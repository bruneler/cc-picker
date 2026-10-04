(() => {
  'use strict';
  // Einwilligung gilt ausschließlich für diese Website und diesen Browser.
  const key = 'cc-picker-matomo-consent-v2';
  const lifetime = 180 * 24 * 60 * 60 * 1000;
  const panel = document.querySelector('[data-analytics-panel]');
  const status = document.querySelector('[data-analytics-status]');
  const settings = document.querySelector('[data-analytics-settings]');
  if (!panel || !status || !settings) return;
  const sites = { 'cc-picker.brue.nu': '4' };
  const siteId = sites[location.hostname];
  const privacySignal = () => navigator.doNotTrack === '1' || navigator.globalPrivacyControl === true;
  let choice = null;
  let expires = 0;
  let script;
  let tracker;
  let sentPage = false;

  function readChoice() {
    try {
      const value = JSON.parse(localStorage.getItem(key) || 'null');
      if (value && ['granted', 'denied'].includes(value.choice) &&
          Number.isFinite(value.expires) && value.expires > Date.now() && value.expires <= Date.now() + lifetime) {
        choice = value.choice; expires = value.expires; return;
      }
    } catch { /* Ohne Browserspeicher ist eine neue Einwilligung erforderlich. */ }
    choice = null; expires = 0;
  }
  const allowed = () => choice === 'granted' && expires > Date.now() && Boolean(siteId) && !privacySignal();
  function clearAnalyticsCookies() {
    // Remove earlier analytics cookies locally, without loading Matomo.
    const names = (document.cookie || '').split(';').map(value => value.trim().split('=')[0])
      .filter(name => /^_pk_[A-Za-z0-9_.-]+$/.test(name));
    const domains = [''];
    const parts = location.hostname.split('.');
    while (parts.length > 1) { domains.push(parts.join('.')); parts.shift(); }
    for (const name of names) for (const domain of domains) {
      document.cookie = name + '=; Max-Age=0; Path=/; SameSite=Lax; Secure' +
        (domain ? '; Domain=' + domain : '');
    }
  }
  function stop() {
    clearAnalyticsCookies();
    if (!tracker) return;
    tracker.forgetConsentGiven();
    tracker.deleteCookies();
  }
  const copy = {
    de: {
      title: 'Freiwillige Besucherstatistik',
      info: 'Wir möchten verstehen, welche Inhalte dir helfen, und erfassen dafür möglichst wenige Daten. Wenn du zustimmst, werten wir mit unserem eigenen Matomo Seitenaufrufe, Besuchsdauer und wiederkehrende Besuche aus. Länder und Regionen helfen uns, Sprachen, Inhalte und Marketingmaßnahmen zu planen. Deine IP-Adresse wird vor dem Speichern gekürzt; Stadt und genaue Koordinaten speichern wir nicht. Ohne Zustimmung bleibt die Auswertung aus. Du kannst jederzeit über die Datenschutz-Einstellungen widerrufen.',
      allow: 'Erlauben', deny: 'Nicht erlauben', settings: 'Datenschutz-Einstellungen', details: 'Datenschutz im Detail',
      signal: 'Dein Browser signalisiert, dass du keine Messung möchtest. Die Auswertung bleibt aus.',
      on: 'Du hast die freiwillige Auswertung erlaubt.', off: 'Die freiwillige Auswertung ist ausgeschaltet.'
    },
    en: {
      title: 'Optional visitor statistics',
      info: 'We want to understand which content helps you while collecting as little data as possible. With your consent, we use our own Matomo to analyse page views, visit duration and returning visits. Countries and regions help us plan languages, content and marketing activities. Your IP address is shortened before storage; we do not store your city or precise coordinates. Analytics stays off without consent. You can withdraw consent at any time through Privacy settings.',
      allow: 'Allow', deny: 'Do not allow', settings: 'Privacy settings', details: 'Privacy details',
      signal: 'Your browser requests no tracking. Statistics remain off.',
      on: 'You have allowed optional statistics.', off: 'Optional statistics are off.'
    }
  };
  function describe() {
    const t = copy[document.documentElement.lang === 'de' ? 'de' : 'en'];
    document.querySelectorAll('[data-analytics-text]').forEach(el => { el.textContent = t[el.dataset.analyticsText]; });
    status.textContent = privacySignal() ? t.signal : allowed() ? t.on : t.off;
  }
  function activate() {
    if (!allowed()) { stop(); return; }
    if (!tracker) {
      if (!window.Matomo) return;
      tracker = window.Matomo.getTracker('https://analytics.brue.nu/matomo.php', siteId);
      tracker.requireConsent();
      tracker.setDoNotTrack(true);
      tracker.setSecureCookie(true);
      tracker.setVisitorCookieTimeout(180 * 24 * 60 * 60);
      tracker.setReferralCookieTimeout(180 * 24 * 60 * 60);
      tracker.setCustomUrl(location.origin + location.pathname);
      let referrer = '';
      try { referrer = new URL(document.referrer).origin; } catch { /* Kein Referrer. */ }
      tracker.setReferrerUrl(referrer);
    }
    tracker.setConsentGiven();
    if (!sentPage) { tracker.trackPageView(); sentPage = true; }
  }
  function sync() {
    describe();
    if (!allowed()) { stop(); return; }
    if (tracker || window.Matomo) { activate(); return; }
    if (script) return;
    script = document.createElement('script');
    script.src = 'https://analytics.brue.nu/matomo.js';
    script.defer = true;
    script.referrerPolicy = 'no-referrer';
    script.addEventListener('load', activate);
    script.addEventListener('error', () => { script.remove(); script = null; });
    document.head.append(script);
  }
  readChoice();
  panel.hidden = choice !== null || privacySignal();
  settings.hidden = false;
  sync();
  settings.addEventListener('click', () => { panel.hidden = false; describe(); panel.querySelector('button').focus(); });
  panel.querySelectorAll('[data-analytics-choice]').forEach(button => {
    button.addEventListener('click', () => {
      choice = button.dataset.analyticsChoice;
      expires = Date.now() + lifetime;
      try { localStorage.setItem(key, JSON.stringify({ choice, expires })); } catch { /* Auswahl gilt nur für diese Seite. */ }
      panel.hidden = true; sync(); settings.focus();
    });
  });
  window.addEventListener('storage', event => {
    if (event.key !== key && event.key !== null) return;
    readChoice(); sync();
  });
  // Eigene, bewachte Pings: nach Ablauf, DNT/GPC oder Widerruf keine Sendungen.
  window.setInterval(() => {
    if (!allowed()) { stop(); return; }
    if (tracker && document.visibilityState === 'visible') tracker.ping();
  }, 15000);
  new MutationObserver(describe).observe(document.documentElement, { attributes: true, attributeFilter: ['lang'] });
  if (location.hash === '#privacy-settings') { panel.hidden = false; }
})();
