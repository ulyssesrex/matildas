const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const scriptPath = path.join(__dirname, '..', 'script.js');
const scriptSource = fs.readFileSync(scriptPath, 'utf8');

const context = {
  console,
  fetch: () => Promise.reject(new Error('fetch should not run in this test')),
  document: {
    querySelectorAll: () => [],
    querySelector: () => null,
    createElement: () => ({
      appendChild() {},
      addEventListener() {},
      classList: { remove() {} },
      style: {},
      set innerHTML(value) {
        this._innerHTML = value;
      },
      get innerHTML() {
        return this._innerHTML || '';
      },
      textContent: '',
    }),
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

assert.strictEqual(typeof context.appendCacheBust, 'function', 'appendCacheBust should be defined');
assert.strictEqual(
  context.appendCacheBust('data/shows.json', '123'),
  'data/shows.json?v=123'
);
assert.strictEqual(
  context.appendCacheBust('media/?view=grid', '123'),
  'media/?view=grid&v=123'
);

console.log('cache-busting helper tests passed');
