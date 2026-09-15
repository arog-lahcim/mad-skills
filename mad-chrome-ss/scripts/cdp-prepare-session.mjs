#!/usr/bin/env node
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

/**
 * Prepare Chrome for Testing session: tabs, highlight, options page, backdrop.
 * Env: DEBUG_PORT, ACTIVE_URL, ACTIVE_TAB_INDEX, TAB_URLS, OPTIONS_PAGE,
 *      HIGHLIGHT_TABS, EXTRA_TAB_URL, LOCALE_SUFFIX (1|0)
 */

const DEBUG_PORT = Number(process.env.DEBUG_PORT || 9224);
const SESSION_PID = process.env.SESSION_PID || 'unknown';
const LOCALE_SUFFIX = process.env.LOCALE_SUFFIX !== '0';
const ACTIVE_URL = process.env.ACTIVE_URL || '';
const ACTIVE_TAB_INDEX = process.env.ACTIVE_TAB_INDEX ?? '';
const TAB_URLS = process.env.TAB_URLS || '';
const OPTIONS_PAGE = process.env.OPTIONS_PAGE || '';
const HIGHLIGHT_TABS = process.env.HIGHLIGHT_TABS || '';
const EXTRA_TAB_URL = process.env.EXTRA_TAB_URL || '';
const EXTENSION_DIR = process.env.EXTENSION_DIR || '';

const manifest = JSON.parse(
  readFileSync(join(EXTENSION_DIR, 'manifest.json'), 'utf8'),
);
const serviceWorkerPath = `/${manifest.background?.service_worker || ''}`;
const extensionId = createHash('sha256')
  .update(EXTENSION_DIR)
  .digest('hex')
  .slice(0, 32)
  .replace(/[0-9a-f]/g, (digit) => String.fromCharCode(97 + Number.parseInt(digit, 16)));
const extensionPagePath = manifest.options_ui?.page
  || manifest.options_page
  || manifest.background?.service_worker;

function isTargetExtensionWorker(target) {
  if (target.type !== 'service_worker' || !target.url.startsWith('chrome-extension://')) {
    return false;
  }
  return new URL(target.url).pathname === serviceWorkerPath;
}

function withLocale(url) {
  if (!LOCALE_SUFFIX || !/^https?:\/\//.test(url)) {
    return url;
  }
  if (/[?&]hl=/.test(url)) {
    return url;
  }
  if (/youtube\.com/i.test(url)) {
    return url.includes('?') ? `${url}&hl=en&gl=US` : `${url}?hl=en&gl=US`;
  }
  return url.includes('?') ? `${url}&hl=en` : `${url}?hl=en`;
}

const POLL_INTERVAL_MS = 250;
const WORKER_POLL_INTERVAL_MS = 100;
const WORKER_POLL_ATTEMPTS = 20;

function seconds(attempts, intervalMs) {
  return ((attempts * intervalMs) / 1000).toFixed(1);
}

async function waitForDebugger(maxAttempts = 40) {
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    try {
      const response = await fetch(`http://127.0.0.1:${DEBUG_PORT}/json/version`);
      if (response.ok) {
        return;
      }
    } catch {
      // retry
    }
    await new Promise((resolve) => setTimeout(resolve, POLL_INTERVAL_MS));
  }
  throw new Error(
    `CDP not available on port ${DEBUG_PORT} after ${seconds(maxAttempts, POLL_INTERVAL_MS)}s of polling `
    + `(pid=${SESSION_PID}); check for a port conflict or a launch that never opened the port`,
  );
}

async function listTargets() {
  const response = await fetch(`http://127.0.0.1:${DEBUG_PORT}/json/list`);
  if (!response.ok) {
    throw new Error(`Failed to list CDP targets: ${response.status}`);
  }
  return response.json();
}

async function createTarget(url) {
  const response = await fetch(
    `http://127.0.0.1:${DEBUG_PORT}/json/new?${encodeURIComponent(url)}`,
    { method: 'PUT' },
  );
  if (!response.ok) {
    throw new Error(`Failed to create CDP target: ${response.status}`);
  }
  return response.json();
}

