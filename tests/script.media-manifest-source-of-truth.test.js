const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

async function runScriptWithMedia({ manifest, directoryListing = '' }) {
  const scriptPath = path.join(__dirname, '..', 'script.js');
  const scriptSource = fs.readFileSync(scriptPath, 'utf8');

  const fetchCalls = [];
  const imageSrcs = [];
  const gridChildren = [];
  const sectionBody = { appendChild() {} };
  const tbody = { innerHTML: '', appendChild() {} };
  const showsTable = {
    closest: () => sectionBody,
    querySelector: (selector) => (selector === 'tbody' ? tbody : null),
    classList: { remove() {} },
  };
  const mediaGrid = {
    appendChild(child) {
      gridChildren.push(child);
    },
    set innerHTML(value) {
      this._innerHTML = value;
      gridChildren.length = 0;
    },
    get innerHTML() {
      return this._innerHTML || '';
    },
  };

  function createElement(tagName) {
    const element = {
      tagName,
      children: [],
      className: '',
      style: {},
      classList: { remove() {} },
      appendChild(child) {
        this.children.push(child);
      },
      addEventListener() {},
      replaceWith() {},
      set innerHTML(value) {
        this._innerHTML = value;
      },
      get innerHTML() {
        return this._innerHTML || '';
      },
      textContent: '',
    };

    if (tagName === 'img') {
      Object.defineProperty(element, 'src', {
        get() {
          return this._src || '';
        },
        set(value) {
          this._src = value;
          imageSrcs.push(value);
        },
      });
    }

    return element;
  }

  const context = {
    console,
    fetch: (url) => {
      const path = String(url);
      fetchCalls.push(path);

      if (path.startsWith('data/shows.json')) {
        return Promise.resolve({
          ok: true,
          json: async () => [],
        });
      }

      if (path === 'media/manifest.json') {
        return Promise.resolve({
          ok: true,
          json: async () => manifest,
        });
      }

      if (path === 'media/') {
        return Promise.resolve({
          ok: true,
          text: async () => directoryListing,
        });
      }

      throw new Error(`Unexpected fetch: ${path}`);
    },
    document: {
      querySelectorAll: (selector) => {
        if (selector === '.nav-link' || selector === '[data-iframe-include]') return [];
        return [];
      },
      querySelector: (selector) => {
        if (selector === 'table[aria-label="Shows"]') return showsTable;
        if (selector === '[data-media-grid]') return mediaGrid;
        return null;
      },
      createElement,
    },
    window: { scrollTo() {} },
    DOMParser: class {
      parseFromString(html) {
        const hrefs = Array.from(html.matchAll(/href="([^"]+)"/g));
        return {
          querySelectorAll: () =>
            hrefs.map((match) => ({
              getAttribute: (name) => (name === 'href' ? match[1] : null),
            })),
        };
      }
    },
    Date,
    Set,
    Array,
    String,
    Number,
    Boolean,
    Object,
    Promise,
  };

  vm.createContext(context);
  vm.runInContext(scriptSource, context, { filename: 'script.js' });

  await new Promise((resolve) => setImmediate(resolve));
  await new Promise((resolve) => setImmediate(resolve));

  return {
    fetchCalls,
    imageSrcs,
    gridChildren,
    helperTypes: {
      fetchOptionalText: typeof context.fetchOptionalText,
      extractImageHrefs: typeof context.extractImageHrefs,
    },
  };
}

async function main() {
  const emptyManifest = await runScriptWithMedia({
    manifest: { files: [] },
    directoryListing: '<a href="0003.png">0003.png</a>',
  });

  assert(emptyManifest.fetchCalls.includes('media/manifest.json'));
  assert(
    !emptyManifest.fetchCalls.includes('media/'),
    'Empty manifest should not trigger a media/ directory fetch'
  );
  assert.deepStrictEqual(
    emptyManifest.imageSrcs,
    [],
    'Empty manifest should not rediscover images from media/ directory listing'
  );
  assert(
    emptyManifest.gridChildren.some((child) => child.textContent === 'Media coming soon.'),
    'Empty manifest should show the empty-state message'
  );

  const invalidManifest = await runScriptWithMedia({
    manifest: { files: ['notes.txt'] },
    directoryListing: '<a href="0006.png">0006.png</a>',
  });

  assert(invalidManifest.fetchCalls.includes('media/manifest.json'));
  assert(
    !invalidManifest.fetchCalls.includes('media/'),
    'Manifest entries without valid images should not trigger a media/ directory fetch'
  );
  assert.deepStrictEqual(
    invalidManifest.imageSrcs,
    [],
    'Manifest entries without valid images should not rediscover images from media/ directory listing'
  );
  assert(
    invalidManifest.gridChildren.some((child) => child.textContent === 'Media coming soon.'),
    'Manifest entries without valid images should show the empty-state message'
  );

  const populatedManifest = await runScriptWithMedia({
    manifest: { files: ['0004.jpg'] },
    directoryListing: '<a href="0005.jpg">0005.jpg</a>',
  });

  assert.deepStrictEqual(populatedManifest.imageSrcs, ['media/0004.jpg']);
  assert(
    !populatedManifest.fetchCalls.includes('media/'),
    'Populated manifest should not trigger a media/ directory fetch'
  );
  assert.strictEqual(
    populatedManifest.helperTypes.fetchOptionalText,
    'undefined',
    'fetchOptionalText should be removed once media directory discovery is gone'
  );
  assert.strictEqual(
    populatedManifest.helperTypes.extractImageHrefs,
    'undefined',
    'extractImageHrefs should be removed once media directory discovery is gone'
  );

  console.log('media manifest source-of-truth behavior verified');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
