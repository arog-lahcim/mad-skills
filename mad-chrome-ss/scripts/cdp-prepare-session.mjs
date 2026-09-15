#!/usr/bin/env node
/**
 * Prepare Chrome for Testing session: tabs, highlight, options page, backdrop.
 * Env: DEBUG_PORT, ACTIVE_URL, OPTIONS_PAGE, HIGHLIGHT_TABS, EXTRA_TAB_URL,
 *      LOCALE_SUFFIX (1|0), FOREGROUND_WINDOW_TITLE (optional log)
 */

const DEBUG_PORT = Number(process.env.DEBUG_PORT || 9224);
const LOCALE_SUFFIX = process.env.LOCALE_SUFFIX !== '0';
const ACTIVE_URL = process.env.ACTIVE_URL || '';
const OPTIONS_PAGE = process.env.OPTIONS_PAGE || '';
const HIGHLIGHT_TABS = process.env.HIGHLIGHT_TABS || '';
const EXTRA_TAB_URL = process.env.EXTRA_TAB_URL || '';

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
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error(`CDP not available on port ${DEBUG_PORT}`);
}

async function listTargets() {
  const response = await fetch(`http://127.0.0.1:${DEBUG_PORT}/json/list`);
  if (!response.ok) {
    throw new Error(`Failed to list CDP targets: ${response.status}`);
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
  let worker = targets.find(
    (target) => target.type === 'service_worker' && target.url.startsWith('chrome-extension://'),
  );
  if (worker) {
    return worker;
  }

  const extensionPage = targets.find(
    (target) => target.type === 'page' && target.url.startsWith('chrome-extension://'),
  );
  if (!extensionPage) {
    throw new Error('No extension page or service worker found');
  }

  await evaluateOnTarget(
    extensionPage,
    "chrome.runtime.sendMessage({ type: 'mad-chrome-ss-wake' }).catch(() => undefined)",
  );
  await new Promise((resolve) => setTimeout(resolve, 400));

  const refreshed = await listTargets();
  worker = refreshed.find(
    (target) => target.type === 'service_worker' && target.url.startsWith('chrome-extension://'),
  );
  if (!worker) {
    throw new Error('Extension service worker not found after wake');
  }
  return worker;
}

function parseHighlightIndices() {
  if (!HIGHLIGHT_TABS.trim()) {
    return [];
  }
  return HIGHLIGHT_TABS.split(',').map((part) => Number(part.trim())).filter(Number.isInteger);
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

    if (${JSON.stringify(extraUrl)}) {
      await chrome.tabs.create({ windowId: win.id, url: ${JSON.stringify(extraUrl)}, active: false });
      tabs = (await chrome.tabs.query({ windowId: win.id })).sort((a, b) => a.index - b.index);
    }

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

    await new Promise((resolve) => setTimeout(resolve, 1500));

    tabs = (await chrome.tabs.query({ windowId: win.id })).sort((a, b) => a.index - b.index);
    const highlight = ${JSON.stringify(highlight)};
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
  const worker = await wakeServiceWorker(targets);
  const extensionId = new URL(worker.url).host;
  const result = await prepareViaWorker(worker, extensionId);
  console.log(JSON.stringify(result));
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
