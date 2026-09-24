const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const script = fs.readFileSync('website/manual.js', 'utf8');

for (const [file, lang] of [['manual.html','de'], ['manual.en.html','en']]) {
  const html = fs.readFileSync('website/' + file, 'utf8');
  const ids = [...html.matchAll(/<section class="page" id="([^"]+)"/g)].map(m => m[1]);
  test(file + ': all chapters work without JavaScript and resources exist', () => {
    assert.equal(ids.length, 6);
    assert.equal(new Set(ids).size, 6);
    assert.ok(!/<section[^>]*\bhidden\b/.test(html));
    assert.ok(!/analytics\.js|matomo|fonts\.googleapis|window\.openai|data-lucide/.test(html));
    for (const match of html.matchAll(/(?:href|src)="([^"]+)"/g)) {
      const url = match[1];
      if (url.startsWith('https:')) continue;
      if (url.startsWith('#')) {
        assert.ok(html.includes('id="' + url.slice(1) + '"'), url);
      } else {
        const local = url.split('#')[0];
        assert.ok(fs.existsSync(path.join('website', local)), url);
      }
    }
  });
  test(file + ': chapter links, history, language links and fallback', () => {
    const pages = ids.map(id => ({id, hidden:false}));
    const links = ids.map((id,i) => ({textContent:`0${i+1} Chapter ${i+1}`, attrs:{}, setAttribute(k,v){this.attrs[k]=v;}, removeAttribute(k){delete this.attrs[k];}}));
    const language = [{href:'https://cc-picker.brue.nu/manual.html'}, {href:'https://cc-picker.brue.nu/manual.en.html'}];
    const title = {}, label = {};
    const next = {hidden:true, querySelector:q => q==='small'?label:title};
    const root = {querySelectorAll:q => ({'.chapters a':links,'.page':pages,'[data-language]':language})[q], querySelector:q => q==='.next'?next:null};
    const location = {hash:'#sessions'};
    const events = {};
    vm.runInNewContext(script, {document:{getElementById:()=>root,documentElement:{lang}},location,URL,window:{addEventListener:(name,fn)=>events[name]=fn}});
    assert.deepEqual(pages.filter(p=>!p.hidden).map(p=>p.id), ['sessions']);
    assert.equal(links[3].attrs['aria-current'],'page');
    assert.equal(next.href,'#organise');
    assert.ok(language.every(l=>l.href.endsWith('#sessions')));
    location.hash='#help'; events.hashchange();
    assert.equal(next.href,'#start');
    assert.equal(label.textContent, lang==='de'?'ZURÜCK ZUM ANFANG':'BACK TO THE START');
    location.hash='#projects'; events.hashchange();
    assert.deepEqual(pages.filter(p=>!p.hidden).map(p=>p.id), ['projects']);
    location.hash='#content'; events.hashchange();
    assert.ok(pages.every(p=>!p.hidden));
    assert.equal(next.hidden,true);
    location.hash=''; events.hashchange();
    assert.deepEqual(pages.filter(p=>!p.hidden).map(p=>p.id), ['start']);
  });
}