async function evaluateOnTarget(target, expression) {
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    ws.onopen = resolve;
    ws.onerror = reject;
  });

  return new Promise((resolve, reject) => {
    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      if (message.id !== 1) {
        return;
      }
      ws.close();
      if (message.result?.exceptionDetails) {
        reject(new Error(JSON.stringify(message.result.exceptionDetails)));
        return;
      }
      resolve(message.result?.result?.value);
    };
    ws.send(
      JSON.stringify({
        id: 1,
        method: 'Runtime.evaluate',
        params: { expression, awaitPromise: true, returnByValue: true },
      }),
    );
  });
}

async function wakeServiceWorker(targets) {
  const state = { state: 'missing', wakeAttempted: false, pollTimeoutSeconds: null };
  let worker = targets.find(isTargetExtensionWorker);
  if (worker) {
    state.state = 'running';
    return { worker, state };
  }

  let currentTargets = targets;
  for (let attempt = 0; attempt < WORKER_POLL_ATTEMPTS && !worker; attempt += 1) {
    currentTargets = await listTargets();
    worker = currentTargets.find(isTargetExtensionWorker);
    if (!worker) {
      await new Promise((resolve) => setTimeout(resolve, WORKER_POLL_INTERVAL_MS));
    }
  }
  state.pollTimeoutSeconds = Number(seconds(WORKER_POLL_ATTEMPTS, WORKER_POLL_INTERVAL_MS));
  if (worker) {
    state.state = 'running-after-poll';
    return { worker, state };
  }

  let extensionPage = currentTargets.find(
    (target) => target.type === 'page' && new URL(target.url).host === extensionId,
  );
  if (!extensionPage && extensionPagePath) {
    extensionPage = await createTarget(
      `chrome-extension://${extensionId}/${extensionPagePath.replace(/^\//, '')}`,
    );
  }
  if (!extensionPage) {
    throw new Error(
      `No extension page or service worker found: port=${DEBUG_PORT} pid=${SESSION_PID} `
      + `serviceWorkerState=missing after ${state.pollTimeoutSeconds}s of polling; `
      + `targets=${currentTargets.map((target) => target.type).join(',') || 'none'}`,
    );
  }

  state.wakeAttempted = true;
  await evaluateOnTarget(
    extensionPage,
    "chrome.runtime.sendMessage({ type: 'mad-chrome-ss-wake' }).catch(() => undefined)",
  );
  for (let attempt = 0; attempt < WORKER_POLL_ATTEMPTS && !worker; attempt += 1) {
    const refreshed = await listTargets();
    worker = refreshed.find(isTargetExtensionWorker);
    if (!worker) {
      await new Promise((resolve) => setTimeout(resolve, WORKER_POLL_INTERVAL_MS));
    }
  }
  if (!worker) {
    throw new Error(
      `Extension service worker not found after wake: port=${DEBUG_PORT} pid=${SESSION_PID} `
      + `serviceWorkerState=asleep serviceWorkerPath=${serviceWorkerPath} `
      + `pollTimeout=${state.pollTimeoutSeconds}s per phase`,
    );
  }
  state.state = 'woken';
  return { worker, state };
}

function parseHighlightIndices() {
  if (!HIGHLIGHT_TABS.trim()) {
    return [];
  }
  return HIGHLIGHT_TABS.split(',').map((part) => Number(part.trim())).filter(Number.isInteger);
}

function parseTabUrls() {
  if (!TAB_URLS.trim()) {
    return [];
  }
  return TAB_URLS.split(',').map((part) => withLocale(part.trim())).filter(Boolean);
}

function parseActiveTabIndex() {
  if (ACTIVE_TAB_INDEX === '') {
    return null;
  }
  const index = Number(ACTIVE_TAB_INDEX);
  if (!Number.isInteger(index) || index < 0) {
    throw new Error('ACTIVE_TAB_INDEX must be a non-negative integer');
  }
  return index;
}

