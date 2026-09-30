// Crafty crawling scraper - CAPTURE ONLY.
//
// Paste this whole file into the browser console on ANY page of the target
// game version's Wowhead subsite (e.g. any /mop-classic/ page). It builds the
// URL manifest for that version, loads each page, and downloads:
//
//   recipes_raw_<ver>.json    { skillLine: [raw listview rows...] }
//   converts_raw_<ver>.json   { Milling|Prospecting: { rows, qty } }
//   sources_raw_<ver>.json    { recipes: {...}, npcs: {...}, runs: [...] }
//   stock_raw_<ver>.json      { itemID: { npcID: limit, ... }, ... }
//
// The first two download only on the run that captures them; a resumed run
// reports that it reused them rather than handing back an identical copy.
//
// SOURCE PASS: the profession listview carries only a source CODE (6=trainer,
// 7=discovery, ...). The detail behind it - which vendor, which drop, which
// quest - lives on each recipe's own spell page, so the pass walks them one at
// a time into IndexedDB, resuming across sittings and exporting when complete.
// Presence in the store IS the resume ledger. SOURCE_PASS_LIMIT caps a run
// while proving out; 0 means every remaining page. Each sitting stamps its own
// span into `runs`, so elapsed time is in the export rather than a lost console.
//
// SEED_SPELL_PAGES covers what the manifest cannot reach: it is built from
// profession RECIPE lists, so a gathering profession with no recipes never
// appears in it.
//
// ITEM PASS: a vendor's stock LIMIT exists nowhere else - not in DB2, not on
// the recipe's own page, whose vendor entries carry only name, type, id and
// zone. It is on the teaching item's page. That pass runs once the source pass
// completes, since its input is the items those pages name, and resumes on the
// same terms.
//
// HOW PAGES LOAD: fetch() plus bracket-matched extraction of the inline data
// arrays. On the host page - the one you pasted into - selfVerify compares that
// extraction against the page's own live globals and reports any divergence
// before the crawl proceeds.
//
// A failed URL is reported by name. Re-run the crawl, or check whether Wowhead
// moved the page.
//
// NO transforms happen here. Every rule - tier sourcing, gating, zero-collapse,
// cap clamps, conversion fractions, Lua emission - lives in
// design/merge_recipe_data.py, which consumes these three files plus the DB2
// closure and writes the shipped data/*.lua.
//
// Re-run: craftyCrawl()          Start over: craftyCrawlReset()

