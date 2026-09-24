(() => {
  'use strict';
  const root = document.getElementById('cc-manual');
  if (!root) return;
  const links = [...root.querySelectorAll('.chapters a')];
  const pages = [...root.querySelectorAll('.page')];
  const next = root.querySelector('.next');
  const german = document.documentElement.lang === 'de';
  function showChapter() {
    const requested = location.hash.slice(1);
    const index = pages.findIndex(page => page.id === requested);
    // Keep every chapter visible for a skip link or an unknown fragment.
    const current = index >= 0 ? index : requested ? -1 : 0;
    pages.forEach((page, i) => { page.hidden = current >= 0 && i !== current; });
    links.forEach((link, i) => {
      if (i === current) link.setAttribute('aria-current', 'page');
      else link.removeAttribute('aria-current');
    });
    next.hidden = current < 0;
    if (current >= 0) {
      const following = (current + 1) % pages.length;
      next.href = '#' + pages[following].id;
      next.querySelector('[data-next-title]').textContent = links[following].textContent.replace(/^\s*\d+\s*/, '').trim();
      next.querySelector('small').textContent = current === pages.length - 1
        ? (german ? 'ZURÜCK ZUM ANFANG' : 'BACK TO THE START')
        : (german ? 'NÄCHSTES KAPITEL' : 'NEXT CHAPTER');
    }
    root.querySelectorAll('[data-language]').forEach(link => {
      const url = new URL(link.href);
      url.hash = current >= 0 ? pages[current].id : requested;
      link.href = url.href;
    });
  }
  window.addEventListener('hashchange', showChapter);
  showChapter();
})();