async function prepareViaWorker(worker, extensionId) {
  const optionsUrl = OPTIONS_PAGE.startsWith('chrome-extension://')
    ? OPTIONS_PAGE
    : OPTIONS_PAGE
      ? `chrome-extension://${extensionId}/${OPTIONS_PAGE.replace(/^\//, '')}`
      : '';

  const highlight = parseHighlightIndices();
  const activeUrl = ACTIVE_URL ? withLocale(ACTIVE_URL) : '';
  const extraUrl = EXTRA_TAB_URL ? withLocale(EXTRA_TAB_URL) : '';
  const tabUrlList = parseTabUrls();
  const activeTabIndex = parseActiveTabIndex();
  if (
    activeTabIndex !== null
    && highlight.length > 0
    && !highlight.includes(activeTabIndex)
  ) {
    throw new Error('ACTIVE_TAB_INDEX must be included in HIGHLIGHT_TABS');
  }
  const orderedHighlight = activeTabIndex === null
    ? highlight
    : [activeTabIndex, ...highlight.filter((index) => index !== activeTabIndex)];

  const expression = `(async () => {
    const win = (await chrome.windows.getAll({ populate: true })).find((item) => item.type === 'normal');
    if (!win) throw new Error('Normal window not found');

    const others = (await chrome.windows.getAll()).filter(
      (item) => item.type === 'normal' && item.id !== win.id,
    );
    if (others.length) {
      await Promise.all(others.map((item) => chrome.windows.remove(item.id)));
    }

    let tabs = (await chrome.tabs.query({ windowId: win.id })).sort((a, b) => a.index - b.index);
    const waitForTabs = async (minimumCount) => {
      const deadline = Date.now() + 15000;
      while (Date.now() < deadline) {
        const current = await chrome.tabs.query({ windowId: win.id });
        if (
          current.length >= minimumCount
          && current.every((tab) => tab.status === 'complete')
        ) {
          return current.sort((a, b) => a.index - b.index);
        }
        await new Promise((resolve) => setTimeout(resolve, 200));
      }
      throw new Error('Timed out waiting for tabs to finish loading');
    };

    if (${JSON.stringify(extraUrl)}) {
      await chrome.tabs.create({ windowId: win.id, url: ${JSON.stringify(extraUrl)}, active: false });
      tabs = (await chrome.tabs.query({ windowId: win.id })).sort((a, b) => a.index - b.index);
    }

    const tabUrlList = ${JSON.stringify(tabUrlList)};
    if (tabUrlList.length) {
      for (let index = 0; index < tabUrlList.length; index += 1) {
        const url = tabUrlList[index];
        if (tabs[index]) {
          await chrome.tabs.update(tabs[index].id, { url });
        } else {
          await chrome.tabs.create({ windowId: win.id, url, active: false });
        }
      }
    } else {
      const updates = [];
      if (${JSON.stringify(activeUrl)}) {
        updates.push({ index: 0, url: ${JSON.stringify(activeUrl)} });
      }
      if (${JSON.stringify(optionsUrl)}) {
        const targetIndex = tabs.length > 2 ? 2 : Math.max(0, tabs.length - 1);
        updates.push({ index: targetIndex, url: ${JSON.stringify(optionsUrl)} });
      }
      for (const update of updates) {
        const tab = tabs[update.index];
        if (tab) {
          await chrome.tabs.update(tab.id, { url: update.url });
        }
      }
    }

    tabs = await waitForTabs(Math.max(1, tabUrlList.length));
    const highlight = ${JSON.stringify(orderedHighlight)};
    const activeTabIndex = ${JSON.stringify(activeTabIndex)};
    if (highlight.length) {
      await chrome.tabs.highlight({ windowId: win.id, tabs: highlight });
    } else if (${JSON.stringify(optionsUrl)}) {
      const optionsIndex = tabs.findIndex((tab) => tab.url.startsWith('chrome-extension://'));
      if (optionsIndex >= 0) {
        await chrome.tabs.update(tabs[optionsIndex].id, { active: true });
      }
    } else if (${JSON.stringify(activeUrl)}) {
      await chrome.tabs.update(tabs[0].id, { active: true });
    }

    if (!highlight.length && activeTabIndex !== null && tabs[activeTabIndex]) {
      await chrome.tabs.update(tabs[activeTabIndex].id, { active: true });
    }

    const background = await chrome.windows.create({ url: 'about:blank', focused: false });
    await chrome.windows.update(win.id, { focused: true });

    return {
      foregroundWindowId: win.id,
      backgroundWindowId: background.id,
      tabs: (await chrome.tabs.query({ windowId: win.id })).map((tab) => ({
        index: tab.index,
        title: tab.title,
        highlighted: tab.highlighted,
        active: tab.active,
        url: tab.url,
      })),
    };
  })()`;

  return evaluateOnTarget(worker, expression);
}

async function main() {
  await waitForDebugger();
  const targets = await listTargets();
  const { worker, state } = await wakeServiceWorker(targets);
  const result = await prepareViaWorker(worker, extensionId);
  console.log(JSON.stringify({ ...result, serviceWorker: state, debugPort: DEBUG_PORT }));
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
