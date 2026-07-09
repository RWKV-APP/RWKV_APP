const String serpExtractionScript = r'''
(function () {
  const items = [];
  const seenUrls = new Set();
  const searchHosts = [
    'google.com',
    'bing.com',
    'baidu.com',
    'duckduckgo.com',
    'brave.com',
    'search.brave.com',
    'yahoo.com',
    'yandex.com',
    'ecosia.org',
    'startpage.com',
    'sogou.com'
  ];

  function decodeBase64Url(value) {
    const normalized = value.replace(/-/g, '+').replace(/_/g, '/');
    const padding = (4 - (normalized.length % 4)) % 4;
    return atob(normalized + '='.repeat(padding));
  }

  function decodeGoogleUrl(rawUrl, root) {
    try {
      if (root) {
        const baiduMu = root.getAttribute('mu') || root.getAttribute('data-mu');
        if (baiduMu && /^https?:\/\//i.test(baiduMu)) {
          rawUrl = baiduMu;
        } else {
          const feedback = root.querySelector('[data-feedback]');
          if (feedback) {
            try {
              const feedbackData = JSON.parse(feedback.getAttribute('data-feedback') || '{}');
              if (feedbackData.url && /^https?:\/\//i.test(feedbackData.url)) {
                rawUrl = feedbackData.url;
              }
            } catch (error) {}
          }
        }
      }

      const parsed = new URL(rawUrl, window.location.href);
      if (parsed.hostname.endsWith('google.com') && parsed.pathname === '/url') {
        rawUrl = parsed.searchParams.get('q') || parsed.searchParams.get('url') || rawUrl;
      }
      if (parsed.hostname.endsWith('bing.com') && parsed.pathname === '/ck/a') {
        rawUrl = parsed.searchParams.get('u') || rawUrl;
        if (rawUrl.startsWith('a1')) {
          rawUrl = decodeBase64Url(rawUrl.substring(2));
        }
      }
      const decoded = new URL(rawUrl, window.location.href);
      decoded.hash = '';
      return decoded.href;
    } catch (error) {
      return rawUrl;
    }
  }

  function hostnameEndsWith(hostname, suffix) {
    return hostname === suffix || hostname.endsWith('.' + suffix);
  }

  function isUsefulUrl(url) {
    if (!url) return false;
    if (!/^https?:\/\//i.test(url)) return false;
    try {
      const parsed = new URL(url);
      const hostname = parsed.hostname.toLowerCase();
      if (parsed.hostname.toLowerCase() === window.location.hostname.toLowerCase()) return false;
      if (isNoisySearchNavigationHost(hostname)) return false;
      if (hostnameEndsWith(parsed.hostname, 'gstatic.com')) return false;
      if (hostnameEndsWith(parsed.hostname, 'googleusercontent.com')) return false;
      if (hostnameEndsWith(parsed.hostname, 'bdstatic.com')) return false;
      if (hostnameEndsWith(parsed.hostname, 'bing.net')) return false;
      if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return false;
      return true;
    } catch (error) {
      return false;
    }
  }

  function isNoisySearchNavigationHost(hostname) {
    return (
      hostname === 'help.sogou.com' ||
      hostname === 'fankui.sogou.com' ||
      hostname === 'pic.sogou.com' ||
      hostname === 'weixin.sogou.com' ||
      hostname === 'v.sogou.com' ||
      hostname === 'zhihu.sogou.com' ||
      hostname === 'hanyu.sogou.com' ||
      hostname === 'fanyi.sogou.com' ||
      hostname === 'wenwen.sogou.com' ||
      hostname === 'as.sogou.com'
    );
  }

  function nearestResultRoot(anchor) {
    return (
      anchor.closest('div.MjjYud') ||
      anchor.closest('div.g') ||
      anchor.closest('li.b_algo') ||
      anchor.closest('div.result') ||
      anchor.closest('article') ||
      anchor.closest('div.c-container') ||
      anchor.closest('div.result-op') ||
      anchor.closest('div.vrwrap') ||
      anchor.closest('[data-testid="result"]') ||
      anchor.closest('[data-layout="organic"]') ||
      anchor.closest('.web-result') ||
      anchor.parentElement
    );
  }

  function cleanText(text) {
    return (text || '')
      .replace(/\u00a0/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  function removeFirstText(text, needle) {
    if (!needle) return text;
    const index = text.indexOf(needle);
    if (index < 0) return text;
    return cleanText(text.slice(0, index) + ' ' + text.slice(index + needle.length));
  }

  function looksLikeSnippet(text, title) {
    const clean = cleanText(text);
    if (!clean) return false;
    if (title && clean === cleanText(title)) return false;
    if (/^https?:\/\//i.test(clean) || /^www\./i.test(clean)) return false;
    if (/^(cached|similar|translate this page|images|videos|news|maps)$/i.test(clean)) return false;
    if (clean.length < 12 && !/[\u4e00-\u9fff]/.test(clean)) return false;
    return true;
  }

  function extractSelectedSnippet(root, title) {
    if (!root) return '';
    const selectors = [
      '.VwiC3b',
      '.hgKElc',
      '.yXK7lf',
      '.b_caption p',
      '.b_snippet',
      '.b_factrow',
      '.compText',
      '.result__snippet',
      '.snippet',
      '.snippet-content',
      '[data-result="snippet"]',
      '.c-abstract',
      '.c-span-last',
      '.fz-mid',
      '.vrwrap .str_info',
      '.organic__content-wrapper',
      '.OrganicTextContentSpan',
      '.web-result__snippet',
      '.Description'
    ];
    for (const selector of selectors) {
      const nodes = Array.from(root.querySelectorAll(selector));
      for (const node of nodes) {
        const text = cleanText(node.innerText || node.textContent || '');
        if (looksLikeSnippet(text, title)) return text.slice(0, 300);
      }
    }
    return '';
  }

  function stripNoisyNodes(root) {
    const clone = root.cloneNode(true);
    const selectors = [
      'script',
      'style',
      'noscript',
      'svg',
      'button',
      'input',
      'textarea',
      'select',
      'nav',
      '[role="button"]',
      '[aria-hidden="true"]',
      '.action-menu',
      '.b_attribution',
      '.b_ad',
      '.ads-ad',
      '.uEierd'
    ];
    for (const node of clone.querySelectorAll(selectors.join(','))) {
      node.remove();
    }
    return clone;
  }

  function extractTitle(anchor, root, requireHeading) {
    const heading = anchor.querySelector('h3') || (root ? root.querySelector('h3') : null);
    if (requireHeading && !heading) return '';
    const text = heading ? heading.innerText : anchor.innerText;
    return cleanText(text);
  }

  function extractSnippet(root, title) {
    if (!root) return '';
    const selected = extractSelectedSnippet(root, title);
    if (selected) return selected;

    const clone = stripNoisyNodes(root);
    let text = cleanText(clone.innerText || clone.textContent || '');
    if (!text) return '';
    text = removeFirstText(text, title);
    text = text
      .replace(/\b(Cached|Similar|Translate this page|About featured snippets)\b/gi, ' ')
      .replace(/\s+/g, ' ')
      .trim();
    if (!looksLikeSnippet(text, title)) return '';
    return text.slice(0, 300);
  }

  function addItem(title, url, snippet) {
    if (!isUsefulUrl(url)) return;
    if (seenUrls.has(url)) return;
    const cleanTitle = cleanText(title);
    if (!cleanTitle) return;

    seenUrls.add(url);
    items.push({
      title: cleanTitle,
      url,
      snippet: cleanText(snippet).slice(0, 300)
    });
  }

  function addAnchor(anchor, requireHeading) {
    const root = nearestResultRoot(anchor);
    const url = decodeGoogleUrl(anchor.href, root);
    const title = extractTitle(anchor, root, requireHeading);
    if (!title) return;
    addItem(title, url, extractSnippet(root, title));
  }

  function extractBingTitle(root, anchor) {
    const heading = root.querySelector('h2, h3');
    const headingText = heading ? cleanText(heading.innerText || heading.textContent || '') : '';
    if (headingText) return headingText;

    const anchorText = cleanText(anchor.innerText || anchor.textContent || '');
    let text = cleanText(root.innerText || root.textContent || '');
    if (anchorText && text.startsWith(anchorText)) {
      text = cleanText(text.slice(anchorText.length));
    }
    const dateMatch = text.match(/(\d+\s*(秒|分钟|小时|天|周|个月|年)(之前|前)?|\d{4}年\d{1,2}月\d{1,2}日|\d{4}年\d{1,2}月|\d{4}年|[A-Z][a-z]+ \d{1,2}, \d{4})/);
    if (dateMatch && typeof dateMatch.index === 'number' && dateMatch.index > 0) {
      return cleanText(text.slice(0, dateMatch.index));
    }
    return text.slice(0, 160);
  }

  function collectBingResults() {
    const roots = Array.from(document.querySelectorAll('li.b_algo'));
    for (const root of roots) {
      const anchors = Array.from(root.querySelectorAll('a[href]'));
      for (const anchor of anchors) {
        const url = decodeGoogleUrl(anchor.href, root);
        if (!isUsefulUrl(url)) continue;
        const title = extractBingTitle(root, anchor);
        if (!title) continue;
        addItem(title, url, extractSnippet(root, title));
        break;
      }
      if (items.length >= 10) break;
    }
  }

  function detectBlockedPage() {
    const bodyText = (document.body && document.body.innerText ? document.body.innerText : '').replace(/\s+/g, ' ').toLowerCase();
    if (bodyText.includes('verify you are human')) return 'Search page requires human verification.';
    if (bodyText.includes('one last step')) return 'Search page requires human verification.';
    if (bodyText.includes('最后一步')) return 'Search page requires human verification.';
    if (bodyText.includes('请解决以下难题')) return 'Search page requires human verification.';
    if (bodyText.includes('captcha')) return 'Search page requires CAPTCHA verification.';
    if (bodyText.includes('unusual traffic')) return 'Search page blocked automated traffic.';
    if (bodyText.includes('not a robot')) return 'Search page requires robot verification.';
    if (bodyText.includes('our systems have detected unusual traffic')) return 'Search page blocked automated traffic.';
    return '';
  }

  function collectHeadingResults() {
    const headings = Array.from(document.querySelectorAll('a[href] h1, a[href] h2, a[href] h3, h1 a[href], h2 a[href], h3 a[href]'));
    for (const heading of headings) {
      const anchor = heading.matches('a[href]') ? heading : heading.closest('a[href]');
      if (!anchor) continue;
      addAnchor(anchor, true);
      if (items.length >= 10) break;
    }
  }

  function collectResults(requireHeading) {
    const anchors = Array.from(document.querySelectorAll('a[href]'));
    for (const anchor of anchors) {
      addAnchor(anchor, requireHeading);
      if (items.length >= 10) break;
    }
  }

  function debugSnapshot() {
    const anchors = Array.from(document.querySelectorAll('a[href]'));
    return {
      bodyTextLength: document.body && document.body.innerText ? document.body.innerText.length : 0,
      bodyTextSample: cleanText(document.body && document.body.innerText ? document.body.innerText : '').slice(0, 500),
      anchorCount: anchors.length,
      headingAnchorCount: document.querySelectorAll('a[href] h1, a[href] h2, a[href] h3, h1 a[href], h2 a[href], h3 a[href]').length,
      bAlgoCount: document.querySelectorAll('li.b_algo').length,
      cContainerCount: document.querySelectorAll('div.c-container').length,
      resultCount: document.querySelectorAll('div.result, article, [data-testid="result"], [data-layout="organic"], .web-result').length,
      bAlgoSamples: Array.from(document.querySelectorAll('li.b_algo')).slice(0, 5).map((node) => {
        const anchor = node.querySelector('a[href]');
        return {
          text: cleanText(node.innerText || node.textContent || '').slice(0, 240),
          anchorText: anchor ? cleanText(anchor.innerText || anchor.textContent || '').slice(0, 160) : '',
          href: anchor ? anchor.href : ''
        };
      }),
      anchorSamples: anchors.slice(0, 20).map((anchor) => ({
        text: cleanText(anchor.innerText || anchor.textContent || '').slice(0, 160),
        href: anchor.href
      }))
    };
  }

  collectBingResults();
  collectHeadingResults();
  if (items.length < 3) collectResults(true);
  if (items.length < 3) collectResults(false);

  return JSON.stringify({
    href: window.location.href,
    title: document.title,
    error: detectBlockedPage(),
    items,
    debug: debugSnapshot()
  });
})();
''';
