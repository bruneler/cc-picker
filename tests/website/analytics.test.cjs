const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('website/analytics.js', 'utf8');
const key = 'cc-picker-matomo-consent-v1';
function setup({ choice, expired = false, signal, hostname = 'cc-picker.brue.nu', blocked = false } = {}) {
  let now = Date.now();
  const listeners = {}, calls = [], scripts = [], intervals = [];
  const store = new Map(choice ? [[key, JSON.stringify({ choice, expires: now + (expired ? -1 : 100000) })]] : []);
  function element(dataset = {}) {
    return { dataset, hidden: true, textContent: '', handlers: {},
      addEventListener(name, fn) { this.handlers[name] = fn; }, focus() {}, remove() {} };
  }
  const deny = element({ analyticsChoice: 'denied' }), allow = element({ analyticsChoice: 'granted' });
  const panel = element(), status = element(), settings = element();
  panel.querySelector = () => deny;
  panel.querySelectorAll = () => [deny, allow];
  const tracker = new Proxy({}, { get: (_, method) => (...args) => calls.push([method, ...args]) });
  const win = { addEventListener: (name, fn) => { listeners[name] = fn; }, setInterval: fn => intervals.push(fn) };
  const doc = { documentElement: { lang: 'de' }, visibilityState: 'visible', referrer: 'https://example.org/private?secret=1',
    querySelector: selector => ({ '[data-analytics-panel]': panel, '[data-analytics-status]': status, '[data-analytics-settings]': settings })[selector],
    querySelectorAll: () => [], createElement: () => element(), head: { append: s => scripts.push(s) } };
  vm.runInNewContext(source, { window: win, document: doc,
    navigator: { doNotTrack: signal === 'DNT' ? '1' : null, globalPrivacyControl: signal === 'GPC' },
    location: { hostname, origin: 'https://' + hostname, pathname: '/', hash: '', search: '?secret=1' },
    localStorage: { getItem: k => { if (blocked) throw Error('blocked'); return store.get(k); }, setItem: (k,v) => { if (blocked) throw Error('blocked'); store.set(k,v); } },
    Date: { now: () => now }, URL, MutationObserver: class { observe() {} } });
  return { calls, scripts, panel, status, store, allow: () => allow.handlers.click(), deny: () => deny.handlers.click(),
    load: () => { win.Matomo = { getTracker: (...args) => { calls.push(['getTracker', ...args]); return tracker; } }; scripts[0].handlers.load(); },
    tick: () => intervals.forEach(fn => fn()), expire: () => { now += 181 * 86400000; },
    storage: () => listeners.storage({ key }) };
}
test('no consent and denial never load Matomo', () => { const t = setup(); assert.equal(t.scripts.length,0); assert.equal(t.panel.hidden,false); t.deny(); t.tick(); assert.equal(t.scripts.length,0); });
test('acceptance loads correct site with minimised URLs once', () => { const t=setup(); t.allow(); assert.equal(t.scripts.length,1); t.load(); assert.deepEqual(t.calls.find(c=>c[0]==='getTracker'),['getTracker','https://analytics.brue.nu/matomo.php','4']); assert.deepEqual(t.calls.find(c=>c[0]==='setCustomUrl'),['setCustomUrl','https://cc-picker.brue.nu/']); assert.deepEqual(t.calls.find(c=>c[0]==='setReferrerUrl'),['setReferrerUrl','https://example.org']); assert.ok(t.calls.findIndex(c=>c[0]==='requireConsent') < t.calls.findIndex(c=>c[0]==='trackPageView')); t.allow(); assert.equal(t.calls.filter(c=>c[0]==='trackPageView').length,1); });
test('withdrawal stops pings and deletes cookies', () => { const t=setup(); t.allow(); t.load(); t.tick(); t.deny(); const p=t.calls.filter(c=>c[0]==='ping').length; t.tick(); assert.equal(t.calls.filter(c=>c[0]==='ping').length,p); assert.ok(t.calls.some(c=>c[0]==='deleteCookies')); });
test('withdrawal while script loads prevents tracking', () => { const t=setup(); t.allow(); t.deny(); t.load(); assert.equal(t.calls.length,0); });
for (const signal of ['DNT','GPC']) test(signal+' overrides stored and new consent', () => { const t=setup({choice:'granted',signal}); t.allow(); assert.equal(t.scripts.length,0); });
test('saved denial and expired consent stay off', () => { for (const options of [{choice:'denied'},{choice:'granted',expired:true}]) assert.equal(setup(options).scripts.length,0); });
test('consent expires in an open page', () => { const t=setup({choice:'granted'}); t.load(); t.expire(); t.tick(); assert.ok(t.calls.some(c=>c[0]==='forgetConsentGiven')); assert.ok(!t.calls.some(c=>c[0]==='ping')); });
test('cross-tab withdrawal stops tracking', () => { const t=setup({choice:'granted'}); t.load(); t.store.clear(); t.storage(); t.tick(); assert.ok(!t.calls.some(c=>c[0]==='ping')); });
test('blocked storage defaults off but permits temporary explicit consent', () => { const t=setup({blocked:true}); assert.equal(t.scripts.length,0); t.allow(); t.load(); assert.ok(t.calls.some(c=>c[0]==='trackPageView')); });
test('preview hosts cannot send tracking', () => { const t=setup({hostname:'localhost'}); t.allow(); assert.equal(t.scripts.length,0); });
test('privacy page has no analytics script and notice discloses full IPs', () => { const s=fs.readFileSync('website/privacy.html','utf8'); assert.ok(!/<script/i.test(s)); assert.match(s,/vollständige IP-Adressen/); assert.match(s,/automatic deletion.*disabled/); });
