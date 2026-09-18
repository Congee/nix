// ==UserScript==
// @name           Google Maps: Real Saved-List Icons
// @namespace      https://github.com/Congee/nix
// @version        1.1.0
// @description    Google Maps web draws every custom saved list with the same generic bookmark/category pin, so on the map you can no longer tell which list a place came from. This paints each list's own emoji over its places, the way the mobile app does.
// @author         Congee
// @homepageURL    https://github.com/Congee/nix
// @supportURL     https://github.com/Congee/nix/issues
// @downloadURL    https://raw.githubusercontent.com/Congee/nix/master/config/userscripts/google-maps-saved-list-icons.user.js
// @updateURL      https://raw.githubusercontent.com/Congee/nix/master/config/userscripts/google-maps-saved-list-icons.user.js
// @match          https://www.google.com/maps*
// @icon           https://maps.google.com/favicon.ico
// @run-at         document-start
// @grant          none
// @license        MIT
// ==/UserScript==

(function () {
  'use strict';

  // ─── Configuration ──────────────────────────────────────────────────────
  const CONFIG = {
    minZoom: 11,            // Maps itself stops drawing saved pins below ~11
    maxPlacesPerList: 2000, // getlist returns an empty doc above ~5000
    iconSize: 26,           // px — matches Google's own saved-place circle
    listsTtlMs: 6 * 3600 * 1000, // how stale a first paint may be; see load()
    skipLists: [],          // list names or ids to leave alone
    smoothPan: true,        // follow drags 1:1 instead of waiting for the URL
    debug: false,
  };

  // The map is a WebGL canvas and its tiles carry no list identity, so there
  // is nothing of Google's to restyle: read the lists from the endpoints the
  // Maps UI uses, project them, and draw emoji circles over the canvas. The
  // overlay cannot know which pins Maps culled, so a stray icon in e.g.
  // directions mode is expected.

  const log = (...a) => { if (CONFIG.debug) console.log('[saved-list-icons]', ...a); };

  // ─── Camera ─────────────────────────────────────────────────────────────
  // The camera sits in the path as /@lat,lng,<z>z. The trailing `z` matters:
  // tilted/3D and Street View end in a/m/y, where a flat projection would be
  // wrong, so those parse as null and the overlay hides.
  const CAM_RE = /\/@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?),(\d+(?:\.\d+)?)z/;

  function camera() {
    const m = CAM_RE.exec(location.pathname);
    return m ? { lat: +m[1], lng: +m[2], zoom: +m[3] } : null;
  }

  // ─── Projection ─────────────────────────────────────────────────────────
  // Web Mercator over a 256 px tile grid, in CSS pixels.
  const MAX_LAT = 85.05112878;

  function project(lat, lng, world) {
    const s = Math.sin(Math.max(-MAX_LAT, Math.min(MAX_LAT, lat)) * Math.PI / 180);
    return {
      x: (lng + 180) / 360 * world,
      y: (0.5 - Math.log((1 + s) / (1 - s)) / (4 * Math.PI)) * world,
    };
  }

  // ─── Endpoints ──────────────────────────────────────────────────────────
  // Both answer with Google's )]}'\n prefix and a positional array. The
  // offsets are unversioned, hence the defensive indexing: a layout change
  // has to degrade to "no icons", never to wrong ones.
  function commonParams() {
    const q = new URLSearchParams(location.search);
    // document-start: <html> may not exist yet, so guard the lang sniff.
    const root = document.documentElement;
    const hl = q.get('hl') || (root && root.lang) || 'en';
    return 'authuser=' + encodeURIComponent(q.get('authuser') || '0') +
           '&hl=' + encodeURIComponent(hl);
  }

  async function gjson(url) {
    const res = await fetch(new URL(url, location.origin).href, { credentials: 'same-origin' });
    if (!res.ok) throw new Error('HTTP ' + res.status);
    return JSON.parse((await res.text()).replace(/^\)\]\}'?\n/, ''));
  }

  // ─── The `pb` request parameter ─────────────────────────────────────────
  // Google's "protobuf URL": a flat, "!"-separated list of <field><type><value>
  // where type `m` opens a submessage and its value counts the blocks inside
  // it. Types used here: i int32, e enum, b bool, s string, m message.
  //
  //   pb({ '1m': { '1s': 'x' }, '4i': 50 })  →  '!1m1!1sx!4i50'
  function pb(fields) {
    let out = '';
    for (const [key, value] of Object.entries(fields)) {
      const num = key.slice(0, -1);
      switch (key.slice(-1)) {
        case 'm': {
          const body = pb(value);
          out += '!' + num + 'm' + (body.match(/!/g) || []).length + body;
          break;
        }
        case 'b':
          out += '!' + num + 'b' + (value ? 1 : 0);
          break;
        case 's':
          // '*' and '!' are the format's own escapes; then URL-escape.
          out += '!' + num + 's' + encodeURIComponent(
            String(value).replace(/\*/g, '*2A').replace(/!/g, '*21'),
          );
          break;
        default:
          out += '!' + num + key.slice(-1) + value; // i, e, d, … base-10
      }
    }
    return out;
  }

  // Both requests are as Maps sends them; only the named fields were probed,
  // so a field means only as much as the comment claims. The 50s cap the
  // index at 50 lists.
  const MAS_PB = pb({
    '2m': { '15i': 17409 },
    '7m': { '1i': 50 },
    '12m': { '1i': 50 },
    '15m': { '1i': 50 },
    '23m': { '1i': 50, '3b': true },
    '24m': { '1i': 50, '3b': true },
    '38m': { '1i': 50, '3b': true },
  });
  const MAS_SLOTS = [29, 43]; // 29 = lists you own, 43 = lists you follow

  const getlistPb = (id, n) => pb({
    '1m': { '1s': id, '2e': 1, '3m': { '1e': 1 } }, // which list
    '2e': 2,
    '3e': 2,
    '4i': n,                                        // page size
    '16b': true,
  });

  // record: [0][0] id, [4] name, [11][0] modified stamp, [17] emoji
  async function fetchLists() {
    const d = await gjson('/locationhistory/preview/mas?' + commonParams() + '&pb=' + MAS_PB);
    const out = [];
    for (const slot of MAS_SLOTS) {
      for (const r of (d[slot] && d[slot][3]) || []) {
        const id = r[0] && r[0][0];
        const emoji = r[17];
        // Only custom lists carry an emoji. Built-in ones (Favourites, Want
        // to go, …) already get distinct glyphs from Maps.
        if (typeof id !== 'string' || typeof emoji !== 'string' || !emoji) continue;
        const stamp = r[11] && r[11][0];
        out.push({
          id, emoji,
          name: typeof r[4] === 'string' ? r[4] : id,
          mtime: (typeof stamp === 'number' || typeof stamp === 'string') ? String(stamp) : '',
        });
      }
    }
    return out;
  }

  // place: [1][5][2..3] lat/lng. Always ask for a full page: keying the
  // request off the record's own place count would silently truncate a list
  // if that offset ever moved.
  async function fetchPlaces(list) {
    const d = await gjson('/maps/preview/entitylist/getlist?' + commonParams() +
                          '&pb=' + getlistPb(list.id, CONFIG.maxPlacesPerList));
    const out = [];
    for (const p of (d[0] && d[0][8]) || []) {
      const ll = p && p[1] && p[1][5];
      if (!ll || typeof ll[2] !== 'number' || typeof ll[3] !== 'number') continue;
      out.push([ll[2], ll[3]]);
    }
    return out;
  }

  // ─── Cache ──────────────────────────────────────────────────────────────
  // Places are keyed on the list's own modified stamp, so an edit from any
  // device invalidates them for free. Without a stamp they fall back to a TTL
  // rather than caching forever.
  const PREFIX = 'saved-list-icons:';
  const placesKey = (list) => 'places:' + list.id + ':' + (list.mtime || 'na');

  function cacheGet(key, maxAgeMs) {
    try {
      const raw = localStorage.getItem(PREFIX + key);
      if (!raw) return null;
      const entry = JSON.parse(raw);
      if (maxAgeMs && Date.now() - entry.t > maxAgeMs) return null;
      return entry.v;
    } catch (e) {
      return null;
    }
  }

  function cacheSet(key, v) {
    const raw = JSON.stringify({ t: Date.now(), v });
    try {
      localStorage.setItem(PREFIX + key, raw);
    } catch (e) {
      // Make room but keep the new value — dropping it would refetch, and
      // overflow again, on every single load.
      for (const k of Object.keys(localStorage)) {
        if (k.startsWith(PREFIX) && k !== PREFIX + key) localStorage.removeItem(k);
      }
      try {
        localStorage.setItem(PREFIX + key, raw);
      } catch (e2) {
        log('too big to cache', key);
      }
    }
  }

  // Drops superseded versions and lists that are gone from the index.
  function cacheSweep(lists) {
    const live = new Set(lists.map((l) => PREFIX + placesKey(l)));
    for (const k of Object.keys(localStorage)) {
      if (k.startsWith(PREFIX + 'places:') && !live.has(k)) localStorage.removeItem(k);
    }
  }

  // ─── Load ───────────────────────────────────────────────────────────────
  let pins = []; // [lat, lng, emoji]

  function sameLists(a, b) {
    return a.length === b.length && a.every((l, i) =>
      l.id === b[i].id && l.mtime === b[i].mtime && l.emoji === b[i].emoji);
  }

  // progressive: swap the pins in list by list, so a cold load paints as it
  // goes. A revalidation swaps once at the end instead, to avoid flashing a
  // half-drawn map over icons that are already correct.
  async function draw(lists, progressive) {
    const next = [];
    const seen = new Set();
    for (const list of lists) {
      if (CONFIG.skipLists.includes(list.name) || CONFIG.skipLists.includes(list.id)) continue;
      const key = placesKey(list);
      let places = cacheGet(key, list.mtime ? 0 : CONFIG.listsTtlMs);
      if (!places) {
        try {
          places = await fetchPlaces(list);
        } catch (e) {
          log('failed', list.name, e);
          continue;
        }
        cacheSet(key, places);
      }
      for (const [lat, lng] of places) {
        // A place can sit in several lists; first list wins, which matches
        // Maps drawing exactly one pin per place.
        const at = lat.toFixed(6) + ',' + lng.toFixed(6);
        if (seen.has(at)) continue;
        seen.add(at);
        next.push([lat, lng, list.emoji]);
      }
      if (progressive) {
        pins = next;
        schedule();
      }
    }
    pins = next;
    schedule();
  }

  async function load() {
    const cached = cacheGet('lists', CONFIG.listsTtlMs);
    if (cached && cached.length) await draw(cached, true);

    // The index holds the stamps everything else is keyed on, so it has to be
    // revalidated: a cached index cannot report its own staleness.
    const fresh = await fetchLists();
    log('lists', fresh);
    cacheSet('lists', fresh);
    cacheSweep(fresh);
    if (!cached || !sameLists(cached, fresh)) await draw(fresh, !cached);
  }

  // ─── Overlay ────────────────────────────────────────────────────────────
  // The layer goes inside the canvas' own parent, a z-index:0 stacking
  // context, so it lands above the map and below Maps' panels without
  // competing on z-index. It is inset negatively so pins just off-screen are
  // already drawn and slide in during a drag.
  const PAD = 320;
  const LAYER_ID = 'vm-saved-list-icons';

  let layer = null;
  let mapCanvas = null;
  let resizeObserver = null;
  let nodes = [];

  function biggestCanvas() {
    let best = null;
    for (const c of document.querySelectorAll('canvas')) {
      const r = c.getBoundingClientRect();
      if (!best || r.width * r.height > best.area) best = { el: c, area: r.width * r.height };
    }
    return best && best.area > 0 ? best.el : null;
  }

  function injectStyle() {
    if (document.getElementById(LAYER_ID + '-style')) return;
    const style = document.createElement('style');
    style.id = LAYER_ID + '-style';
    style.textContent =
      '#' + LAYER_ID + ' > i {' +
      'position:absolute;left:0;top:0;box-sizing:border-box;' +
      'width:' + CONFIG.iconSize + 'px;height:' + CONFIG.iconSize + 'px;' +
      'margin:' + -CONFIG.iconSize / 2 + 'px 0 0 ' + -CONFIG.iconSize / 2 + 'px;' +
      'border-radius:50%;border:1px solid rgba(0,0,0,.14);background:#fff;' +
      'box-shadow:0 1px 3px rgba(0,0,0,.35);' +
      'display:flex;align-items:center;justify-content:center;' +
      'font-size:' + Math.round(CONFIG.iconSize * 0.56) + 'px;line-height:1;font-style:normal;' +
      'font-family:"Apple Color Emoji","Segoe UI Emoji","Noto Color Emoji",sans-serif;' +
      '}';
    (document.head || document.documentElement).appendChild(style);
  }

  function ensureLayer() {
    // Fast path: nothing moved since the last frame, so skip the DOM walk.
    if (mapCanvas && mapCanvas.isConnected &&
        layer && layer.parentElement === mapCanvas.parentElement) return true;

    const canvas = biggestCanvas();
    const host = canvas && canvas.parentElement;
    if (!host) return false;

    if (canvas !== mapCanvas) {
      mapCanvas = canvas;
      if (resizeObserver) resizeObserver.disconnect();
      // Opening/closing the side panel resizes the canvas without touching
      // the URL, which moves the camera centre.
      resizeObserver = new ResizeObserver(schedule);
      resizeObserver.observe(canvas);
    }
    if (layer && layer.parentElement === host) return true;

    injectStyle();
    if (layer) layer.remove();
    nodes = [];
    layer = document.createElement('div');
    layer.id = LAYER_ID;
    Object.assign(layer.style, {
      position: 'absolute',
      left: -PAD + 'px', top: -PAD + 'px', right: -PAD + 'px', bottom: -PAD + 'px',
      overflow: 'hidden',
      pointerEvents: 'none',
      zIndex: '5',
    });
    host.appendChild(layer);
    return true;
  }

  // The observer, the poll and the URL hooks can all fire in one frame.
  let frame = 0;

  function schedule() {
    if (frame) return;
    frame = requestAnimationFrame(() => { frame = 0; render(); });
  }

  // Icons are reused across renders; the surplus is hidden, not destroyed.
  function icon(i) {
    let el = nodes[i];
    if (!el) {
      el = document.createElement('i');
      nodes[i] = el;
      layer.appendChild(el);
    }
    return el;
  }

  function hideFrom(i) {
    for (; i < nodes.length; i++) nodes[i].style.display = 'none';
  }

  function render() {
    if (!ensureLayer()) return;

    layer.style.transform = '';
    layer.style.opacity = '1';

    const cam = camera();
    if (!cam || cam.zoom < CONFIG.minZoom || !pins.length) {
      hideFrom(0);
      return;
    }

    // Layer-local coordinates: the layer starts PAD left of and above the host.
    const cr = mapCanvas.getBoundingClientRect();
    const hr = layer.parentElement.getBoundingClientRect();
    const left = cr.left - hr.left + PAD;
    const top = cr.top - hr.top + PAD;
    const originX = left + cr.width / 2;
    const originY = top + cr.height / 2;

    const world = 256 * Math.pow(2, cam.zoom);
    const centre = project(cam.lat, cam.lng, world);

    let used = 0;
    for (const [lat, lng, emoji] of pins) {
      const p = project(lat, lng, world);
      let dx = p.x - centre.x;
      dx -= world * Math.round(dx / world); // take the shorter way round
      const x = dx + originX;
      const y = p.y - centre.y + originY;
      if (x < left - PAD || x > left + cr.width + PAD) continue;
      if (y < top - PAD || y > top + cr.height + PAD) continue;
      const el = icon(used++);
      if (el.textContent !== emoji) el.textContent = emoji;
      el.style.transform = 'translate(' + x.toFixed(1) + 'px,' + y.toFixed(1) + 'px)';
      el.style.display = '';
    }
    hideFrom(used);
  }

  // ─── Gestures ───────────────────────────────────────────────────────────
  // The URL is only rewritten once a gesture settles. Maps pans 1:1 in CSS
  // pixels, so translating the layer by the pointer delta tracks a drag
  // exactly; zoom is animated and fractional, so the layer just fades. A
  // camera move Maps starts by itself gives no signal at all and is not
  // covered.
  let drag = null;
  let fadeTimer = null;
  let settleTimer = null;

  const onMap = (e) => !!layer && !!mapCanvas && e.target === mapCanvas;

  function fadeThenRender(ms) {
    if (!layer) return;
    layer.style.opacity = '0';
    clearTimeout(fadeTimer);
    fadeTimer = setTimeout(render, ms);
  }

  addEventListener('pointerdown', (e) => {
    if (!CONFIG.smoothPan || e.button !== 0 || !onMap(e)) return;
    drag = { id: e.pointerId, x: e.clientX, y: e.clientY };
  }, true);

  // A pinch adds a second pointer; only the one that started the drag pans.
  addEventListener('pointermove', (e) => {
    if (!drag || e.pointerId !== drag.id || !layer) return;
    layer.style.transform =
      'translate(' + (e.clientX - drag.x) + 'px,' + (e.clientY - drag.y) + 'px)';
  }, true);

  for (const type of ['pointerup', 'pointercancel']) {
    addEventListener(type, (e) => {
      if (!drag || e.pointerId !== drag.id) return;
      drag = null;
      // Maps normally rewrites the URL, which re-renders. If it decides the
      // drag was a click it never does, so drop the translate ourselves —
      // late enough not to snap the icons back mid-gesture.
      clearTimeout(settleTimer);
      settleTimer = setTimeout(render, 600);
    }, true);
  }

  addEventListener('wheel', (e) => { if (onMap(e)) fadeThenRender(400); }, true);
  addEventListener('dblclick', (e) => { if (onMap(e)) fadeThenRender(500); }, true);

  // The +/− control and the keyboard zoom too, and neither targets the canvas.
  addEventListener('click', (e) => {
    const el = e.target instanceof Element && e.target.closest('button,[role="button"]');
    if (el && /zoom/i.test(el.id + ' ' + (el.getAttribute('aria-label') || ''))) {
      fadeThenRender(500);
    }
  }, true);

  addEventListener('keydown', (e) => {
    if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
    if (e.key === '+' || e.key === '-' || e.key === '=' || e.key === '_') fadeThenRender(500);
  }, true);

  // ─── Wiring ─────────────────────────────────────────────────────────────
  // Every camera move is a replaceState, every navigation a pushState. The
  // poll is a backstop: at document-start neither the canvas nor the /@… URL
  // exists yet, and Maps also moves the camera without our hooks.
  const fire = () => setTimeout(schedule, 0);
  for (const method of ['pushState', 'replaceState']) {
    const original = history[method];
    if (typeof original !== 'function') continue;
    history[method] = function () {
      const result = original.apply(this, arguments);
      fire();
      return result;
    };
  }
  addEventListener('popstate', fire);

  let lastUrl = '';
  setInterval(() => {
    if (location.href === lastUrl && layer && layer.parentElement) return;
    lastUrl = location.href;
    schedule();
  }, 250);

  load().catch((e) => log('load failed', e));
})();
