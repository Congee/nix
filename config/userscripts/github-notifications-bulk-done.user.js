// ==UserScript==
// @name           GitHub Notifications: Bulk Done for Merged/Closed
// @namespace      https://github.com/Congee/nix
// @version        1.0.2
// @description    Adds a button to github.com/notifications that scans EVERY page of the current inbox view (not just the first), finds notifications whose PR was merged/closed or whose issue was closed, and marks them all as Done in one shot. GitHub's built-in "select all" only covers the 25 rows of the current page, forcing you to repeat the selection page by page.
// @author         Congee
// @homepageURL    https://github.com/Congee/nix
// @supportURL     https://github.com/Congee/nix/issues
// @downloadURL    https://raw.githubusercontent.com/Congee/nix/master/config/userscripts/github-notifications-bulk-done.user.js
// @updateURL      https://raw.githubusercontent.com/Congee/nix/master/config/userscripts/github-notifications-bulk-done.user.js
// @match          https://github.com/*
// @icon           https://github.com/favicon.ico
// @run-at         document-idle
// @grant          none
// @license        MIT
// ==/UserScript==

(function () {
  'use strict';

  // ─── Configuration ──────────────────────────────────────────────────────
  const CONFIG = {
    markMergedPRs: true,   // purple "merged" pull requests
    markClosedPRs: true,   // red "closed without merging" pull requests
    markClosedIssues: true, // both "completed" and "closed as not planned"
    pageDelayMs: 400,      // politeness delay between page fetches
    batchSize: 25,         // ids per archive POST — matches GitHub's page size
    maxPages: 200,         // hard safety cap on pagination
  };

  // ─── How it works ───────────────────────────────────────────────────────
  // 1. Scan (read-only): fetch the current view page by page, following the
  //    paginator's "Next" cursor link, and classify each notification row by
  //    its state octicon. Scanning first means the cursors stay stable — no
  //    items shift between pages mid-walk.
  // 2. Archive: POST the collected notification ids in batches to the same
  //    endpoint the UI's own "Done" button submits to, reusing the
  //    authenticity token scraped from that form. Marking as Done is
  //    reversible from the Done tab.
  const ARCHIVE_FALLBACK = '/notifications/beta/archive';

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  // ─── Row classification ─────────────────────────────────────────────────
  // State comes from the row's octicon; PR-vs-issue comes from the link href.
  // octicon-skip needs the href check because skipped CI runs use it too.
  function classify(li) {
    const href =
      li.querySelector('a[href*="/pull/"], a[href*="/issues/"]')?.getAttribute('href') || '';
    for (const svg of li.querySelectorAll('svg.octicon')) {
      const c = svg.classList;
      if (c.contains('octicon-git-merge')) return 'merged-pr';
      if (c.contains('octicon-git-pull-request-closed')) return 'closed-pr';
      if (c.contains('octicon-issue-closed')) return 'closed-issue';
      if (c.contains('octicon-skip') && href.includes('/issues/')) return 'closed-issue';
    }
    return null;
  }

  const WANTED = () => ({
    'merged-pr': CONFIG.markMergedPRs,
    'closed-pr': CONFIG.markClosedPRs,
    'closed-issue': CONFIG.markClosedIssues,
  });

  function notificationId(li) {
    return (
      li.querySelector('input[name="notification_ids[]"]')?.value ||
      li.dataset.notificationId ||
      null
    );
  }

  // ─── Page fetching & parsing ────────────────────────────────────────────
  // Firefox runs this script in Violentmonkey's sandbox (GitHub's CSP blocks
  // page injection), and the sandbox's fetch() has no document base URL, so
  // relative URLs throw "not a valid URL" — always fetch absolute URLs.
  async function fetchDoc(url) {
    const res = await fetch(new URL(url, location.href).href, {
      credentials: 'same-origin',
      headers: { Accept: 'text/html' },
    });
    if (!res.ok) throw new Error(`GET ${url} → HTTP ${res.status}`);
    return new DOMParser().parseFromString(await res.text(), 'text/html');
  }

  // The "Done" button lives in a per-row / bulk-bar form; steal its action
  // URL and CSRF token instead of hardcoding, so endpoint renames don't
  // silently break the POST. "unarchive" forms (Done tab) are excluded.
  function findArchiveForm(doc) {
    for (const f of doc.querySelectorAll('form[action*="archive"]')) {
      const action = f.getAttribute('action') || '';
      if (action.includes('unarchive') || !action.includes('/notifications/')) continue;
      const token = f.querySelector('input[name="authenticity_token"]')?.value;
      if (token) return { action, token };
    }
    return null;
  }

  // The paginator renders "Next" as an <a> with an ?after= cursor when there
  // is a next page, and as a disabled <button> when there is not.
  function nextPageUrl(doc) {
    for (const a of doc.querySelectorAll('a[href*="after="]')) {
      if (a.textContent.trim().toLowerCase() === 'next')
        return new URL(a.getAttribute('href'), location.href).href;
    }
    return null;
  }

  // ─── Phase 1: scan all pages (read-only) ────────────────────────────────
  async function scanAllPages(log) {
    const wanted = WANTED();
    const visited = new Set(); // guards against cursor loops
    const found = new Map(); // id → kind
    let archiveForm = null;
    let url = location.href; // respect the current filter/query
    let pages = 0;

    while (url && pages < CONFIG.maxPages && !visited.has(url)) {
      visited.add(url);
      pages += 1;
      const doc = await fetchDoc(url);
      archiveForm = archiveForm || findArchiveForm(doc);

      const rows = doc.querySelectorAll('li.notifications-list-item, li.js-notifications-list-item');
      for (const li of rows) {
        const kind = classify(li);
        if (!kind || !wanted[kind]) continue;
        const id = notificationId(li);
        if (id) found.set(id, kind);
      }

      log(`scanned page ${pages} — ${found.size} matching so far`);
      url = nextPageUrl(doc);
      if (url) await sleep(CONFIG.pageDelayMs);
    }

    return { found, pages, archiveForm };
  }

  // ─── Phase 2: archive in batches ────────────────────────────────────────
  async function archiveIds(ids, form, log) {
    const endpoint = new URL(form.action || ARCHIVE_FALLBACK, location.origin);
    let done = 0;
    for (let i = 0; i < ids.length; i += CONFIG.batchSize) {
      const batch = ids.slice(i, i + CONFIG.batchSize);
      const body = new URLSearchParams();
      body.append('authenticity_token', form.token);
      for (const id of batch) body.append('notification_ids[]', id);
      const res = await fetch(endpoint, {
        method: 'POST',
        body,
        credentials: 'same-origin',
        headers: { Accept: 'text/html, application/xhtml+xml' },
      });
      if (!res.ok) throw new Error(`archive batch failed: HTTP ${res.status}`);
      done += batch.length;
      log(`marked ${done}/${ids.length} as Done`);
      await sleep(150);
    }
    return done;
  }

  // ─── UI: floating panel on /notifications ───────────────────────────────
  // Built with createElement only — github.com enforces Trusted Types, which
  // rejects innerHTML from userscripts.
  const PANEL_ID = 'vm-gh-bulk-done';

  function buildPanel() {
    const panel = document.createElement('div');
    panel.id = PANEL_ID;
    Object.assign(panel.style, {
      position: 'fixed',
      bottom: '16px',
      right: '16px',
      zIndex: '2147483647',
      display: 'flex',
      flexDirection: 'column',
      gap: '6px',
      alignItems: 'flex-end',
      font: '12px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    });

    const logWrap = document.createElement('div');
    logWrap.style.display = 'none';
    logWrap.style.position = 'relative';

    const logEl = document.createElement('div');
    Object.assign(logEl.style, {
      maxWidth: '320px',
      maxHeight: '120px',
      overflowY: 'auto',
      padding: '6px 24px 6px 10px',
      borderRadius: '6px',
      whiteSpace: 'pre-line',
      background: 'var(--bgColor-default, var(--color-canvas-default, #fff))',
      color: 'var(--fgColor-default, var(--color-fg-default, #1f2328))',
      border: '1px solid var(--borderColor-default, var(--color-border-default, #d0d7de))',
      boxShadow: '0 3px 12px rgba(0,0,0,.25)',
    });

    const closeBtn = document.createElement('button');
    closeBtn.type = 'button';
    closeBtn.textContent = '×';
    closeBtn.title = 'Dismiss';
    Object.assign(closeBtn.style, {
      position: 'absolute',
      top: '1px',
      right: '4px',
      padding: '0 4px',
      border: 'none',
      background: 'transparent',
      color: 'var(--fgColor-muted, var(--color-fg-muted, #848d97))',
      fontSize: '16px',
      lineHeight: '1.4',
      cursor: 'pointer',
    });
    closeBtn.addEventListener('click', () => {
      logWrap.style.display = 'none';
    });
    logWrap.append(logEl, closeBtn);

    let hideTimer = null;
    const lines = [];
    const log = (msg) => {
      clearTimeout(hideTimer);
      logWrap.style.display = 'block';
      lines.push(msg);
      logEl.textContent = lines.slice(-8).join('\n');
      logEl.scrollTop = logEl.scrollHeight;
    };
    // Benign endings fade on their own; errors stay until dismissed via ×.
    const scheduleHide = () => {
      clearTimeout(hideTimer);
      hideTimer = setTimeout(() => {
        logWrap.style.display = 'none';
      }, 10000);
    };

    const btn = document.createElement('button');
    btn.type = 'button';
    btn.textContent = '✓ Done: merged & closed (all pages)';
    Object.assign(btn.style, {
      padding: '6px 12px',
      borderRadius: '6px',
      cursor: 'pointer',
      fontWeight: '600',
      color: '#fff',
      background: 'var(--bgColor-done-emphasis, var(--color-done-emphasis, #8250df))',
      border: '1px solid rgba(0,0,0,.15)',
      boxShadow: '0 3px 12px rgba(0,0,0,.25)',
    });

    btn.addEventListener('click', async () => {
      btn.disabled = true;
      btn.style.opacity = '.6';
      lines.length = 0;
      let sticky = false;
      try {
        const query = new URLSearchParams(location.search).get('query') || '';
        if (query.includes('is:done')) log('note: this is the Done view — these are already Done');

        log('scanning…');
        const { found, pages, archiveForm } = await scanAllPages(log);
        if (found.size === 0) {
          log(`nothing to do — no merged/closed notifications in ${pages} page(s)`);
          return;
        }

        const tally = { 'merged-pr': 0, 'closed-pr': 0, 'closed-issue': 0 };
        for (const kind of found.values()) tally[kind] += 1;
        const summary =
          `${tally['merged-pr']} merged PRs, ${tally['closed-pr']} closed PRs, ` +
          `${tally['closed-issue']} closed issues across ${pages} page(s)`;
        log(summary);

        if (!confirm(`Mark ${found.size} notifications as Done?\n\n${summary}\n\n(Reversible from the Done tab.)`)) {
          log('cancelled');
          return;
        }

        const form = findArchiveForm(document) || archiveForm;
        if (!form) throw new Error('no archive form found — GitHub markup may have changed');
        await archiveIds([...found.keys()], form, log);
        log('all done — reloading…');
        await sleep(800);
        location.reload();
      } catch (err) {
        sticky = true;
        log(`error: ${err.message}`);
      } finally {
        btn.disabled = false;
        btn.style.opacity = '1';
        if (!sticky) scheduleHide();
      }
    });

    panel.append(logWrap, btn);
    return panel;
  }

  // GitHub is a Turbo app: soft navigations replace <body> without a page
  // load, so (re)mount on turbo:load rather than only at injection time.
  function mount() {
    const existing = document.getElementById(PANEL_ID);
    if (!location.pathname.startsWith('/notifications')) {
      existing?.remove();
      return;
    }
    if (!existing) document.body.appendChild(buildPanel());
  }

  document.addEventListener('turbo:load', mount);
  mount();
})();
