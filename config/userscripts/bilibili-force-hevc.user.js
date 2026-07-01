// ==UserScript==
// @name           Bilibili Force H.265 (HEVC)
// @name:zh-CN     Bilibili 强制 H.265 (HEVC) 编码
// @namespace      https://github.com/Congee/nix
// @version        1.0.0
// @description    Force Bilibili's HTML5 player to use H.265/HEVC instead of AV1. AV1 has no hardware decoder on Firefox/Chromium on most Macs (software decode = high CPU/battery), whereas HEVC is hardware-accelerated via VideoToolbox. Safari already prefers HEVC; this makes Firefox/Chromium behave the same.
// @description:zh-CN 强制 B 站网页播放器使用 H.265/HEVC 编码，而非 AV1。AV1 在多数 Mac 的 Firefox/Chromium 上没有硬件解码（软解、费电费 CPU），HEVC 则可经 VideoToolbox 硬解。Safari 本就优先 HEVC，此脚本让 Firefox/Chromium 行为一致。
// @author         Congee
// @homepageURL    https://github.com/Congee/nix
// @supportURL     https://github.com/Congee/nix/issues
// @downloadURL    https://raw.githubusercontent.com/Congee/nix/master/config/userscripts/bilibili-force-hevc.user.js
// @updateURL      https://raw.githubusercontent.com/Congee/nix/master/config/userscripts/bilibili-force-hevc.user.js
// @match          *://www.bilibili.com/video/*
// @match          *://www.bilibili.com/list/*
// @match          *://www.bilibili.com/medialist/play/*
// @match          *://www.bilibili.com/watchlater/*
// @match          *://www.bilibili.com/bangumi/play/*
// @match          *://www.bilibili.com/blackboard/*
// @match          *://www.bilibili.com/festival/*
// @match          *://player.bilibili.com/*
// @icon           https://www.bilibili.com/favicon.ico
// @run-at         document-start
// @grant          none
// @license        MIT
// ==/UserScript==

(function () {
  'use strict';

  // ─── Configuration ──────────────────────────────────────────────────────
  // Bilibili's bpx player exposes a codec preference: player.setPreferCodec(n)
  // / player.getPreferCodec(), persisted to localStorage under LS_KEY.
  // The enum below was verified empirically against the live player:
  //   0 = Auto  → default_codec_strategy is ["av1","hevc","avc"], so it picks
  //               AV1, which is software-decoded on FF/Chromium on macOS.
  //   1 = HEVC / H.265  ← hardware-decoded on Apple Silicon & most Macs
  //   2 = AVC  / H.264   (hardware-decoded, but larger files than HEVC)
  //   3 = AV1
  // If your browser can't hardware-decode HEVC, the player transparently falls
  // back to AVC (also hardware-decoded) — either way you avoid software AV1.
  const TARGET_CODEC = 1; // HEVC
  const LS_KEY = 'bilibili_player_codec_prefer_type';

  // With @grant none the script shares the page realm, so the page's `window`
  // (and thus `window.player`) is directly reachable. unsafeWindow is used only
  // as a fallback for managers that still sandbox under @grant none.
  const win = (typeof unsafeWindow !== 'undefined') ? unsafeWindow : window;

  // ─── 1. Seed the stored preference BEFORE the player boots ────────────────
  // Runs at document-start, so the player reads it during initialization and
  // selects HEVC from the very first frame — no reload, no AV1 "flash".
  function seed() {
    try {
      if (localStorage.getItem(LS_KEY) !== String(TARGET_CODEC)) {
        localStorage.setItem(LS_KEY, String(TARGET_CODEC));
      }
    } catch (e) {
      // localStorage may be blocked; the API fallback below still corrects it.
    }
  }
  seed();

  // ─── 2. Enforce via the player API (drift correction / fallback) ──────────
  // If something reset the preference during init (player version guard, an A/B
  // config, or a manual change), fix it. A reload is issued ONLY when the live
  // preference is actually wrong — on a normally-seeded load it is already
  // correct, so enforce() returns immediately and never reloads.
  function enforce() {
    const p = win.player;
    if (!p || typeof p.getPreferCodec !== 'function' || typeof p.setPreferCodec !== 'function') {
      return false; // player not ready yet
    }
    let current;
    try {
      current = p.getPreferCodec();
    } catch (e) {
      return false;
    }
    if (current === TARGET_CODEC) {
      return true; // already correct — nothing to do
    }
    try {
      p.setPreferCodec(TARGET_CODEC);
      // The current media already loaded with the wrong codec, so a reload is
      // required to re-fetch the HEVC stream.
      if (typeof p.reload === 'function') {
        p.reload();
      }
    } catch (e) {
      // ignore
    }
    return true;
  }

  // Poll for the player for a bounded window after each (re)navigation.
  function runEnforcementWindow() {
    seed();
    let tries = 0;
    const timer = setInterval(function () {
      if (enforce() || ++tries > 40) { // ~20s ceiling
        clearInterval(timer);
      }
    }, 500);
  }
  runEnforcementWindow();

  // ─── 3. Re-apply on SPA navigation (video → video without a page reload) ──
  // Bilibili is a single-page app; navigating between videos often only calls
  // history.pushState. The persisted preference already covers new media, but
  // re-running enforcement is cheap insurance against any transient reset.
  const fire = function () { setTimeout(runEnforcementWindow, 0); };
  ['pushState', 'replaceState'].forEach(function (method) {
    const original = history[method];
    if (typeof original !== 'function') return;
    history[method] = function () {
      const result = original.apply(this, arguments);
      fire();
      return result;
    };
  });
  window.addEventListener('popstate', fire);
})();
