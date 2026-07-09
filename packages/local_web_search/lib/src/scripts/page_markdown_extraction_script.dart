const String pageMarkdownExtractionScript = r'''
(function () {
  const maxOutputChars = 12000;
  const blockTags = new Set([
    'ADDRESS',
    'ARTICLE',
    'ASIDE',
    'BLOCKQUOTE',
    'DD',
    'DETAILS',
    'DIV',
    'DL',
    'DT',
    'FIGCAPTION',
    'FIGURE',
    'FOOTER',
    'FORM',
    'H1',
    'H2',
    'H3',
    'H4',
    'H5',
    'H6',
    'HEADER',
    'HR',
    'LI',
    'MAIN',
    'NAV',
    'OL',
    'P',
    'PRE',
    'SECTION',
    'TABLE',
    'UL'
  ]);
  const noisySelectors = [
    'script',
    'style',
    'noscript',
    'template',
    'svg',
    'canvas',
    'iframe',
    'nav',
    'footer',
    'header',
    'aside',
    'form',
    'button',
    'input',
    'select',
    'textarea',
    '[role="navigation"]',
    '[role="banner"]',
    '[role="contentinfo"]',
    '[role="complementary"]',
    '[aria-hidden="true"]',
    '.ad',
    '.ads',
    '.advert',
    '.advertisement',
    '.banner',
    '.breadcrumb',
    '.breadcrumbs',
    '.cookie',
    '.comments',
    '.comment',
    '.copyright',
    '.download',
    '.footer',
    '.header',
    '.menu',
    '.nav',
    '.navbar',
    '.newsletter',
    '.pagination',
    '.popup',
    '.promo',
    '.related',
    '.share',
    '.sharing',
    '.sidebar',
    '.social',
    '.sponsor',
    '.toolbar',
    '#comments',
    '#footer',
    '#header',
    '#navigation',
    '#sidebar'
  ];

  function cleanInline(text) {
    return (text || '')
      .replace(/\u00a0/g, ' ')
      .replace(/[ \t\r\f\v]+/g, ' ')
      .trim();
  }

  function cleanBlock(text) {
    return (text || '')
      .replace(/\u00a0/g, ' ')
      .replace(/[ \t\r\f\v]+/g, ' ')
      .replace(/\n[ \t]+/g, '\n')
      .replace(/[ \t]+\n/g, '\n')
      .replace(/\n{3,}/g, '\n\n')
      .trim();
  }

  function textOf(node) {
    return cleanInline(node.innerText || node.textContent || '');
  }

  function linkDensity(node) {
    const textLength = textOf(node).length;
    if (textLength === 0) return 1;
    let linkLength = 0;
    for (const link of Array.from(node.querySelectorAll('a'))) {
      linkLength += textOf(link).length;
    }
    return linkLength / textLength;
  }

  function removeNoisyNodes(root) {
    for (const node of Array.from(root.querySelectorAll(noisySelectors.join(',')))) {
      node.remove();
    }
    for (const node of Array.from(root.querySelectorAll('*'))) {
      const text = textOf(node);
      if (!text && node.children.length === 0 && node.tagName !== 'IMG') {
        node.remove();
        continue;
      }
      const classAndId = `${node.id || ''} ${node.className || ''}`.toLowerCase();
      if (/(^|\s)(ad|ads|advert|cookie|footer|header|menu|nav|popup|promo|share|social|sponsor|toolbar)(\s|$)/.test(classAndId)) {
        node.remove();
        continue;
      }
      if (text.length < 80 && linkDensity(node) > 0.85) {
        node.remove();
      }
    }
  }

  function candidateRoots() {
    const selectors = [
      'main',
      'article',
      '[role="main"]',
      '.main',
      '.content',
      '.post',
      '.article',
      '.entry-content',
      '.post-content',
      '.page-content',
      '#content',
      '#main'
    ];
    const nodes = [];
    for (const selector of selectors) {
      for (const node of Array.from(document.querySelectorAll(selector))) {
        if (!nodes.includes(node)) nodes.push(node);
      }
    }
    nodes.push(document.body);
    return nodes;
  }

  function candidateScore(node) {
    const text = textOf(node);
    if (text.length === 0) return 0;
    const density = linkDensity(node);
    const headingBonus = node.querySelectorAll('h1,h2,h3').length * 80;
    const paragraphBonus = node.querySelectorAll('p').length * 35;
    const listBonus = node.querySelectorAll('li').length * 10;
    const tableBonus = node.querySelectorAll('table').length * 60;
    return text.length * Math.max(0.05, 1 - density) + headingBonus + paragraphBonus + listBonus + tableBonus;
  }

  function selectMainRoot() {
    let selected = document.body;
    let selectedScore = 0;
    for (const node of candidateRoots()) {
      const score = candidateScore(node);
      if (score <= selectedScore) continue;
      selected = node;
      selectedScore = score;
    }
    return selected || document.body;
  }

  function childMarkdown(node, depth) {
    const parts = [];
    for (const child of Array.from(node.childNodes)) {
      const value = nodeMarkdown(child, depth);
      if (!value) continue;
      parts.push(value);
    }
    return cleanBlock(parts.join('\n\n'));
  }

  function inlineMarkdown(node, depth) {
    const parts = [];
    for (const child of Array.from(node.childNodes)) {
      const value = nodeMarkdown(child, depth);
      if (!value) continue;
      parts.push(value);
    }
    return cleanInline(parts.join(' '));
  }

  function tableMarkdown(node) {
    const rows = [];
    for (const row of Array.from(node.querySelectorAll('tr'))) {
      const cells = Array.from(row.children)
        .filter((cell) => cell.matches('th,td'))
        .map((cell) => cleanInline(cell.innerText || cell.textContent || ''))
        .filter((text) => text.length > 0);
      if (cells.length === 0) continue;
      rows.push(cells);
    }
    if (rows.length === 0) return '';
    const columnCount = Math.max(...rows.map((row) => row.length));
    if (columnCount === 0) return '';
    const normalizedRows = rows.map((row) => {
      const next = row.slice();
      while (next.length < columnCount) next.push('');
      return next;
    });
    const header = normalizedRows[0];
    const lines = [
      `| ${header.join(' | ')} |`,
      `| ${Array.from({ length: columnCount }).map(() => '---').join(' | ')} |`
    ];
    for (const row of normalizedRows.slice(1, 8)) {
      lines.push(`| ${row.join(' | ')} |`);
    }
    return lines.join('\n');
  }

  function nodeMarkdown(node, depth) {
    if (!node) return '';
    if (node.nodeType === Node.TEXT_NODE) {
      return cleanInline(node.textContent || '');
    }
    if (node.nodeType !== Node.ELEMENT_NODE) return '';

    const tag = node.tagName;
    if (tag === 'BR') return '\n';
    if (tag === 'IMG') {
      return cleanInline(node.getAttribute('alt') || '');
    }
    if (/^H[1-6]$/.test(tag)) {
      const level = Math.max(1, Math.min(6, Number(tag.substring(1))));
      const text = inlineMarkdown(node, depth);
      if (!text) return '';
      return `${'#'.repeat(level)} ${text}`;
    }
    if (tag === 'P') {
      return inlineMarkdown(node, depth);
    }
    if (tag === 'PRE') {
      const text = cleanBlock(node.innerText || node.textContent || '');
      if (!text) return '';
      return `\`\`\`\n${text}\n\`\`\``;
    }
    if (tag === 'CODE') {
      const text = cleanInline(node.innerText || node.textContent || '');
      if (!text) return '';
      if (node.parentElement && node.parentElement.tagName === 'PRE') return text;
      return `\`${text.replace(/`/g, "'")}\``;
    }
    if (tag === 'BLOCKQUOTE') {
      const text = childMarkdown(node, depth);
      if (!text) return '';
      return text
        .split('\n')
        .map((line) => line.trim() ? `> ${line}` : '>')
        .join('\n');
    }
    if (tag === 'UL' || tag === 'OL') {
      const lines = [];
      const children = Array.from(node.children).filter((child) => child.tagName === 'LI');
      for (let index = 0; index < children.length; index += 1) {
        const child = children[index];
        const text = childMarkdown(child, depth + 1).replace(/\n/g, '\n  ');
        if (!text) continue;
        const marker = tag === 'OL' ? `${index + 1}.` : '-';
        lines.push(`${marker} ${text}`);
      }
      return lines.join('\n');
    }
    if (tag === 'LI') {
      return childMarkdown(node, depth + 1);
    }
    if (tag === 'TABLE') {
      return tableMarkdown(node);
    }
    if (tag === 'A') {
      const text = inlineMarkdown(node, depth);
      if (!text) return '';
      const href = node.getAttribute('href') || '';
      if (!/^https?:\/\//i.test(href)) return text;
      if (text.length > 80) return text;
      return `[${text}](${href})`;
    }
    if (tag === 'HR') return '---';

    const text = blockTags.has(tag)
      ? childMarkdown(node, depth)
      : inlineMarkdown(node, depth);
    return text;
  }

  function lineQuality(line) {
    const text = line.trim();
    if (!text) return true;
    if (text.length < 2) return false;
    const digitCount = (text.match(/\d/g) || []).length;
    const letterCount = (text.match(/[A-Za-z\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF]/g) || []).length;
    const specialCount = (text.match(/[^A-Za-z0-9\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF\s#`>|.[\]()\-:，。、《》！？；]/g) || []).length;
    if (text.length > 20 && digitCount / text.length > 0.6) return false;
    if (text.length > 20 && specialCount / text.length > 0.5) return false;
    if (text.length > 8 && letterCount === 0) return false;
    return true;
  }

  function finalizeMarkdown(markdown) {
    const seenTinyLines = new Map();
    const lines = cleanBlock(markdown)
      .split('\n')
      .map((line) => line.trimEnd())
      .filter((line) => {
        if (!lineQuality(line)) return false;
        const key = line.trim();
        if (key.length > 0 && key.length < 60) {
          const count = seenTinyLines.get(key) || 0;
          seenTinyLines.set(key, count + 1);
          if (count >= 2) return false;
        }
        return true;
      });
    return cleanBlock(lines.join('\n')).slice(0, maxOutputChars).trim();
  }

  try {
    const sourceRoot = selectMainRoot();
    const clone = sourceRoot.cloneNode(true);
    removeNoisyNodes(clone);
    const rawText = textOf(clone);
    const markdown = finalizeMarkdown(childMarkdown(clone, 0));
    if (!markdown) {
      return JSON.stringify({
        href: window.location.href,
        title: document.title || '',
        markdown: '',
        rawTextLength: rawText.length,
        markdownLength: 0,
        error: 'Deep extraction found no readable page content.'
      });
    }
    return JSON.stringify({
      href: window.location.href,
      title: document.title || '',
      markdown,
      rawTextLength: rawText.length,
      markdownLength: markdown.length
    });
  } catch (error) {
    return JSON.stringify({
      href: window.location.href,
      title: document.title || '',
      markdown: '',
      rawTextLength: 0,
      markdownLength: 0,
      error: String(error)
    });
  }
})();
''';