(function craftyCrawlOuter() {
  // --- known profession sets per game version (skill-line IDs are global) ---
  const VERSIONS = {
    'mop-classic': [129,164,165,171,185,186,197,202,333,755,773],
    'tbc':         [129,164,165,171,185,186,197,202,333,755],       // no Inscription
  };
  const DISPLAY = {
    129:'First Aid',164:'Blacksmithing',165:'Leatherworking',171:'Alchemy',
    185:'Cooking',186:'Mining',197:'Tailoring',202:'Engineering',
    333:'Enchanting',755:'Jewelcrafting',773:'Inscription'
  };
  // Wowhead splits the URL space: primary professions under
  // /spells/professions/, secondary skills (First Aid, Cooking) under
  // /spells/secondary-skills/. A wrong category serves the category INDEX
  // (hundreds of unrelated rows), not a 404 - field-confirmed 2026-07 by
  // First Aid and Cooking both "extracting" the same 966-row index.
  const SLUG = {
    129:['secondary-skills','first-aid'], 164:['professions','blacksmithing'],
    165:['professions','leatherworking'], 171:['professions','alchemy'],
    185:['secondary-skills','cooking'],   186:['professions','mining'],
    197:['professions','tailoring'],      202:['professions','engineering'],
    333:['professions','enchanting'],     755:['professions','jewelcrafting'],
    773:['professions','inscription']
  };
  const PAGE_DELAY_MS = 1200;   // politeness between page loads
  const SOURCE_PASS_LIMIT = 0;   // pages per run; 0 = every remaining page
  // A block outlasts 60s and clears at or before 180s (field-observed: the
  // 60s retry always failed, the next one always succeeded), so the first
  // wait starts where the evidence says a retry can land. Linear from there -
  // doubling overshoots when the block is already nearly over.
  const SEED_SPELL_PAGES    = [2366];   // Herb Gathering - see the source pass
  const RATE_LIMIT_BASE_MS  = 120000;  // first pause after a 403
  const RATE_LIMIT_STEP_MS  = 60000;   // added per consecutive block
  const RATE_LIMIT_MAX_MS   = 300000;  // ceiling per wait
  const RATE_LIMIT_TRIES    = 6;       // attempts before giving the page up

  const seg = location.pathname.split('/').filter(Boolean);
  const ver = seg[0] || 'unknown';
  const known = VERSIONS[ver];
  if (!known) {
    console.error('Crafty crawl: unrecognized game version "' + ver + '". ' +
                  'Paste this on a page under /mop-classic/ or /tbc/.');
    return;
  }
  const base = location.origin + '/' + ver;
  const RECIPES_STORE  = 'craftyRecipes_' + ver;       // profession pass output
  const CONVERTS_STORE = 'craftyConverts_' + ver;      // quantity pass output

  // --- the manifest: profession listings + conversion spell pages ---
  const manifest = known.map(s => ({
    kind: 'profession', skill: s,
    url: base + '/spells/' + SLUG[s][0] + '/' + SLUG[s][1],
  }));
  if (known.includes(773)) {
    manifest.push({ kind: 'convert', verb: 'Milling',
                    url: base + '/spell=51005/milling', lvKey: 'milled-from' });
  }
  if (known.includes(755)) {
    manifest.push({ kind: 'convert', verb: 'Prospecting',
                    url: base + '/spell=31252/prospecting', lvKey: 'prospected-from' });
  }

  const dl = (name, text, mime) => {
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([text], {type: mime || 'text/plain'}));
    a.download = name; a.click();
  };
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const hms = ms => {
    const t = Math.round(ms / 1000);
    return Math.floor(t / 3600) + 'h ' + String(Math.floor(t / 60) % 60).padStart(2, '0') +
           'm ' + String(t % 60).padStart(2, '0') + 's';
  };

  // ------------------------------------------------------------------
  // Durable capture store (IndexedDB)
  // ------------------------------------------------------------------
  // The source pass captures thousands of pages over a multi-sitting crawl.
  // A browser file download (a.click) cannot be confirmed to land on disk -
  // the browser can silently drop it under its repeated-download throttle -
  // so downloading each chunk as it is captured stranded pages that the run
  // then marked done. IndexedDB writes ARE confirmable (the transaction fires
  // oncomplete / onerror) and hold far more than localStorage, so the capture
  // lives here, one record per recipe id, and is exported ONCE at the end.
  // Presence of an id in the store IS the resume ledger: no separate bookkeeping
  // can disagree with what was actually written. Even if the final export
  // download drops, the data is safe here and re-exportable without re-crawling.
  const DB_NAME = 'craftyCrawl_' + ver;
  const openDB = () => new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, 1);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains('pages')) db.createObjectStore('pages');
      if (!db.objectStoreNames.contains('meta'))  db.createObjectStore('meta');
      // Teaching-item pages, keyed by itemID. Its own store so the two passes
      // resume independently - presence is the resume ledger for both.
      // A database made before this store existed will not have it: run
      // craftyCrawlReset() and crawl again.
      if (!db.objectStoreNames.contains('items')) db.createObjectStore('items');
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
  // Write one record and RESOLVE ONLY on transaction completion - a rejected
  // or errored write is surfaced, never silently lost.
  const idbPut = (db, store, key, val) => new Promise((resolve, reject) => {
    const tx = db.transaction(store, 'readwrite');
    tx.objectStore(store).put(val, key);
    tx.oncomplete = () => resolve(true);
    tx.onerror = () => reject(tx.error);
    tx.onabort = () => reject(tx.error);
  });
  const idbGet = (db, store, key) => new Promise((resolve, reject) => {
    const tx = db.transaction(store, 'readonly');
    const r = tx.objectStore(store).get(key);
    r.onsuccess = () => resolve(r.result);
    r.onerror = () => reject(r.error);
  });
  const idbKeys = (db, store) => new Promise((resolve, reject) => {
    const tx = db.transaction(store, 'readonly');
    const r = tx.objectStore(store).getAllKeys();
    r.onsuccess = () => resolve(r.result);
    r.onerror = () => reject(r.error);
  });
  const idbAll = (db, store) => new Promise((resolve, reject) => {
    const tx = db.transaction(store, 'readonly');
    const keysReq = tx.objectStore(store).getAllKeys();
    const valsReq = tx.objectStore(store).getAll();
    tx.oncomplete = () => {
      const out = {};
      keysReq.result.forEach((k, i) => { out[k] = valsReq.result[i]; });
      resolve(out);
    };
    tx.onerror = () => reject(tx.error);
  });

  // ------------------------------------------------------------------
  // Page loading
  // ------------------------------------------------------------------

  // Wowhead rate-limits: sustained fetching earns a 403 for a while. A 403
  // is NOT a lost page - it is the site asking for a pause - so the fetch
  // waits and retries the same URL rather than dropping it. Backoff doubles
  // per consecutive block and resets on the first success, so a run that
  // trips the limit slows itself down instead of burning through the
  // remaining pages against a wall.
  let backoffMs = RATE_LIMIT_BASE_MS;
  let blockedCount = 0;

  async function fetchPage(url) {
    for (let attempt = 0; attempt < RATE_LIMIT_TRIES; attempt++) {
      const res = await fetch(url, { credentials: 'same-origin' });
      if (res.status === 403 || res.status === 429) {
        blockedCount++;
        console.warn('Crafty crawl: rate-limited (' + res.status + ') on ' + url +
                     ' - waiting ' + Math.round(backoffMs / 1000) + 's');
        await sleep(backoffMs);
        backoffMs = Math.min(backoffMs + RATE_LIMIT_STEP_MS, RATE_LIMIT_MAX_MS);
        continue;
      }
      if (!res.ok) return null;
      backoffMs = RATE_LIMIT_BASE_MS;   // recovered
      return await res.text();
    }
    return null;   // still blocked after every retry
  }

  // fetch fallback: pull the raw HTML and cut the data array out of the
  // inline script source. anchor = a regex locating the assignment/config
  // whose next '[' opens the row array; the bracket must sit CLOSE to the
  // anchor (an unbounded search walked into unrelated arrays). The rows are
  // JS object literals (unquoted keys), so they are evaluated, not
  // JSON-parsed - the same trust as pasting this script.
  function extractArrayFromHTML(html, anchor) {
    const m = html.search(anchor);
    if (m < 0) return null;
    const start = html.indexOf('[', m);
    if (start < 0 || start - m > 200) return null;
    let depth = 0, inStr = null;
    for (let i = start; i < html.length; i++) {
      const ch = html[i];
      if (inStr) {
        if (ch === '\\') i++;
        else if (ch === inStr) inStr = null;
      } else if (ch === '"' || ch === "'") {
        inStr = ch;
      } else if (ch === '[' || ch === '{') {
        depth++;
      } else if (ch === ']' || ch === '}') {
        depth--;
        if (depth === 0) {
          try {
            return new Function('return ' + html.slice(start, i + 1))();
          } catch (e) { return null; }
        }
      }
    }
    return null;
  }

  // Get a page's rows: { recipes: [...] } for profession pages,
  // { convert: [...] } for spell pages. mode reports how.
  async function harvest(entry) {
    let html = null;
    try {
      html = await fetchPage(entry.url);
      let rows = null;
      if (html && entry.kind === 'profession') {
        rows = extractArrayFromHTML(html, /listviewspells\s*=/);
      } else if (html) {
        // The convert table lives in a new Listview({ ... }) config whose id
        // matches lvKey. Balance the whole config object around the id (no
        // assumptions about field order or distance), then take its data
        // array from inside.
        const idAt = html.search(new RegExp("['\"]?id['\"]?\\s*:\\s*['\"]" + entry.lvKey + "['\"]"));
        if (idAt >= 0) {
          const open = html.lastIndexOf('Listview(', idAt);
          if (open >= 0) {
            const block = balancedBlock(html, html.indexOf('{', open));
            if (block) rows = extractArrayFromHTML(block, /data\s*:/);
          }
        }
      }
      if (validRows(entry, rows)) return { rows, mode: 'fetch' };
      if (rows) console.warn('Crafty crawl: ' + entry.url + ' extracted rows FAILED validation (wrong array).');
    } catch (e) { /* reported below */ }
    // A failed or invalid extraction saves the page's first Listview
    // neighborhood so the real structure is inspectable from one run.
    if (html) {
      const at = Math.max(0, html.indexOf('Listview('));
      dl('crawl_debug_' + (entry.skill || entry.verb) + '.txt', html.slice(at, at + 4000));
    }
    return { rows: null, mode: 'failed' };
  }

  // The balanced {...} starting at `start` (respecting strings), or null.
  function balancedBlock(html, start) {
    if (start < 0) return null;
    let depth = 0, inStr = null;
    for (let i = start; i < html.length; i++) {
      const ch = html[i];
      if (inStr) {
        if (ch === '\\') i++;
        else if (ch === inStr) inStr = null;
      } else if (ch === '"' || ch === "'") inStr = ch;
      else if (ch === '{') depth++;
      else if (ch === '}') { depth--; if (depth === 0) return html.slice(start, i + 1); }
    }
    return null;
  }

  // Shape validation: the extraction must have found the RIGHT array, not
  // just AN array. Profession rows carry learnedat; convert rows carry
  // yield + percent. A category-index page fails this instead of polluting.
  function validRows(entry, rows) {
    if (!Array.isArray(rows) || !rows.length) return false;
    const sample = rows.slice(0, 25);
    if (entry.kind === 'profession') {
      return sample.some(r => r && typeof r.id === 'number' && ('learnedat' in r));
    }
    return sample.every(r => r && typeof r.id === 'number'
      && typeof r.yield === 'number'
      && (typeof r.percent === 'number'
          || (typeof r.count === 'number' && typeof r.outof === 'number')));
  }

  // ------------------------------------------------------------------
  // Self-verification: fetch-vs-live equivalence, proven per run
  // ------------------------------------------------------------------

  // The fetch path reads the page's raw source literal; paste-mode read the
  // live object AFTER Wowhead's scripts ran. Whether those differ in any
  // field OUR TRANSFORMS CONSUME is a property of Wowhead's code - so it is
  // proven, not assumed: when this script is pasted on a page that itself
  // has live data, the same URL is fetched and compared field-by-field
  // (consumed fields only; live-only extras are irrelevant by construction)
  // before any crawling. IDENTICAL clears the fetch path for this run;
  // divergence names the exact row and field, and the crawl REFUSES to run
  // on a divergent extractor.
  const RECIPE_FIELDS = ['id','name','learnedat','reagents','creates','colors',
                         'source','nskillup','reqclass','reqrace',
                         'specialization','scaling','skill'];
  // percent is NOT compared: it is a runtime-DERIVED field (Wowhead's
  // Listview computes it from count/outof at construction; the raw source
  // literal has no percent - field-confirmed 2026-07 by the verify diff).
  // We consume its inputs and derive it ourselves.
  const CONVERT_FIELDS = ['id','name','reqskill','yield','count','outof'];

  function fieldEq(a, b) { return JSON.stringify(a === undefined ? null : a)
                              === JSON.stringify(b === undefined ? null : b); }

  function compareRows(liveRows, fetchedRows, fields, label) {
    // Row identity: recipes are unique by id; convert rows are one per
    // (source, result) pair - keying those by id alone collapsed multi-yield
    // herbs to their last row and manufactured phantom diffs.
    const keyOf = r => ('yield' in r) ? (r.id + ':' + r.yield) : r.id;
    const byId = rows => { const m = new Map(); for (const r of rows) m.set(keyOf(r), r); return m; };
    const L = byId(liveRows), F = byId(fetchedRows);
    const diffs = [];
    for (const [id, lr] of L) {
      const fr = F.get(id);
      if (!fr) { diffs.push('row ' + id + ' missing from fetch'); continue; }
      for (const f of fields) {
        if (!fieldEq(lr[f], fr[f])) {
          diffs.push('row ' + id + ' field "' + f + '": live=' +
                     JSON.stringify(lr[f]) + ' fetch=' + JSON.stringify(fr[f]));
        }
      }
    }
    for (const id of F.keys()) if (!L.has(id)) diffs.push('row ' + id + ' extra in fetch');
    if (!diffs.length) {
      console.log('Crafty crawl VERIFY [' + label + ']: IDENTICAL - ' + L.size +
                  ' rows, every consumed field equal between live page and fetch extraction.');
      return true;
    }
    console.error('Crafty crawl VERIFY [' + label + ']: DIVERGENT (' + diffs.length + '):');
    for (const d of diffs.slice(0, 20)) console.error('  ' + d);
    dl('crawl_verify_diffs.txt', diffs.join('\n'));
    return false;
  }

  // Verify against whatever live data THIS page has. No live data on the
  // host page -> nothing to verify against; the run proceeds with the
  // caveat printed.
  async function selfVerify() {
    let entry = null, liveRows = null, fields = null, label = null;
    if (typeof listviewspells !== 'undefined' && listviewspells && listviewspells.length) {
      liveRows = listviewspells; fields = RECIPE_FIELDS; label = 'recipes@' + location.pathname;
      entry = { kind: 'profession', url: location.href };
    } else if (typeof g_listviews !== 'undefined' && g_listviews) {
      const key = g_listviews['milled-from'] ? 'milled-from'
                : (g_listviews['prospected-from'] ? 'prospected-from' : null);
      if (key) {
        const lv = g_listviews[key];
        liveRows = lv.data || lv; fields = CONVERT_FIELDS; label = key + '@' + location.pathname;
        entry = { kind: 'convert', url: location.href, lvKey: key };
      }
    }
    if (!entry) {
      console.warn('Crafty crawl: host page has no live listview - fetch-vs-live ' +
                   'equivalence NOT verified this run. Paste on a profession or ' +
                   'Milling/Prospecting page to get the proof.');
      return true;
    }
    const html = await fetchPage(entry.url);
    let fetched = null;
    if (entry.kind === 'profession') {
      fetched = extractArrayFromHTML(html, /listviewspells\s*=/);
    } else {
      const idAt = html.search(new RegExp("['\"]?id['\"]?\\s*:\\s*['\"]" + entry.lvKey + "['\"]"));
      if (idAt >= 0) {
        const open = html.lastIndexOf('Listview(', idAt);
        if (open >= 0) {
          const block = balancedBlock(html, html.indexOf('{', open));
          if (block) fetched = extractArrayFromHTML(block, /data\s*:/);
        }
      }
    }
    if (!fetched) {
      console.error('Crafty crawl VERIFY: could not extract this very page by fetch - ' +
                    'the extractor is broken for it; refusing to crawl on guesses.');
      return false;
    }
    return compareRows(liveRows, fetched, fields, label);
  }

  // ------------------------------------------------------------------
  // The crawl
  // ------------------------------------------------------------------

  (async function crawl() {
    // A resumable crawl has no single elapsed time - the store is filled across
    // however many sittings it takes. Each run stamps its own span into meta,
    // so the export carries the real total rather than the last run's fraction.
    const runStarted = Date.now();
    const proven = await selfVerify();
    if (!proven) {
      console.error('Crafty crawl: aborted - the fetch extraction diverges from ' +
                    'live data on this very page. Diffs saved; nothing was emitted.');
      return;
    }
    // Every pass persists, not just the source pass: a sitting that re-ran
    // the profession and quantity passes would spend its rate-limit budget
    // re-fetching pages it already has, making a 403 likelier in the source
    // pass - the only one that still needs pages. craftyCrawlReset() clears
    // all three.
    let storedRecipes = null, storedConverts = null;
    try { storedRecipes = JSON.parse(localStorage.getItem(RECIPES_STORE) || 'null'); } catch (e) {}
    try { storedConverts = JSON.parse(localStorage.getItem(CONVERTS_STORE) || 'null'); } catch (e) {}
    const haveRecipes = storedRecipes && Object.keys(storedRecipes).length === known.length;

    if (haveRecipes) {
      console.log('Crafty crawl [' + ver + ']: profession pages already captured (' +
                  Object.keys(storedRecipes).length + ' professions) - skipping.');
    }
    console.log('Crafty crawl [' + ver + ']: ' + manifest.length + ' pages queued.');
    const convertRows = {};     // verb -> spell-page rows (chances)
    const rawRecipeRows = {};   // skillLine -> untransformed rows; the capture
    const report = [];
    const fingerprints = {};   // rows.length + first id: two pages sharing one
                               // means one URL served another's (or an index) page

    for (const entry of manifest) {
      const label = entry.kind === 'profession' ? DISPLAY[entry.skill] : entry.verb;
      if (entry.kind === 'profession' && haveRecipes) continue;
      if (entry.kind !== 'profession' && storedConverts) continue;
      const { rows, mode } = await harvest(entry);
      if (!rows) {
        report.push('  FAILED  ' + label + '  (' + entry.url + ') - re-run, or check the URL');
        console.warn('Crafty crawl: FAILED ' + label);
      } else if (entry.kind === 'profession') {
        const fp = rows.length + ':' + (rows[0] && rows[0].id);
        if (fingerprints[fp]) {
          console.warn('Crafty crawl: ' + label + ' returned the SAME rows as ' +
                       fingerprints[fp] + ' - check its URL. Skipping.');
          report.push('  DUPLICATE  ' + label + ' (same rows as ' + fingerprints[fp] + ') - skipped');
          await sleep(PAGE_DELAY_MS);
          continue;
        }
        fingerprints[fp] = label;
        rawRecipeRows[entry.skill] = rows;
        report.push('  ok [' + mode + ']  ' + label + '  ' + rows.length + ' rows');
        console.log('Crafty crawl: ' + label + ' [' + mode + '] ' + rows.length + ' rows');
      } else {
        convertRows[entry.verb] = rows;
        report.push('  ok [' + mode + ']  ' + label + '  ' + rows.length + ' rows collected');
        console.log('Crafty crawl: ' + label + ' [' + mode + '] ' + rows.length + ' rows');
      }
      await sleep(PAGE_DELAY_MS);
    }

    if (haveRecipes) {
      Object.assign(rawRecipeRows, storedRecipes);
      report.push('  profession pages: reused ' + Object.keys(storedRecipes).length +
                  ' from a previous run (no fetches)');
    } else if (Object.keys(rawRecipeRows).length) {
      try { localStorage.setItem(RECIPES_STORE, JSON.stringify(rawRecipeRows)); } catch (e) {}
    }

    // ---- Quantity pass: per-proc stack ranges live on each SOURCE ITEM's
    // page (the spell page aggregates chances only). One fetch per source
    // item; a page whose rows carry no stack data is reported and its
    // results are captured without qty (the merge treats absent qty as 1,
    // conservative).
    let convertsRaw = {};   // verb -> { rows, qty: {sourceID: {resultID: [min,max]}} }
    if (storedConverts) {
      convertsRaw = storedConverts;
      report.push('  quantity pass: reused from a previous run (no fetches)');
      console.log('Crafty crawl: conversion quantities already captured - skipping.');
    }
    for (const verb of Object.keys(convertRows)) {
      const lvKey = verb === 'Prospecting' ? 'prospecting' : 'milling';
      const ids = [...new Set(convertRows[verb].map(r => r.id))];
      const q = {};
      let got = 0;
      console.log('Crafty crawl: quantity pass (' + verb + '): ' + ids.length + ' source pages...');
      for (const id of ids) {
        try {
          const html = await fetchPage(base + '/item=' + id);
          if (!html) { console.warn('Crafty crawl: gave up on item=' + id); continue; }
          let rows = null;
          const idAt = html.search(new RegExp("['\"]?id['\"]?\\s*:\\s*['\"]" + lvKey + "['\"]"));
          if (idAt >= 0) {
            const open = html.lastIndexOf('Listview(', idAt);
            if (open >= 0) {
              const block = balancedBlock(html, html.indexOf('{', open));
              if (block) rows = extractArrayFromHTML(block, /data\s*:/);
            }
          }
          if (rows && rows.length && rows.some(r => Array.isArray(r.stack))) {
            const m = {};
            for (const r of rows) if (Array.isArray(r.stack)) m[r.id] = [r.stack[0], r.stack[1]];
            q[id] = m;
            got++;
          } else {
            console.warn('Crafty crawl: no stack data on item=' + id + ' (' + verb + ')');
          }
        } catch (e) {
          console.warn('Crafty crawl: quantity fetch failed for item=' + id);
        }
        await sleep(PAGE_DELAY_MS);
      }
      report.push('  quantity pass (' + verb + '): ' + got + '/' + ids.length + ' source pages');
      convertsRaw[verb] = { rows: convertRows[verb], qty: q };
    }

    // ---- Source pass: per-recipe acquisition detail from each spell page.
    // The profession listview carries only a source CODE; the detail behind
    // it lives on the recipe's own page, in listviews whose ids and shapes
    // were read from the live markup:
    //
    //   taught-by-npc   trainers  {id, name, location[zoneIDs], minlevel,
    //                              maxlevel, tag}
    //   taught-by-item  the teaching item {id, name, skill}, carrying EITHER
    //                   sourcemore[{n, t, ti, z, dd?}] naming a specific
    //                   vendor/creature, OR commondrop:true when it drops too
    //                   widely to enumerate
    //   reward-from-q   quests {id, name, reqlevel, side, xp}
    //   recipes         the spell itself - colors, reagents, trainingcost
    //
    // Any other listview id encountered is recorded verbatim rather than
    // guessed at: an unknown shape is a finding, not something to handle
    // speculatively.
    //
    // The capture lives in IndexedDB (see openDB above), which holds the full
    // dataset and confirms every write - so unlike the old per-chunk downloads,
    // no page can be silently dropped and later mis-reported as captured.
    //
    // Every Listview on the page is stored verbatim under its id. Deciding
    // which ids are acquisition, gate, or discovery data is the merge's job,
    // against data already on disk - so a new need never forces a re-crawl.
    // The one transform is NPC dedup below, and only because it is lossless:
    // the NPC table plus each recipe's id list reconstructs the raw rows.
    const seenViews = {};    // listview id -> how many pages carried it
    // An NPC is an entity, not a property of a recipe: the same 39 First Aid
    // trainers appear on every First Aid recipe, and inlining them is 95% of
    // the capture's bulk (measured: 152 KB -> 16 KB for 25 recipes once
    // normalized). Trainers are stored ONCE here and referenced by id.
    let sourceNPCs = {};
    {
      // One page per RECIPE. A recipe can appear under several professions -
      // Release Spirit is listed by all nine - and the store is keyed by id, so
      // counting an id once per profession would leave completion permanently
      // short by the number of repeats.
      const ids = [];
      const seenIds = new Set();
      for (const sl of Object.keys(rawRecipeRows)) {
        for (const r of rawRecipeRows[sl]) {
          if (r.id && !seenIds.has(String(r.id))) { seenIds.add(String(r.id)); ids.push(r.id); }
        }
      }
      // Pages the recipe manifest cannot reach. The manifest is built from
      // profession RECIPE lists, so a gathering profession with no recipes is
      // never in it - Herb Gathering carries gathered-from-object, the node
      // list with a required skill per object, and nothing would ever fetch it.
      // Mining needs no seed: its page arrives because smelting recipes sit on
      // the Mining skill line.
      for (const id of SEED_SPELL_PAGES) {
        if (!seenIds.has(String(id))) { seenIds.add(String(id)); ids.push(id); }
      }
      // The capture lives in IndexedDB, one record per recipe id under the
      // 'pages' store, plus the shared NPC table under meta/'npcs'. An id
      // present in 'pages' is captured - presence IS the resume ledger, so
      // nothing can claim an id the store does not actually hold. On the final
      // sitting the whole store is read back and exported ONCE.
      const db = await openDB();
      const doneKeys = new Set((await idbKeys(db, 'pages')).map(String));
      sourceNPCs = (await idbGet(db, 'meta', 'npcs')) || {};

      const remaining = ids.filter(id => !doneKeys.has(String(id)));
      const todo = SOURCE_PASS_LIMIT > 0 ? remaining.slice(0, SOURCE_PASS_LIMIT) : remaining;
      console.log('Crafty crawl: source pass: ' + todo.length + ' this run; ' +
                  doneKeys.size + ' already in store, ' +
                  (remaining.length - todo.length) + ' still to go' +
                  (SOURCE_PASS_LIMIT > 0 ? ' (SOURCE_PASS_LIMIT = ' + SOURCE_PASS_LIMIT + ')' : ''));
      let got = 0;
      for (const id of todo) {
        try {
          const html = await fetchPage(base + '/spell=' + id);
          // Blocked past every retry: leave it UNRECORDED so the next run
          // picks it up again, rather than marking it done with no data.
          if (!html) { console.warn('Crafty crawl: gave up on spell=' + id); continue; }
          const found = {};
          // Walk every Listview on the page: the set present varies by how
          // the recipe is obtained, and which ones appear IS the answer.
          const re = /new\s+Listview\s*\(\s*\{/g;
          let mm;
          while ((mm = re.exec(html)) !== null) {
            const block = balancedBlock(html, html.indexOf('{', mm.index));
            if (!block) continue;
            const idm = block.match(/id\s*:\s*'([^']+)'/);
            if (!idm) continue;
            const key = idm[1];
            const rows = extractArrayFromHTML(block, /data\s*:/);
            if (!rows || !rows.length) continue;
            if (key === 'taught-by-npc') {
              // Lossless dedup: the NPC row goes to the table once, the recipe
              // keeps only its id. Every field the page gave is preserved on
              // the table, so the raw rows are fully reconstructable.
              const ids = [];
              for (const t of rows) {
                if (!t || !t.id) continue;
                if (!sourceNPCs[t.id]) {
                  sourceNPCs[t.id] = { name: t.name, tag: t.tag,
                                       zones: t.location || [] };
                }
                ids.push(t.id);
              }
              found[key] = ids;
            } else {
              // Everything else is stored exactly as extracted - no field
              // selection, so unseen fields on any listview come through whole.
              found[key] = rows;
            }
            seenViews[key] = (seenViews[key] || 0) + 1;
          }
          // Recorded even when empty: a page with no listviews is a fact
          // (nothing sources this recipe). The write is AWAITED, so an id only
          // counts as captured once IndexedDB confirms the transaction - a
          // failed write throws and the id is left for the next run rather than
          // silently marked done. The NPC table is saved alongside so a mid-run
          // stop keeps the trainers seen so far.
          await idbPut(db, 'pages', String(id), found);
          await idbPut(db, 'meta', 'npcs', sourceNPCs);
          got++;
        } catch (e) {
          console.warn('Crafty crawl: source capture failed for spell=' + id +
                       ' - ' + (e && e.message ? e.message : e));
        }
        await sleep(PAGE_DELAY_MS);
      }
      // Only a sitting that actually fetched pages is a sitting: a run that
      // found the store already full did no crawling, and recording it would
      // bury the real spans under one-second entries.
      let runs = (await idbGet(db, 'meta', 'runs')) || [];
      if (todo.length) {
        runs.push({ started: new Date(runStarted).toISOString(),
                    finished: new Date().toISOString(),
                    seconds: Math.round((Date.now() - runStarted) / 1000),
                    attempted: todo.length, captured: got, blocked: blockedCount });
        await idbPut(db, 'meta', 'runs', runs);
        const totalSeconds = runs.reduce((t, r) => t + r.seconds, 0);
        report.push('  this run: ' + hms(Date.now() - runStarted) +
                    ' for ' + got + '/' + todo.length + ' pages' +
                    (blockedCount ? ', ' + blockedCount + ' rate-limit waits' : '') +
                    '  |  ' + runs.length + ' run(s) total: ' + hms(totalSeconds * 1000));
      }

      // Resume-safe completion: the store itself is the source of truth.
      const storedCount = (await idbKeys(db, 'pages')).length;
      const left = ids.length - storedCount;
      report.push('  source pass: ' + got + ' captured this run, ' +
                  storedCount + '/' + ids.length + ' in store' +
                  (left > 0 ? ' - ' + left + ' remaining, RUN AGAIN to continue'
                            : ' - COMPLETE'));
      if (blockedCount) {
        report.push('  source pass: rate-limited ' + blockedCount + ' times ' +
                    '(pages were retried, not lost)');
      }
      report.push('  source pass: listviews captured: ' +
                  Object.keys(seenViews).sort().map(k => k + '(' + seenViews[k] + ')').join(', '));
      // Export when the store is complete. In smoke-test mode
      // (SOURCE_PASS_LIMIT > 0) export whatever is in the store so a short run
      // exercises the full capture -> IndexedDB -> read-back -> download chain.
      // The whole capture is read back from IndexedDB and downloaded as a single
      // file. If this one download drops, the data is still safe in the store:
      // re-running exports again without re-crawling.
      if (left <= 0 || SOURCE_PASS_LIMIT > 0) {
        const pages = await idbAll(db, 'pages');
        const npcs  = (await idbGet(db, 'meta', 'npcs')) || {};
        const testTag = (left > 0 && SOURCE_PASS_LIMIT > 0) ? '_SMOKETEST' : '';
        dl('sources_raw_' + ver + testTag + '.json',
           JSON.stringify({ recipes: pages, npcs: npcs, runs: runs }), 'application/json');
        report.push('  source pass: exported sources_raw_' + ver + testTag +
                    '.json (' + Object.keys(pages).length + ' recipes, ' +
                    Object.keys(npcs).length + ' NPCs)' +
                    (testTag ? ' [SMOKE TEST - partial store, not the real crawl]'
                             : ' - if the download did not appear, re-run to ' +
                               'export again (capture is safe in IndexedDB)'));
      } else {
        report.push('  source pass: ' + Object.keys(sourceNPCs).length +
                    ' NPCs so far; export happens once the store is complete');
      }

      // ------------------------------------------------------------------
      // ITEM PASS - vendor stock limits
      //
      // A limited-stock vendor item is the one vendor fact no source we hold
      // carries: DB2 does not have it, and a recipe spell page's vendor entries
      // carry only name, type, id and zone. It is on the TEACHING ITEM's page,
      // in the sold-by listview, as a per-vendor "stock" column - a count for
      // limited, -1 for unlimited. Wowhead uses the same sentinel the client
      // does, verified against five items at a live merchant window.
      //
      // Runs only once the source pass is complete, because its input is the
      // set of teaching items named by those pages.
      // ------------------------------------------------------------------
      if (left <= 0) {
        const pages = await idbAll(db, 'pages');
        const itemIDs = new Set();
        for (const p of Object.values(pages)) {
          for (const r of (p['taught-by-item'] || [])) {
            if (r && r.id) itemIDs.add(String(r.id));
          }
        }
        const itemDone = new Set((await idbKeys(db, 'items')).map(String));
        const itemTodo = [...itemIDs].filter(id => !itemDone.has(id));

        let itemGot = 0;
        for (const id of itemTodo) {
          try {
            const html = await fetchPage('/' + ver + '/item=' + id);
            if (!html) continue;
            const stock = {};
            // Anchor on the sold-by listview's OWN data:, not on its id - the
            // id is followed by hiddenCols and extraCols, and the extractor
            // takes the next bracket it finds.
            const at = html.search(/id:\s*'sold-by'/);
            const rows = at < 0 ? []
                       : (extractArrayFromHTML(html.slice(at), /data:/) || []);
            // Stock is per item/VENDOR pair, not per item: Red Woolen Bag is 1
            // at eleven vendors and 3 at a twelfth, so a per-item maximum would
            // report that twelfth as exceeding it.
            //
            // Only limited entries are kept. -1 is unlimited and is the norm.
            for (const r of rows) {
              if (r && r.id && typeof r.stock === 'number' && r.stock > 0) {
                stock[r.id] = r.stock;
              }
            }
            // Recorded even when empty - an unlimited item is a captured fact,
            // and without the row it would be re-fetched on every run.
            await idbPut(db, 'items', id, stock);
            itemGot++;
          } catch (e) {
            console.warn('Crafty crawl: item capture failed for item=' + id +
                         ' - ' + (e && e.message ? e.message : e));
          }
          await sleep(PAGE_DELAY_MS);
        }

        const itemStored = (await idbKeys(db, 'items')).length;
        const itemLeft = itemIDs.size - itemStored;
        report.push('  item pass: ' + itemGot + ' captured this run, ' +
                    itemStored + '/' + itemIDs.size + ' in store' +
                    (itemLeft > 0 ? ' - ' + itemLeft + ' remaining, RUN AGAIN'
                                  : ' - COMPLETE'));
        if (itemLeft <= 0) {
          const all = await idbAll(db, 'items');
          const limited = {};
          for (const [id, st] of Object.entries(all)) {
            if (st && Object.keys(st).length) limited[id] = st;
          }
          dl('stock_raw_' + ver + '.json', JSON.stringify(limited),
             'application/json');
          report.push('  item pass: exported stock_raw_' + ver + '.json (' +
                      Object.keys(limited).length + ' items with a limited vendor)');
        }
      }
    }

    // Download what this run CAPTURED, not what it happens to hold. Both are
    // reloaded from localStorage on every sitting, so downloading on presence
    // hands back an identical copy each time the crawl is resumed.
    if (Object.keys(convertsRaw).length && !storedConverts) {
      try { localStorage.setItem(CONVERTS_STORE, JSON.stringify(convertsRaw)); } catch (e) {}
      dl('converts_raw_' + ver + '.json', JSON.stringify(convertsRaw), 'application/json');
      report.push('  captured converts_raw_' + ver + '.json');
    } else if (Object.keys(convertsRaw).length) {
      report.push('  converts_raw_' + ver + '.json: reused from a previous run, not re-downloaded');
    }
    const got = Object.keys(rawRecipeRows).length;
    if (got && !haveRecipes) {
      dl('recipes_raw_' + ver + '.json', JSON.stringify(rawRecipeRows), 'application/json');
      report.push('  captured recipes_raw_' + ver + '.json (' + got + '/' + known.length + ' professions' +
                  (got === known.length ? '' : ' - PARTIAL: failed pages above were skipped') + ')');
    } else if (got) {
      report.push('  recipes_raw_' + ver + '.json: reused from a previous run, not re-downloaded');
    }
    console.log('Crafty crawl [' + ver + '] complete - feed both files to ' +
                'design/merge_recipe_data.py:\n' + report.join('\n'));
  })();

  window.craftyCrawl = craftyCrawlOuter;
  window.craftyCrawlReset = function () {
    // Profession/convert passes still resume from localStorage; the source
    // pass capture now lives in IndexedDB. Clear both. (The old source-pass
    // localStorage keys are removed too, harmlessly, in case an old run left
    // them behind.)
    localStorage.removeItem('craftySourcePass_' + ver);
    localStorage.removeItem('craftyRecipes_' + ver);
    localStorage.removeItem('craftyConverts_' + ver);
    localStorage.removeItem('craftyNPCs_' + ver);
    const req = indexedDB.deleteDatabase('craftyCrawl_' + ver);
    req.onsuccess = () => console.log('Crafty crawl: all captured progress cleared (localStorage + IndexedDB).');
    req.onerror   = () => console.warn('Crafty crawl: cleared localStorage; IndexedDB delete failed - close other Wowhead tabs and retry craftyCrawlReset().');
    req.onblocked = () => console.warn('Crafty crawl: IndexedDB delete BLOCKED - another tab holds it open. Close other Wowhead tabs and retry.');
  };
})();
