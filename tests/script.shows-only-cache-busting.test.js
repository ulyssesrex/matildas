const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

async function main() {
  const scriptPath = path.join(__dirname, '..', 'script.js');
  const scriptSource = fs.readFileSync(scriptPath, 'utf8');

  const fetchCalls = [];
  const imageSrcs = [];
  const sectionBody = { appendChild() {} };
  const tbody = { innerHTML: '', appendChild() {} };
  const showsTable = {
    closest: () => sectionBody,
    querySelector: (selector) => (selector === 'tbody' ? tbody : null),
    classList: { remove() {} },
  };
  const mediaGrid = {
    innerHTML: '',
    appendChild() {},
  };

  function createElement(tagName) {
    const element = {
      tagName,
      className: '',
      children: [],
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
      fetchCalls.push(url);

      if (String(url).startsWith('data/shows.json')) {
        return Promise.resolve({
          ok: true,
          json: async () => [],
        });
      }

      if (url === 'media/manifest.json' || String(url).startsWith('media/manifest.json')) {
        return Promise.resolve({
          ok: true,
          json: async () => ({ files: ['0001.jpg'] }),
        });
      }

      return Promise.resolve({
        ok: true,
        text: async () => '',
      });
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
      parseFromString() {
        return {
          querySelectorAll: () => [],
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

  assert(
    fetchCalls.some((url) => /^data\/shows\.json\?v=/.test(String(url))),
    'Shows data should be fetched with a cache-busting query param'
  );
  assert(fetchCalls.includes('media/manifest.json'), 'Media manifest should be fetched without cache busting');
  assert(
    !fetchCalls.some((url) => /^media\/manifest\.json\?/.test(String(url))),
    'Media manifest should not include a cache-busting query param'
  );
  assert.deepStrictEqual(imageSrcs, ['media/0001.jpg']);

  console.log('shows-only cache-busting behavior verified');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
