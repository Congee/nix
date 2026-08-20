// ==UserScript==
// @name         Bilibili Infinite Buffer
// @name:zh-CN   B站无限缓冲（整片预载 + 永久缓存）
// @namespace    https://github.com/Congee/nix
// @version      0.0.1
// @description  Prefetch an adjustable read-ahead window (default 3 min, up to the whole video) into RAM and answer every player request from cache: a big effective buffer on slow networks, and seeking backwards never re-downloads. Cache lives until the tab closes.
// @description:zh-CN 预载可调时长的缓冲窗口（默认 3 分钟，可选整片）进内存，播放器所有请求直接命中缓存：慢网不卡顿，回拖进度条不重新加载。页面关闭前缓存不丢失。
// @author       Congee
// @license      MIT
// @match        https://www.bilibili.com/video/*
// @match        https://www.bilibili.com/bangumi/play/*
// @match        https://www.bilibili.com/cheese/play/*
// @match        https://www.bilibili.com/list/*
// @match        https://www.bilibili.com/medialist/play/*
// @match        https://www.bilibili.com/watchlater/*
// @match        https://www.bilibili.com/festival/*
// @match        https://player.bilibili.com/*
// @run-at       document-start
// @grant        none
// ==/UserScript==

(() => {
  'use strict';
  if (window.__bibInstalled) return;
  window.__bibInstalled = true;

  const NF = window.fetch.bind(window); // native fetch, used by the prefetcher itself
  const COMMIT = 1 << 20;  // commit to cache every 1 MiB while streaming
  const SPAN = 16 << 20;   // bytes per connection in parallel mode
  const NEAR = 48 << 20;   // a miss within this of a running pump doesn't reposition it

  // ---------- config ----------
  const CFG = Object.assign(
    { enabled: true, overlay: true, capGB: 0, parallel: 3, aheadSec: 180 },
    (() => { try { return JSON.parse(localStorage.getItem('bib.cfg')) || {}; } catch { return {}; } })()
  );
  const saveCfg = () => { try { localStorage.setItem('bib.cfg', JSON.stringify(CFG)); } catch {} };

  // ---------- utils ----------
  const totals = { dl: 0, served: 0, hits: 0 };
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const once = (fn) => { let d = false; return () => { if (!d) { d = true; fn(); } }; };
  function concat(chunks, len) {
    const out = new Uint8Array(len);
    let o = 0;
    for (const c of chunks) { out.set(c, o); o += c.length; }
    return out;
  }
  function parseRangeHeader(h) {
    if (!h) return null;
    const m = /^\s*bytes=(\d+)-(\d*)\s*$/i.exec(h);
    return m ? { start: +m[1], end: m[2] ? +m[2] : null } : null;
  }
  function parseContentRange(h) {
    if (!h) return null;
    const m = /^bytes\s+(\d+)-(\d+)\/(\d+|\*)$/i.exec(h.trim());
    return m ? { start: +m[1], end: +m[2], total: m[3] === '*' ? null : +m[3] } : null;
  }
  function isSeg(url) {
    try {
      const u = new URL(url, location.href);
      const h = u.hostname;
      const hostOK = h.endsWith('.bilivideo.com') || h.endsWith('.bilivideo.cn') ||
                     h.endsWith('.akamaized.net') || h.endsWith('.szbdyd.com');
      if (!hostOK) return false;
      const p = u.pathname;
      return p.endsWith('.m4s') || p.endsWith('.mp4') || p.endsWith('.flv') || p.includes('/upgcxcode/');
    } catch { return false; }
  }

  // ---------- sparse byte cache ----------
  class SparseCache {
    constructor() { this.parts = []; this.size = 0; } // sorted, non-overlapping {start,end,data}
    _find(pos) { // index of first part with end > pos
      let lo = 0, hi = this.parts.length;
      while (lo < hi) { const m = (lo + hi) >> 1; if (this.parts[m].end <= pos) lo = m + 1; else hi = m; }
      return lo;
    }
    gaps(start, end) {
      const out = [];
      let pos = start, i = this._find(start);
      while (pos < end) {
        const p = this.parts[i];
        if (!p || p.start >= end) { out.push([pos, end]); break; }
        if (p.start > pos) out.push([pos, p.start]);
        pos = Math.max(pos, p.end);
        i++;
      }
      return out;
    }
    covered(start, end) { return end <= start || this.gaps(start, end).length === 0; }
    firstGapAfter(pos, limit) { const g = this.gaps(pos, limit); return g.length ? g[0] : null; }
    add(start, u8) {
      if (!u8 || !u8.length) return;
      for (const [s, e] of this.gaps(start, start + u8.length)) {
        const copy = u8.slice(s - start, e - start);
        this.parts.splice(this._find(s), 0, { start: s, end: e, data: copy });
        this.size += copy.length;
      }
    }
    read(start, end) {
      if (!this.covered(start, end)) return null;
      const out = new Uint8Array(end - start);
      for (let i = this._find(start); i < this.parts.length; i++) {
        const p = this.parts[i];
        if (p.start >= end) break;
        const s = Math.max(start, p.start), e = Math.min(end, p.end);
        out.set(p.data.subarray(s - p.start, e - p.start), s - start);
      }
      return out;
    }
  }

  // ---------- stream registry ----------
  const idOf = (path) => { const m = /-(\d+)\.(m4s|mp4)$/.exec(path); return m ? +m[1] : 0; };
  const cidOf = (path) => { const m = /\/upgcxcode\/\d+\/\d+\/(\d+)\//.exec(path); return m ? m[1] : null; };

  // real audio/video file ids, learned from the player's playurl responses
  // (cheese/bangumi use id spaces the 30200-30299 audio heuristic doesn't cover)
  const AUD_IDS = new Set(), VID_IDS = new Set(), ID_LABEL = new Map();
  const QN_NAME = new Map(); // qn -> bilibili's own quality badge, from support_formats
  function learnDash(dash) {
    if (!dash) return;
    const learn = (reps, set, name) => (reps || []).forEach((rep) => {
      if (!rep) return;
      for (const u of [rep.baseUrl, rep.base_url, ...(rep.backupUrl || rep.backup_url || [])]) {
        if (!u) continue;
        try {
          const id = idOf(new URL(u, location.href).pathname);
          if (!id) continue;
          set.add(id);
          const n = name(rep);
          if (n) ID_LABEL.set(id, n);
        } catch {}
      }
    });
    const vName = (r) => QN_NAME.get(r.id) ||
      (r.height ? r.height + 'P' + (parseFloat(r.frameRate || r.frame_rate) >= 45 ? '60' : '') : null);
    const aName = (r) => (r.bandwidth ? Math.round(r.bandwidth / 1000) + 'k' : null);
    learn(dash.video, VID_IDS, vName);
    learn(dash.audio, AUD_IDS, aName);
    if (dash.dolby) learn(dash.dolby.audio, AUD_IDS, aName);
    if (dash.flac) learn([dash.flac.audio], AUD_IDS, aName);
  }
  const isPlayurl = (url) => /api\.bilibili\.com\/[^?]*playurl/.test(url);
  function learnPlayurl(x) {
    try {
      const j = typeof x === 'string' ? JSON.parse(x) : x;
      if (!j) return;
      for (const o of [j.data, j.result, j.data && j.data.video_info, j.result && j.result.video_info]) {
        if (!o) continue;
        for (const f of o.support_formats || [])
          if (f && f.quality && f.display_desc) QN_NAME.set(f.quality, f.display_desc + (f.superscript || ''));
        if (o.dash) learnDash(o.dash);
      }
    } catch {}
  }
  let piSeen = null;
  function learnEmbedded() {
    const pi = window.__playinfo__;
    if (!pi || pi === piSeen) return;
    piSeen = pi;
    learnPlayurl(pi);
  }

  const kindOf = (path) => {
    const id = idOf(path);
    learnEmbedded();
    if (AUD_IDS.has(id)) return 'audio';
    if (VID_IDS.has(id)) return 'video';
    if (id >= 30200 && id < 30300) return 'audio';
    return path.endsWith('.m4s') ? 'video' : 'media';
  };

  const streams = new Map(); // pathname -> stream state
  let inFlight = 0;          // player requests currently on the network

  function streamFor(url) {
    const u = new URL(url, location.href);
    let st = streams.get(u.pathname);
    if (!st) {
      evictInactive(300000); // drop streams of previously watched videos after 5 min
      const kind = kindOf(u.pathname);
      const id = idOf(u.pathname);
      st = {
        key: u.pathname,
        cid: cidOf(u.pathname),
        url: u.href,
        cache: new SparseCache(),
        total: null,
        totalTry: 0,
        kind,
        label: (kind === 'audio' ? '♪ ' : '▸ ') + nameOf(id),
        prefetchable: u.pathname.endsWith('.m4s'),
        playerEnd: 0,
        lastSeen: 0,
        active: true,
        loaderRunning: false,
        pumps: new Set(),
        pumpInfo: new Map(),
        badUrl: null,
        backoff: 0,
        state: 'idle',
        done: false,
      };
      streams.set(u.pathname, st);
    }
    return st;
  }

  const nameOf = (id) => ID_LABEL.get(id) || (id ? '#' + id : 'file');
  function refreshKind(st) { // playurl data may arrive after the stream was created
    const k = kindOf(st.key);
    const label = (k === 'audio' ? '♪ ' : '▸ ') + nameOf(idOf(st.key));
    if (k !== st.kind) st.kind = k;
    if (label !== st.label) st.label = label;
  }

  const totalCached = () => { let n = 0; for (const s of streams.values()) n += s.cache.size; return n; };
  const memOverCap = () => CFG.capGB > 0 && totalCached() > CFG.capGB * 2 ** 30;
  function evictInactive(maxAge = 60000) {
    const now = Date.now();
    const liveCids = new Set();
    for (const s of streams.values()) if (s.active && s.cid) liveCids.add(s.cid);
    for (const [k, s] of streams) {
      if (s.active || now - s.lastSeen <= maxAge) continue;
      if (s.cid && liveCids.has(s.cid)) continue; // same video: keep for instant quality switch-back
      streams.delete(k);
    }
  }

  function setTotal(st, t) {
    if (!(t > 0)) return;
    const hi = st.cache.parts.length ? st.cache.parts[st.cache.parts.length - 1].end : 0;
    if (t < hi) return; // never below data we already hold
    if (st.total !== t) st.total = t;
  }

  // ---------- read-ahead window (time -> bytes via linear bitrate estimate) ----------
  const playerVideo = () =>
    document.querySelector('.bpx-player-container video') || document.querySelector('video');
  function mediaRate(st) { // bytes per second of media time, 0 if unknown
    const v = playerVideo();
    const dur = v && isFinite(v.duration) && v.duration > 1 ? v.duration : 0;
    return dur && st.total ? st.total / dur : 0;
  }
  function limitByte(st) {
    if (CFG.aheadSec <= 0) return st.total ?? Infinity; // whole video
    if (st.total == null) return st.playerEnd + (4 << 20); // bootstrap until size known
    const rate = mediaRate(st);
    if (!rate) return Math.min(st.total, st.playerEnd + (4 << 20));
    const target = (playerVideo().currentTime + CFG.aheadSec) * rate * 1.05 + (2 << 20); // VBR slack
    return Math.min(st.total, Math.floor(target));
  }
  function anchorByte(st) { // window anchor: the playhead, not the max player request
    const rate = mediaRate(st);
    const v = playerVideo();
    if (!rate || !v) return st.playerEnd;
    return Math.floor(Math.max(0, v.currentTime) * rate);
  }

  function noteRequest(st, url, r) {
    st.lastSeen = Date.now();
    refreshKind(st);
    if (url !== st.url) st.url = url;
    if (st.badUrl && st.url !== st.badUrl) st.badUrl = null;
    const end = r ? (r.end != null ? r.end + 1 : r.start) : 0;
    st.playerEnd = Math.max(st.playerEnd, end);
    st.active = true;
    for (const o of streams.values()) {
      if (o !== st && o.kind === st.kind) o.active = false;
    }
    if (CFG.enabled) { ensureLoader(st); ensureTotal(st); }
  }

  function tryServe(st, r) {
    if (st.total == null) return null;
    const start = r ? r.start : 0;
    const end = r && r.end != null ? Math.min(r.end, st.total - 1) : st.total - 1;
    if (start > end) return null;
    const data = st.cache.read(start, end + 1);
    if (!data) return null;
    return { data, start, end, total: st.total };
  }

  // a cache miss far away from any running pump means the user seeked: refocus prefetch
  function reposition(st, missStart) {
    if (!st.pumps.size) return;
    for (const pi of st.pumpInfo.values()) {
      if (missStart >= pi.spanStart && missStart < pi.pos + NEAR) return;
    }
    for (const c of [...st.pumps]) { try { c.abort(); } catch {} }
  }

  // ---------- total-size discovery ----------
  async function ensureTotal(st) {
    if (st.total != null || Date.now() - st.totalTry < 15000) return;
    st.totalTry = Date.now();
    try {
      const res = await NF(st.url, { method: 'HEAD', mode: 'cors', credentials: 'omit', cache: 'no-store' });
      const cl = +res.headers.get('content-length') || 0;
      if (res.ok && cl > 0) { setTotal(st, cl); return; }
    } catch {}
    try { // fallback: full GET, read Content-Length (CORS-safelisted), abort body
      const ctrl = new AbortController();
      const res = await NF(st.url, { mode: 'cors', credentials: 'omit', cache: 'no-store', signal: ctrl.signal });
      const cl = +res.headers.get('content-length') || 0;
      ctrl.abort();
      if (res.ok && cl > 0) setTotal(st, cl);
    } catch {}
  }

  // ---------- prefetcher ----------
  function ensureLoader(st) {
    if (!st.prefetchable || st.loaderRunning) return;
    loaderLoop(st).catch(() => {});
  }

  function splitSpans(gap, p, total) {
    const [g0, g1] = gap;
    const window_ = Math.min(g1 - g0, p * SPAN);
    const per = Math.ceil(window_ / p);
    const spans = [];
    for (let s = g0; s < g0 + window_; s += per) spans.push([s, Math.min(s + per, g0 + window_, total)]);
    return spans;
  }

  async function loaderLoop(st) {
    st.loaderRunning = true;
    try {
      while (CFG.enabled && st.active) {
        if (st.badUrl && st.url === st.badUrl) { st.state = 'url expired, waiting'; await sleep(3000); continue; }
        if (memOverCap()) { st.state = 'paused (mem cap)'; evictInactive(); await sleep(3000); continue; }
        const total = st.total;
        const limit = Math.min(total ?? Infinity, limitByte(st));
        const from = Math.min(CFG.aheadSec > 0 ? anchorByte(st) : st.playerEnd, limit);
        let gap = st.cache.firstGapAfter(from, limit);
        if (!gap) gap = st.cache.firstGapAfter(0, limit); // holes behind the playhead
        if (!gap) {
          st.done = total != null && st.cache.covered(0, total);
          st.state = st.done ? 'complete' : (CFG.aheadSec > 0 ? 'window full' : 'idle');
          await sleep(1200);
          continue;
        }
        // frontier trickle: top up in ~10 s slices instead of a connection per second
        const frontier = total != null && limit < total && gap[1] >= limit;
        if (frontier && gap[1] - gap[0] < Math.max(768 << 10, 10 * mediaRate(st))) {
          st.state = 'window full';
          await sleep(1000);
          continue;
        }
        st.done = false;
        st.state = 'fetching';
        try {
          const spans = (total != null && CFG.parallel > 1 && gap[1] !== Infinity)
            ? splitSpans(gap, CFG.parallel, total)
            : [gap];
          const rs = await Promise.allSettled(spans.map(([a, b]) => pump(st, a, b)));
          const bad = rs.find((x) => x.status === 'rejected');
          if (bad) throw bad.reason;
          st.backoff = 0;
        } catch (e) {
          st.backoff = Math.min((st.backoff || 1) * 2, 20);
          st.lastErr = String((e && e.message) || e).slice(0, 60);
          st.state = 'retry in ' + st.backoff + 's · ' + st.lastErr;
          await sleep(st.backoff * 1000);
        }
      }
    } finally {
      st.loaderRunning = false;
      st.state = 'stopped';
    }
  }

  async function pump(st, start, end) {
    start = Math.floor(start);
    if (end !== Infinity) end = Math.floor(end);
    const ctrl = new AbortController();
    const pi = { spanStart: start, pos: start };
    st.pumps.add(ctrl);
    st.pumpInfo.set(ctrl, pi);
    try {
      const range = end === Infinity ? `bytes=${start}-` : `bytes=${start}-${end - 1}`;
      let res;
      try {
        res = await NF(st.url, {
          method: 'GET', mode: 'cors', credentials: 'omit', cache: 'no-store',
          headers: { Range: range }, signal: ctrl.signal,
        });
      } catch (e) {
        if (ctrl.signal.aborted) return; // our own reposition/stop, not an error
        throw e;
      }
      if (res.status === 403 || res.status === 410 || res.status === 412) {
        st.badUrl = st.url;
        try { res.body && res.body.cancel(); } catch {}
        throw new Error('url expired (' + res.status + ')');
      }
      if (res.status !== 206 && res.status !== 200) throw new Error('http ' + res.status);
      let pos = res.status === 206 ? start : 0; // 200 = server ignored Range, body starts at 0
      pi.pos = pos;
      const cr = parseContentRange(res.headers.get('content-range'));
      if (cr && cr.total) setTotal(st, cr.total);
      else if (res.status === 200) { const cl = +res.headers.get('content-length') || 0; if (cl) setTotal(st, cl); }
      const reader = res.body.getReader();
      let chunks = [], clen = 0, cstart = pos;
      const commit = () => {
        if (clen) { st.cache.add(cstart, concat(chunks, clen)); chunks = []; clen = 0; }
        cstart = pos;
      };
      while (true) {
        if (!st.active || !CFG.enabled || memOverCap()) { commit(); ctrl.abort(); break; }
        while (inFlight > 0 && !ctrl.signal.aborted) { commit(); await sleep(150); } // yield to the player
        let rr;
        try { rr = await reader.read(); }
        catch (e) { commit(); if (ctrl.signal.aborted) return; throw e; }
        if (rr.done) {
          commit();
          const want = end === Infinity ? st.total : end;
          if (end === Infinity && st.total == null) setTotal(st, pos);
          else if (want != null && pos < want) throw new Error('truncated at ' + pos + '/' + want);
          break;
        }
        totals.dl += rr.value.length;
        chunks.push(rr.value);
        clen += rr.value.length;
        pos += rr.value.length;
        pi.pos = pos;
        if (clen >= COMMIT) commit();
        if (end !== Infinity && pos >= end) { commit(); ctrl.abort(); break; }
      }
    } finally {
      st.pumps.delete(ctrl);
      st.pumpInfo.delete(ctrl);
    }
  }

  // ---------- XHR hook ----------
  const XP = XMLHttpRequest.prototype;
  const oOpen = XP.open, oSend = XP.send, oSet = XP.setRequestHeader, oAbort = XP.abort;
  const xstate = new WeakMap();
  const SHADOWED = ['readyState', 'status', 'statusText', 'response', 'responseURL',
                    'getResponseHeader', 'getAllResponseHeaders', 'abort'];

  XP.open = function (method, url, ...rest) {
    try {
      for (const k of SHADOWED) { try { delete this[k]; } catch {} }
      xstate.set(this, { m: String(method).toUpperCase(), url: new URL(String(url), location.href).href, range: null, synth: null });
    } catch { xstate.delete(this); }
    return oOpen.call(this, method, url, ...rest);
  };
  XP.setRequestHeader = function (name, value) {
    const s = xstate.get(this);
    if (s && String(name).toLowerCase() === 'range') s.range = String(value);
    return oSet.apply(this, arguments);
  };
  XP.abort = function () {
    const s = xstate.get(this);
    if (s && s.synth) { s.synth.cancelled = true; s.synth.timers.forEach(clearTimeout); }
    return oAbort.apply(this, arguments);
  };
  XP.send = function (...args) {
    const s = xstate.get(this);
    if (s && s.m === 'GET' && isPlayurl(s.url)) {
      this.addEventListener('load', () => {
        try { const rt = this.responseType; learnPlayurl(rt === '' || rt === 'text' ? this.responseText : this.response); } catch {}
      });
    }
    if (!s || !CFG.enabled || s.m !== 'GET' || !isSeg(s.url)) return oSend.apply(this, args);
    let st = null, r = null, hit = null;
    try {
      st = streamFor(s.url);
      r = parseRangeHeader(s.range);
      noteRequest(st, s.url, r);
      const rt = this.responseType;
      if (rt === 'arraybuffer' || rt === 'blob') hit = tryServe(st, r);
    } catch {}
    if (hit) {
      totals.hits++;
      totals.served += hit.data.length;
      synthXHR(this, s, hit, !!r);
      return;
    }
    if (st && r) { try { reposition(st, r.start); } catch {} }
    inFlight++;
    const dec = once(() => { inFlight--; });
    setTimeout(dec, 60000); // safety: never wedge the prefetcher
    this.addEventListener('loadend', dec);
    this.addEventListener('load', () => { try { harvestXHR(this, st, r); } catch {} });
    return oSend.apply(this, args);
  };

  function harvestXHR(xhr, st, r) {
    if (!st || xhr.responseType !== 'arraybuffer' || !(xhr.response instanceof ArrayBuffer)) return;
    const status = xhr.status;
    if (status !== 200 && status !== 206) return;
    let start = 0;
    if (status === 206) {
      const cr = parseContentRange(xhr.getResponseHeader('Content-Range'));
      if (cr) { start = cr.start; if (cr.total) setTotal(st, cr.total); }
      else if (r) start = r.start;
      else return;
    } else {
      setTotal(st, xhr.response.byteLength);
    }
    st.cache.add(start, new Uint8Array(xhr.response));
    totals.dl += xhr.response.byteLength;
  }

  function synthXHR(xhr, s, hit, isPartial) {
    const len = hit.data.length;
    const rt = xhr.responseType;
    const headers = { 'content-type': 'video/mp4', 'content-length': String(len), 'x-bib-cache': 'hit' };
    if (isPartial) headers['content-range'] = `bytes ${hit.start}-${hit.end}/${hit.total}`;
    let readyState = 1;
    let response = null;
    const synth = { timers: [], cancelled: false };
    s.synth = synth;
    Object.defineProperties(xhr, {
      readyState: { configurable: true, get: () => readyState },
      status: { configurable: true, get: () => (readyState >= 2 ? (isPartial ? 206 : 200) : 0) },
      statusText: { configurable: true, get: () => (readyState >= 2 ? (isPartial ? 'Partial Content' : 'OK') : '') },
      response: { configurable: true, get: () => response },
      responseURL: { configurable: true, get: () => s.url },
      getResponseHeader: { configurable: true, value: (n) => headers[String(n).toLowerCase()] ?? null },
      getAllResponseHeaders: {
        configurable: true,
        value: () => Object.entries(headers).map(([k, v]) => `${k}: ${v}`).join('\r\n') + '\r\n',
      },
      abort: { configurable: true, value: () => { synth.cancelled = true; synth.timers.forEach(clearTimeout); } },
    });
    const t = (fn, ms) => synth.timers.push(setTimeout(() => { if (!synth.cancelled) fn(); }, ms));
    t(() => { readyState = 2; xhr.dispatchEvent(new Event('readystatechange')); }, 0);
    t(() => {
      readyState = 3;
      response = rt === 'blob' ? new Blob([hit.data], { type: 'video/mp4' }) : hit.data.buffer;
      xhr.dispatchEvent(new Event('readystatechange'));
    }, 1);
    t(() => {
      readyState = 4;
      xhr.dispatchEvent(new Event('readystatechange'));
      const pe = (type) => new ProgressEvent(type, { lengthComputable: true, loaded: len, total: len });
      xhr.dispatchEvent(pe('progress'));
      xhr.dispatchEvent(pe('load'));
      xhr.dispatchEvent(pe('loadend'));
    }, 2);
  }

  // ---------- fetch hook ----------
  const oFetch = window.fetch;
  window.fetch = function (input, init) {
    try {
      let req = input instanceof Request ? input : null;
      const url = req ? req.url : String(input);
      if (isPlayurl(url)) {
        const p = NF(input, init);
        p.then((res) => { try { res.clone().text().then(learnPlayurl); } catch {} }, () => {});
        return p;
      }
      if (CFG.enabled && isSeg(url)) {
        if (!req || init) req = new Request(input, init);
        if (req.method === 'GET') {
          const st = streamFor(url);
          const r = parseRangeHeader(req.headers.get('range'));
          noteRequest(st, url, r);
          const hit = tryServe(st, r);
          if (hit) {
            totals.hits++;
            totals.served += hit.data.length;
            const headers = new Headers({
              'Content-Type': 'video/mp4',
              'Content-Length': String(hit.data.length),
              'X-Bib-Cache': 'hit',
            });
            if (r) headers.set('Content-Range', `bytes ${hit.start}-${hit.end}/${hit.total}`);
            const resp = new Response(hit.data, {
              status: r ? 206 : 200,
              statusText: r ? 'Partial Content' : 'OK',
              headers,
            });
            try { Object.defineProperty(resp, 'url', { value: url }); } catch {}
            return Promise.resolve(resp);
          }
          if (r) { try { reposition(st, r.start); } catch {} }
          inFlight++;
          const dec = once(() => { inFlight--; });
          setTimeout(dec, 60000);
          return oFetch.call(this, req).then(
            (res) => {
              try {
                if ((res.status === 200 || res.status === 206) && res.body) {
                  const cr = parseContentRange(res.headers.get('content-range'));
                  if (cr && cr.total) setTotal(st, cr.total);
                  else if (res.status === 200) { const cl = +res.headers.get('content-length') || 0; if (cl) setTotal(st, cl); }
                  const startPos = res.status === 206 ? (cr ? cr.start : (r ? r.start : 0)) : 0;
                  const [a, b] = res.body.tee();
                  harvestStream(st, startPos, b).finally(dec);
                  const out = new Response(a, res);
                  try {
                    Object.defineProperty(out, 'url', { value: res.url });
                    Object.defineProperty(out, 'redirected', { value: res.redirected });
                  } catch {}
                  return out;
                }
              } catch {}
              dec();
              return res;
            },
            (err) => { dec(); throw err; }
          );
        }
      }
    } catch {}
    return oFetch.apply(this, arguments);
  };

  async function harvestStream(st, startPos, body) {
    const reader = body.getReader();
    let pos = startPos, chunks = [], clen = 0, cstart = pos;
    const commit = () => {
      if (clen) { st.cache.add(cstart, concat(chunks, clen)); chunks = []; clen = 0; }
      cstart = pos;
    };
    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) { commit(); break; }
        totals.dl += value.length;
        chunks.push(value);
        clen += value.length;
        pos += value.length;
        if (clen >= COMMIT) commit();
      }
    } catch { commit(); }
  }

  // ---------- UI ----------
  const fmtMB = (n) => (n >= 1e9 ? (n / 1073741824).toFixed(2) + ' GB' : ((n / 1048576) | 0) + ' MB');
  const fmtSpd = (b) => (b >= 1048576 ? (b / 1048576).toFixed(1) + ' MB/s' : ((b / 1024) | 0) + ' KB/s');

  function initUI() {
    const host = document.createElement('div');
    host.style.cssText = 'position:fixed;left:16px;bottom:16px;z-index:2147483000;display:none;';
    const sh = host.attachShadow({ mode: 'open' });
    sh.innerHTML = `
<style>
  :host { all: initial; }
  * { box-sizing: border-box; font: 12px/1.45 -apple-system, "Segoe UI", "PingFang SC", "Microsoft YaHei", sans-serif; }
  #pill { display:inline-flex; align-items:center; gap:6px; padding:5px 11px; border-radius:999px;
    background:rgba(18,18,22,.78); color:#e7e7ea; cursor:pointer; user-select:none;
    backdrop-filter:blur(8px); -webkit-backdrop-filter:blur(8px);
    box-shadow:0 2px 10px rgba(0,0,0,.35); border:1px solid rgba(255,255,255,.08); }
  #pill b { color:#35e0b4; font-weight:600; }
  #panel { position:absolute; left:0; bottom:34px; width:296px; padding:12px 12px 10px; border-radius:12px;
    background:rgba(18,18,22,.92); color:#e7e7ea; backdrop-filter:blur(10px); -webkit-backdrop-filter:blur(10px);
    box-shadow:0 6px 24px rgba(0,0,0,.45); border:1px solid rgba(255,255,255,.08); }
  .hd { display:flex; justify-content:space-between; align-items:center; margin-bottom:8px; }
  .hd b { font-size:13px; }
  .row { display:flex; align-items:center; gap:8px; margin-top:6px; }
  .lb { width:64px; color:#b9b9c2; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
  .bar { flex:1; height:6px; border-radius:3px; background:rgba(255,255,255,.12); overflow:hidden; }
  .bar i { display:block; height:100%; background:#35e0b4; border-radius:3px; transition:width .4s; }
  .rt { width:44px; text-align:right; color:#e7e7ea; }
  .sub { margin:1px 0 2px 72px; color:#8b8b95; font-size:11px; }
  .mut { margin-top:6px; color:#8b8b95; font-size:11px; }
  #stats { margin-top:9px; padding-top:8px; border-top:1px solid rgba(255,255,255,.08); color:#b9b9c2; font-size:11px; }
  .cfg { display:flex; align-items:center; gap:10px; margin-top:8px; color:#b9b9c2; font-size:11px; flex-wrap:wrap; }
  .cfg select { background:rgba(255,255,255,.08); color:#e7e7ea; border:1px solid rgba(255,255,255,.12);
    border-radius:5px; padding:1px 4px; font-size:11px; }
  .cfg button { background:rgba(255,80,80,.14); color:#ff8484; border:1px solid rgba(255,80,80,.3);
    border-radius:5px; padding:2px 8px; cursor:pointer; font-size:11px; margin-left:auto; }
  .cfg label { display:inline-flex; align-items:center; gap:4px; cursor:pointer; }
  input[type=checkbox] { accent-color:#35e0b4; margin:0; }
</style>
<div id="pill">∞ <b id="pv">…</b></div>
<div id="panel" hidden>
  <div class="hd"><b>∞ Infinite Buffer</b><label><input type="checkbox" id="en"> enabled</label></div>
  <div id="rows"></div>
  <div id="stats"></div>
  <div class="cfg">
    <label>prefetch <select id="ahead">
      <option value="60">60 s</option><option value="180">3 min</option><option value="300">5 min</option>
      <option value="600">10 min</option><option value="1800">30 min</option><option value="0">whole video</option></select></label>
    <label>mem cap <select id="cap">
      <option value="0">unlimited</option><option value="1">1 GB</option><option value="2">2 GB</option>
      <option value="4">4 GB</option><option value="8">8 GB</option></select></label>
    <label>connections <select id="par"><option>1</option><option>2</option><option>3</option><option>4</option></select></label>
  </div>
  <div class="cfg">
    <label><input type="checkbox" id="ov"> marks on progress bar</label>
    <button id="clr">clear cache</button>
  </div>
</div>`;
    (document.body || document.documentElement).appendChild(host);

    const $ = (id) => sh.getElementById(id);
    const pill = $('pill'), panel = $('panel'), pv = $('pv'), rows = $('rows'), stats = $('stats');
    pill.addEventListener('click', () => { panel.hidden = !panel.hidden; });
    const en = $('en'), cap = $('cap'), par = $('par'), ov = $('ov'), ahead = $('ahead');
    en.checked = CFG.enabled; cap.value = String(CFG.capGB); par.value = String(CFG.parallel);
    ov.checked = CFG.overlay; ahead.value = String(CFG.aheadSec);
    ahead.addEventListener('change', () => { CFG.aheadSec = +ahead.value; saveCfg(); });
    en.addEventListener('change', () => {
      CFG.enabled = en.checked; saveCfg();
      if (CFG.enabled) for (const s of streams.values()) if (s.active) ensureLoader(s);
    });
    cap.addEventListener('change', () => { CFG.capGB = +cap.value; saveCfg(); });
    par.addEventListener('change', () => { CFG.parallel = +par.value; saveCfg(); });
    ov.addEventListener('change', () => { CFG.overlay = ov.checked; saveCfg(); });
    $('clr').addEventListener('click', () => {
      for (const s of streams.values()) { s.active = false; for (const c of [...s.pumps]) { try { c.abort(); } catch {} } }
      streams.clear();
    });

    let lastDl = 0, lastT = Date.now(), spd = 0;
    setInterval(() => {
      const now = Date.now(), dt = (now - lastT) / 1000;
      if (dt > 0.3) { spd = spd * 0.5 + ((totals.dl - lastDl) / dt) * 0.5; lastDl = totals.dl; lastT = now; }
      if (!streams.size) { host.style.display = 'none'; return; }
      host.style.display = '';
      let vs = null;
      for (const s of streams.values()) {
        if (s.kind !== 'audio' && s.active && (!vs || s.lastSeen > vs.lastSeen)) vs = s;
      }
      pv.textContent = vs && vs.total
        ? Math.min(100, (vs.cache.size / vs.total) * 100).toFixed(0) + '%'
        : fmtMB(totalCached());
      pill.title = 'cached ' + fmtMB(totalCached()) + ' · ↓ ' + fmtSpd(spd);
      if (panel.hidden) return;
      const act = [...streams.values()].filter((s) => s.active)
        .sort((a, b) => (a.kind === 'video' ? 0 : 1) - (b.kind === 'video' ? 0 : 1));
      const inact = [...streams.values()].filter((s) => !s.active);
      let html = '';
      for (const s of act.slice(0, 4)) {
        const pct = s.total ? Math.min(100, (s.cache.size / s.total) * 100) : 0;
        html += `<div class="row"><span class="lb">${s.label}</span><div class="bar"><i style="width:${pct.toFixed(1)}%"></i></div>` +
          `<span class="rt">${s.total ? pct.toFixed(0) + '%' : '…'}</span></div>` +
          `<div class="sub">${fmtMB(s.cache.size)}${s.total ? ' / ' + fmtMB(s.total) : ''} · ${s.done ? '✓ complete' : s.state}</div>`;
      }
      if (inact.length) {
        let ib = 0; for (const s of inact) ib += s.cache.size;
        html += `<div class="mut">+ ${inact.length} idle cached stream(s), ${fmtMB(ib)}</div>`;
      }
      rows.innerHTML = html;
      stats.textContent = `↓ ${fmtSpd(spd)} · served from cache ${fmtMB(totals.served)} (${totals.hits}×) · RAM ${fmtMB(totalCached())}`;
    }, 800);

    // cached-range marks above the player's progress bar
    let cv = null;
    setInterval(() => {
      if (!CFG.overlay || !CFG.enabled) { if (cv) { cv.remove(); cv = null; } return; }
      const bar = document.querySelector('.bpx-player-progress');
      if (!bar) { if (cv) { cv.remove(); cv = null; } return; }
      if (!cv || !cv.isConnected || cv.parentElement !== bar) {
        if (cv) cv.remove();
        cv = document.createElement('canvas');
        cv.style.cssText = 'position:absolute;left:0;top:-7px;width:100%;height:3px;pointer-events:none;';
        bar.appendChild(cv);
      }
      let vs = null;
      for (const s of streams.values()) {
        if (s.kind === 'video' && s.active && s.total && (!vs || s.lastSeen > vs.lastSeen)) vs = s;
      }
      const w = Math.max(1, bar.clientWidth | 0);
      if (cv.width !== w) cv.width = w;
      cv.height = 3;
      const g = cv.getContext('2d');
      g.clearRect(0, 0, w, 3);
      if (!vs) return;
      g.fillStyle = 'rgba(255,255,255,.16)';
      g.fillRect(0, 0, w, 3);
      g.fillStyle = '#35e0b4';
      for (const p of vs.cache.parts) {
        const x0 = (p.start / vs.total) * w, x1 = (p.end / vs.total) * w;
        g.fillRect(x0, 0, Math.max(1, x1 - x0), 3);
      }
    }, 1000);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', initUI, { once: true });
  else initUI();

  window.__bib = { streams, totals, CFG };
})();
