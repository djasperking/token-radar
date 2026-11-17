// Token Radar dashboard. Reads window.RADAR (data.js, written by main.ts from the sealed snapshot) and renders
// the board, a detail view per protocol, the live-token comparison and the method. No network, no framework.
// Every figure on the page comes from data.js; the detail view recomputes implied value from the row's own
// multipliers (impliedOf) and checks it against the number board.json carries.
(function () {
  'use strict';
  var D = window.RADAR;
  var app = document.getElementById('app');
  if (!D) return;
  var ROWS = D.rows;
  var BY = {};
  ROWS.forEach(function (r) { BY[r.slug] = r; });
  var MAXV = ROWS.reduce(function (m, r) { return Math.max(m, r.implied_value_usd); }, 1);
  var TOTAL = ROWS.reduce(function (s, r) { return s + r.implied_value_usd; }, 0);

  var S = { tab: 'radar', q: '', cat: 'all', chain: 'all', tvl: 0, tier: 'all', conf: 'all', sort: 'rank', dir: 1, sel: ROWS[0].slug, view: 'board' };

  // ---- formatting -------------------------------------------------------------------------------------
  function esc(s) { return String(s === null || s === undefined ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
  function usd(n) {
    if (n === null || n === undefined || !isFinite(n)) return 'n/a';
    var a = Math.abs(n);
    if (a >= 1e9) return '$' + (n / 1e9).toFixed(2) + 'B';
    if (a >= 1e6) return '$' + (n / 1e6).toFixed(a >= 1e8 ? 0 : 1) + 'M';
    if (a >= 1e3) return '$' + Math.round(n / 1e3) + 'K';
    return '$' + (a < 10 && a % 1 ? n.toFixed(2) : Math.round(n));
  }
  function pct(n) { return n === null || n === undefined ? 'n/a' : (n > 0 ? '+' : '') + n.toFixed(1) + '%'; }
  function cls(n) { return n === null || n === undefined || Math.abs(n) < 0.05 ? 'flat' : n > 0 ? 'up' : 'down'; }
  function age(d) { return d === null || d === undefined ? 'n/a' : d >= 365 ? (d / 365).toFixed(1) + 'y' : d + 'd'; }
  function ratio(n) { return n.toFixed(n < 0.1 ? 3 : 2) + 'x'; }
  function cat(r) { return r.category || 'Uncategorised'; }

  // The model's own arithmetic, in the same order as lib/model.ts.
  function impliedOf(r) { return Math.max(1, Math.round(r.tvl_usd * r.ratio * r.size_mult * r.growth_mult * r.maturity_mult)); }

  // ---- state in the address bar -----------------------------------------------------------------------
  function readHash() {
    var h = location.hash.replace(/^#/, '');
    if (!h) return;
    h.split('&').forEach(function (kv) {
      var i = kv.indexOf('=');
      if (i < 0) return;
      var k = decodeURIComponent(kv.slice(0, i)), v = decodeURIComponent(kv.slice(i + 1));
      if (k === 'tvl' || k === 'dir') S[k] = Number(v) || 0 || (k === 'dir' ? 1 : 0);
      else if (k in S) S[k] = v;
    });
    if (S.dir !== -1) S.dir = 1;
    if (!BY[S.sel]) S.sel = ROWS[0].slug;
  }
  function writeHash() {
    var p = [];
    ['tab', 'view', 'sel', 'q', 'cat', 'chain', 'tvl', 'tier', 'conf', 'sort', 'dir'].forEach(function (k) { p.push(k + '=' + encodeURIComponent(S[k])); });
    try { history.replaceState(null, '', '#' + p.join('&')); } catch (e) { /* a file page may refuse */ }
  }

  // ---- filtering and sorting --------------------------------------------------------------------------
  var KEYS = {
    rank: function (r) { return r.rank; },
    name: function (r) { return r.name.toLowerCase(); },
    tvl: function (r) { return r.tvl_usd; },
    chg: function (r) { return r.change_7d === null ? -1e9 : r.change_7d; },
    age: function (r) { return r.age_days === null ? -1 : r.age_days; },
    ratio: function (r) { return r.ratio; },
    value: function (r) { return r.implied_value_usd; },
    conf: function (r) { return { high: 3, medium: 2, low: 1 }[r.confidence]; },
    cost: function (r) { return r.gas_usd; }
  };
  function visible() {
    var q = S.q.trim().toLowerCase();
    var out = ROWS.filter(function (r) {
      if (S.cat !== 'all' && cat(r) !== S.cat) return false;
      if (S.chain !== 'all' && r.chains.indexOf(S.chain) < 0) return false;
      if (r.tvl_usd < S.tvl) return false;
      if (S.tier !== 'all' && r.tier !== S.tier) return false;
      if (S.conf !== 'all' && r.confidence !== S.conf) return false;
      if (q && (r.name + ' ' + cat(r) + ' ' + r.chains.join(' ')).toLowerCase().indexOf(q) < 0) return false;
      return true;
    });
    var f = KEYS[S.sort] || KEYS.rank;
    out.sort(function (a, b) { var x = f(a), y = f(b); return (x < y ? -1 : x > y ? 1 : a.rank - b.rank) * S.dir; });
    return out;
  }

  // ---- pieces -----------------------------------------------------------------------------------------
  var LOGO = '<svg viewBox="0 0 32 32" aria-hidden="true"><circle cx="16" cy="16" r="14" fill="none" stroke="#1f5b45" stroke-width="1.5"/><circle cx="16" cy="16" r="9" fill="none" stroke="#1f5b45" stroke-width="1.5"/><circle cx="16" cy="16" r="4" fill="none" stroke="#34d3a4" stroke-width="1.5"/><path d="M16 16 L27 8" stroke="#34d3a4" stroke-width="2" stroke-linecap="round"/><circle cx="24" cy="10" r="2.2" fill="#34d3a4"/></svg>';

  function header(compact) {
    var wl = D.watchlist_covered + ' / ' + D.watchlist_size;
    return '<header class="top"><div class="wrap"><div class="brand">' + LOGO + 'Token Radar</div><div class="meta"><span>Snapshot ' + esc(D.as_of) + '</span><span>DefiLlama protocol index</span><span>Model ' + esc(D.model_version) + '</span></div></div></header>' +
      (compact ? '' : '<section class="hero"><div class="wrap"><div><h1>' + ROWS.length + ' protocols record no token. Here is what a launch could be worth.</h1>' +
      '<p class="lede">Every protocol in the snapshot with no token on record is valued from what the market pays for the ' + D.fit.comps + ' protocols that do have one: market cap per dollar of TVL, by category, adjusted for size, 7-day TVL growth and age. Select a row for the value walk and a costed farm plan. Implied value is this radar\'s claim, not a prediction that a token launches.</p></div>' +
      '<div class="kpis"><div class="kpi ok"><b>' + wl + '</b><span>watchlist protocols covered</span></div><div class="kpi"><b>' + usd(TOTAL) + '</b><span>combined implied value, ' + ROWS.length + ' rows</span></div>' +
      '<div class="kpi"><b>' + D.fit.comps + '</b><span>live-token comps fitted</span></div><div class="kpi"><b>' + D.fit.beta.toFixed(2) + '</b><span>size slope, log ratio per log TVL</span></div></div></div></section>');
  }
  function tabs() {
    var t = [['radar', 'Radar'], ['live', 'Live tokens'], ['method', 'Method']];
    return '<nav class="tabs" role="tablist"><div class="wrap">' + t.map(function (x) { return '<button class="tab" role="tab" data-tab="' + x[0] + '" aria-selected="' + (S.tab === x[0]) + '">' + x[1] + '</button>'; }).join('') + '</div></nav>';
  }
  function opts(list, cur, all) {
    return '<option value="all">' + all + '</option>' + list.map(function (x) { return '<option value="' + esc(x[0]) + '"' + (x[0] === cur ? ' selected' : '') + '>' + esc(x[1]) + '</option>'; }).join('');
  }
  function controls(n) {
    var cats = {}, chains = {};
    ROWS.forEach(function (r) { cats[cat(r)] = (cats[cat(r)] || 0) + 1; r.chains.forEach(function (c) { chains[c] = (chains[c] || 0) + 1; }); });
    var cl = Object.keys(cats).sort(function (a, b) { return cats[b] - cats[a] || (a < b ? -1 : 1); }).map(function (c) { return [c, c + ' (' + cats[c] + ')']; });
    var hl = Object.keys(chains).sort(function (a, b) { return chains[b] - chains[a] || (a < b ? -1 : 1); }).slice(0, 24).map(function (c) { return [c, c + ' (' + chains[c] + ')']; });
    var tv = [[1e7, '$10M+'], [5e7, '$50M+'], [1e8, '$100M+'], [5e8, '$500M+'], [1e9, '$1B+']];
    var seg = [['all', 'All'], ['watchlist', 'Watchlist'], ['early', 'Early']];
    return '<div class="controls">' +
      '<div class="field"><label for="q">Search</label><input id="q" type="search" placeholder="Name, category or chain" value="' + esc(S.q) + '"></div>' +
      '<div class="field"><label for="cat">Category</label><select id="cat">' + opts(cl, S.cat, 'All categories') + '</select></div>' +
      '<div class="field"><label for="chain">Chain</label><select id="chain">' + opts(hl, S.chain, 'All chains') + '</select></div>' +
      '<div class="field"><label for="tvl">Min TVL</label><select id="tvl"><option value="0">Any</option>' + tv.map(function (x) { return '<option value="' + x[0] + '"' + (S.tvl === x[0] ? ' selected' : '') + '>' + x[1] + '</option>'; }).join('') + '</select></div>' +
      '<div class="field"><label for="conf">Confidence</label><select id="conf"><option value="all">Any</option>' + ['high', 'medium', 'low'].map(function (c) { return '<option value="' + c + '"' + (S.conf === c ? ' selected' : '') + '>' + c + '</option>'; }).join('') + '</select></div>' +
      '<div class="field"><label>Tier</label><div class="seg" role="group" aria-label="Tier">' + seg.map(function (x) { return '<button data-tier="' + x[0] + '" aria-pressed="' + (S.tier === x[0]) + '">' + x[1] + '</button>'; }).join('') + '</div></div>' +
      '<button class="btn" id="reset">Reset</button><button class="btn" id="csv">Export CSV</button>' +
      '<div class="count" aria-live="polite">' + n + ' of ' + ROWS.length + ' shown</div></div>';
  }
  function th(k, label, right, hide) {
    var s = S.sort === k ? (S.dir === 1 ? 'ascending' : 'descending') : 'none';
    return '<th scope="col" class="' + (right ? 'r ' : '') + (hide || '') + '" aria-sort="' + s + '"><button data-sort="' + k + '">' + label + '</button></th>';
  }
  function table(list) {
    if (!list.length) return '<div class="tablebox"><div class="empty">No protocol matches these filters. <button class="btn" id="reset2">Reset filters</button></div></div>';
    var body = list.map(function (r) {
      var w = Math.max(3, Math.round(70 * Math.sqrt(r.implied_value_usd / MAXV)));
      return '<tr tabindex="0" data-slug="' + esc(r.slug) + '" aria-selected="' + (r.slug === S.sel) + '">' +
        '<td class="rk num">' + r.rank + '</td>' +
        '<td><div class="pn">' + esc(r.name) + (r.tier === 'watchlist' ? ' <span class="pill wl">watchlist</span>' : '') + '</div><div class="pc">' + esc(cat(r)) + ' · ' + esc(r.chains.slice(0, 3).join(', ') || 'no chain listed') + (r.chains.length > 3 ? ' +' + (r.chains.length - 3) : '') + '</div></td>' +
        '<td class="r num">' + usd(r.tvl_usd) + '</td>' +
        '<td class="r num ' + cls(r.change_7d) + '">' + pct(r.change_7d) + '</td>' +
        '<td class="r num hide-s">' + age(r.age_days) + '</td>' +
        '<td class="r num hide-s">' + ratio(r.ratio) + '</td>' +
        '<td class="r"><div class="bar"><i style="width:' + w * 0.9 + 'px"></i><span class="num">' + usd(r.implied_value_usd) + '</span></div></td>' +
        '<td class="hide-s"><span class="pill ' + r.confidence + '">' + r.confidence + '</span></td></tr>';
    }).join('');
    return '<div class="tablebox"><div class="scroller"><table><thead><tr>' + th('rank', '#') + th('name', 'Protocol') + th('tvl', 'TVL', 1) + th('chg', '7d', 1) + th('age', 'Age', 1, 'hide-s') + th('ratio', 'Peer ratio', 1, 'hide-s') + th('value', 'Implied value', 1) + th('conf', 'Confidence', 0, 'hide-s') + '</tr></thead><tbody>' + body + '</tbody></table></div></div>';
  }
  function walk(r) {
    var v1 = r.tvl_usd * r.ratio, v2 = v1 * r.size_mult, v3 = v2 * r.growth_mult, v4 = v3 * r.maturity_mult;
    var again = impliedOf(r), ok = again === r.implied_value_usd;
    function line(label, sub, x, run) { return '<div><span>' + label + '<small>' + sub + '</small></span><span class="num x">' + x + '</span><span class="num">' + run + '</span></div>'; }
    return '<div class="walk">' +
      line('Total value locked', 'snapshot figure', '', usd(r.tvl_usd)) +
      line('Peer ratio', esc(cat(r)) + ', ' + r.comps_n + ' live comp' + (r.comps_n === 1 ? '' : 's') + ', ' + r.confidence + ' confidence', '× ' + ratio(r.ratio), usd(v1)) +
      line('Size', 'TVL vs the comps\' reference of ' + usd(D.fit.ref_tvl), '× ' + r.size_mult.toFixed(2), usd(v2)) +
      line('Growth', 'TVL ' + pct(r.change_7d) + ' over 7 days', '× ' + r.growth_mult.toFixed(2), usd(v3)) +
      line('Maturity', age(r.age_days) + ' tracked with no token', '× ' + r.maturity_mult.toFixed(2), usd(v4)) +
      line('Implied value', 'rank ' + r.rank + ' of ' + ROWS.length, '', usd(r.implied_value_usd)) +
      '</div><p class="check">Recomputed in this page: <span class="num">' + again.toLocaleString('en-US') + '</span> ' + (ok ? '<b>matches</b>' : '<b style="color:var(--bad)">differs from</b>') + ' board.json.</p>';
  }
  function detail(r, full) {
    var i = ROWS.indexOf(r);
    var comps = r.comps.map(function (c) { return '<tr><td>' + esc(c.name) + '<div class="pc">' + esc(c.category || 'Uncategorised') + '</div></td><td class="r num">' + usd(c.tvl_usd) + '</td><td class="r num">' + usd(c.mcap_usd) + '</td><td class="r num">' + ratio(c.ratio) + '</td></tr>'; }).join('');
    var plan = r.steps.map(function (s) { return '<li><div><p>' + esc(s.text) + '</p><div class="m"><span>cost <em>' + esc(s.cost) + '</em></span><span>time <em>' + esc(s.time) + '</em></span></div></div></li>'; }).join('');
    var sig = [];
    if (r.change_7d !== null && Math.abs(r.change_7d) >= 10) sig.push('<span class="pill ' + (r.change_7d > 0 ? 'high' : 'medium') + '">TVL ' + pct(r.change_7d) + ' in 7 days</span>');
    if (r.age_days !== null) sig.push('<span class="pill">' + age(r.age_days) + ' tracked, no token recorded</span>');
    return '<aside class="detail' + (full ? ' full' : '') + '" id="detail" aria-label="Detail for ' + esc(r.name) + '"><h2>' + esc(r.name) + (full ? '' : ' <button class="btn open" data-view="detail">Full view</button>') + '</h2>' +
      '<div class="badges"><span class="pill ' + (r.tier === 'watchlist' ? 'wl' : '') + '">' + (r.tier === 'watchlist' ? 'On the watchlist (≥ ' + usd(D.floor_usd) + ' TVL)' : 'Early: below the watchlist floor') + '</span><span class="pill">' + esc(cat(r)) + '</span>' + r.chains.slice(0, 4).map(function (c) { return '<span class="pill">' + esc(c) + '</span>'; }).join('') + sig.join('') + '</div>' +
      '<div class="hl"><b>' + usd(r.implied_value_usd) + '</b><span>implied value if its record stays as it is · ' + (100 * r.implied_value_usd / TOTAL).toFixed(1) + '% of the board</span></div>' +
      '<div class="cols"><div><h3>Value walk</h3>' + walk(r) +
      '<h3>Nearest comparables by TVL</h3><table class="mini"><thead><tr><th scope="col">Token</th><th scope="col" class="r">TVL</th><th scope="col" class="r">Mcap</th><th scope="col" class="r">Mcap/TVL</th></tr></thead><tbody>' + comps + '</tbody></table></div><div>' +
      '<h3>Farm plan</h3><div class="tot"><div><b>' + usd(r.capital_usd) + '</b><span>capital, stays yours</span></div><div><b>' + usd(r.gas_usd) + '</b><span>gas, all steps</span></div><div><b>' + r.days + ' days</b><span>minimum hold</span></div></div>' +
      '<ol class="plan">' + plan + '</ol>' +
      '<p class="note">Gas is an estimate per chain (see Method). A plan is a way to be on record before a token exists, not advice and not a promise of a reward. Never share a seed phrase.</p>' +
      '<div class="nav"><button class="btn" data-step="-1"' + (i === 0 ? ' disabled' : '') + '>Previous rank</button><button class="btn" data-step="1"' + (i === ROWS.length - 1 ? ' disabled' : '') + '>Next rank</button></div></div></div></aside>';
  }
  function radar() {
    var list = visible();
    if (list.length && list.indexOf(BY[S.sel]) < 0) S.sel = list[0].slug;
    var sel = BY[S.sel];
    if (S.view === 'detail') return '<section class="wrap"><div class="crumb"><button class="btn" data-view="board">&larr; Back to the board</button><span class="num">rank ' + sel.rank + ' of ' + ROWS.length + ' · j / k or the buttons below move between ranks</span></div>' + detail(sel, true) + '</section>';
    return '<section class="wrap">' + controls(list.length) + '<div class="split">' + table(list) + detail(sel) + '</div></section>';
  }
  function live() {
    var rows = D.live.map(function (r) {
      var w = Math.min(100, Math.round(100 * Math.sqrt(r.ratio / 3)));
      return '<tr><td><div class="pn">' + esc(r.name) + '</div><div class="pc">' + esc(r.category || 'Uncategorised') + '</div></td><td class="r num">' + usd(r.tvl_usd) + '</td><td class="r num">' + usd(r.mcap_usd) + '</td><td class="r"><div class="bar"><i style="width:' + w * 0.8 + 'px"></i><span class="num">' + ratio(r.ratio) + '</span></div></td><td class="r num ' + cls(r.change_7d) + '">' + pct(r.change_7d) + '</td></tr>';
    }).join('');
    return '<section class="wrap page"><h2>Live tokens: the market\'s own values</h2><p>These protocols already record a token, so their value is the market\'s, not a model\'s. They are kept off the ranked board and used as the comparables the model is fitted from: each row\'s market cap per dollar of TVL is one observation. The ' + D.live.length + ' largest by market cap are shown; the fit uses all ' + D.fit.comps + '.</p>' +
      '<div class="card"><table><thead><tr><th scope="col" style="padding:8px 12px">Protocol</th><th scope="col" class="r" style="padding:8px 12px">TVL</th><th scope="col" class="r" style="padding:8px 12px">Market cap</th><th scope="col" class="r" style="padding:8px 12px">Mcap / TVL</th><th scope="col" class="r" style="padding:8px 12px">TVL 7d</th></tr></thead><tbody>' + rows + '</tbody></table></div></section>';
  }
  function method() {
    var c = D.constants;
    var cats = D.fit.categories.filter(function (x) { return x.pre_token > 0 || x.comps > 0; }).sort(function (a, b) { return b.pre_token - a.pre_token || b.comps - a.comps || (a.name < b.name ? -1 : 1); });
    var rows = cats.map(function (x) { return '<tr><td>' + esc(x.name) + '</td><td class="r num">' + x.comps + '</td><td class="r num">' + (x.median_ratio === null ? 'n/a' : ratio(x.median_ratio)) + '</td><td class="r num">' + Math.round(100 * x.weight) + '%</td><td class="r num">' + ratio(x.used_ratio) + '</td><td class="r num">' + x.pre_token + '</td><td><span class="pill ' + x.confidence + '">' + x.confidence + '</span></td></tr>'; }).join('');
    return '<section class="wrap page"><h2>How a row is valued</h2>' +
      '<p>One function scores every protocol. No name is special-cased and nothing is hardcoded about any one protocol: the numbers below are fitted from the snapshot, then applied to each protocol\'s own TVL, 7-day change and listing date.</p>' +
      '<div class="formula"><b>implied</b> = TVL × <b>ratio</b>(category) × <b>size</b> × <b>growth</b> × <b>maturity</b><br>' +
      '<b>ratio</b>(category) = shrunk median of mcap/TVL over live comps, weight n / (n + ' + c.shrink + ') toward the market median ' + ratio(D.fit.market_ratio) + '<br>' +
      '<b>size</b> = clamp((TVL / ' + usd(D.fit.ref_tvl) + ')^' + D.fit.beta.toFixed(3) + ', ' + c.size_min + ', ' + c.size_max + ')   (slope fitted by least squares, clamped to [-0.5, 0])<br>' +
      '<b>growth</b> = 1 + ' + c.growth_weight + ' × clamp(change_7d, ' + c.growth_floor + ', ' + c.growth_cap + ') / 100   (no figure counts as 0)<br>' +
      '<b>maturity</b> = ' + c.maturity_floor + ' + ' + c.maturity_range + ' × min(age_days, ' + c.maturity_days + ') / ' + c.maturity_days + '   (no listing date counts as ' + c.unknown_age_days + ' days)</div>' +
      '<h2>What goes on the board</h2><p>All ' + D.watchlist_size + ' watchlist protocols, plus every other protocol that records no token and is not a wrapped, staked, bridged or exchange product of one that trades (' + D.excluded + ' such products were set aside). That is ' + ROWS.length + ' rows; the watchlist is the floor, and the ' + (ROWS.length - D.watchlist_size) + ' early rows below it are the radar\'s finds. Protocols with a token are on the Live tokens tab, never in the ranking.</p>' +
      '<h2>Category ratios and confidence</h2><p>Confidence is high with 8 or more live comps in the category, medium with 3 to 7, and low below that, where the market median carries most of the weight. Low-confidence rows are the least certain, and the page says so.</p>' +
      '<div class="card"><table><thead><tr><th scope="col" style="padding:8px 12px">Category</th><th scope="col" class="r" style="padding:8px 12px">Live comps</th><th scope="col" class="r" style="padding:8px 12px">Median</th><th scope="col" class="r" style="padding:8px 12px">Weight</th><th scope="col" class="r" style="padding:8px 12px">Ratio used</th><th scope="col" class="r" style="padding:8px 12px">Pre-token</th><th scope="col" style="padding:8px 12px">Confidence</th></tr></thead><tbody>' + rows + '</tbody></table></div>' +
      '<h2>Farm plans and gas</h2><p>Each plan is built from the protocol\'s category, cheapest listed chain, TVL, growth and age, never from a list of names. Per-transaction gas is an estimate: $4 on Ethereum, $1.50 on Tron, $0.15 on common L2s and alt-L1s, $0.02 on Solana and $0.50 elsewhere. Capital scales with TVL from $100 to $300 and stays in the farmer\'s wallet. Hold time grows for young protocols and for fast TVL growth.</p>' +
      '<h2>Limits</h2><p>A protocol with no token on DefiLlama\'s record may still have one, so the first step of every plan is to check. Implied value is a ratio-based estimate, not a forecast that a token will launch or at what price. The snapshot is sealed at ' + esc(D.as_of) + ' and does not update.</p></section>';
  }

  // ---- render and events ------------------------------------------------------------------------------
  function render(keepScroll) {
    var y = window.pageYOffset;
    var view = S.tab === 'live' ? live() : S.tab === 'method' ? method() : radar();
    app.innerHTML = header(S.tab === 'radar' && S.view === 'detail') + tabs() + view;
    app.setAttribute('aria-busy', 'false');
    writeHash();
    var sc = app.querySelector('.scroller'), row = app.querySelector('tr[aria-selected="true"]');
    if (sc && row && !keepScroll) sc.scrollTop = Math.max(0, row.offsetTop - 120);
    if (keepScroll) window.scrollTo(0, y);
  }
  function select(slug) {
    S.sel = slug;
    var sc0 = app.querySelector('.scroller'), top = sc0 ? sc0.scrollTop : 0;
    render(true);
    var sc = app.querySelector('.scroller');
    if (sc) sc.scrollTop = top;
  }
  function csv() {
    var list = visible();
    var head = ['rank', 'slug', 'name', 'category', 'chains', 'tvl_usd', 'change_7d', 'age_days', 'implied_value_usd', 'confidence', 'plan_capital_usd', 'plan_gas_usd', 'plan_days'];
    var lines = [head.join(',')].concat(list.map(function (r) {
      return [r.rank, r.slug, r.name, cat(r), r.chains.join(' '), r.tvl_usd, r.change_7d, r.age_days, r.implied_value_usd, r.confidence, r.capital_usd, r.gas_usd, r.days].map(function (v) { v = v === null ? '' : String(v); return /[",\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v; }).join(',');
    }));
    var a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([lines.join('\n') + '\n'], { type: 'text/csv' }));
    a.download = 'token-radar-' + D.as_of + '.csv';
    a.click();
  }
  function reset() { S.q = ''; S.cat = 'all'; S.chain = 'all'; S.tvl = 0; S.tier = 'all'; S.conf = 'all'; S.sort = 'rank'; S.dir = 1; render(); }

  app.addEventListener('click', function (e) {
    var t = e.target.closest ? e.target.closest('[data-tab],[data-view],[data-sort],[data-tier],[data-slug],[data-step],#reset,#reset2,#csv') : null;
    if (!t) return;
    if (t.dataset.tab) { S.tab = t.dataset.tab; render(); window.scrollTo(0, 0); }
    else if (t.dataset.view) { S.view = t.dataset.view; render(); window.scrollTo(0, 0); }
    else if (t.dataset.sort) { var k = t.dataset.sort; if (S.sort === k) S.dir = -S.dir; else { S.sort = k; S.dir = k === 'name' || k === 'rank' ? 1 : -1; } render(true); }
    else if (t.dataset.tier) { S.tier = t.dataset.tier; render(true); }
    else if (t.dataset.slug) { if (window.innerWidth <= 1100) { S.sel = t.dataset.slug; S.view = 'detail'; render(); window.scrollTo(0, 0); } else select(t.dataset.slug); }
    else if (t.dataset.step) { var list = visible(), i = list.indexOf(BY[S.sel]) + Number(t.dataset.step); if (list[i]) select(list[i].slug); }
    else if (t.id === 'csv') csv();
    else reset();
  });
  app.addEventListener('change', function (e) {
    var id = e.target.id;
    if (id === 'cat' || id === 'chain' || id === 'conf') S[id] = e.target.value;
    else if (id === 'tvl') S.tvl = Number(e.target.value) || 0;
    else return;
    render(true);
  });
  app.addEventListener('input', function (e) {
    if (e.target.id !== 'q') return;
    S.q = e.target.value;
    var pos = e.target.selectionStart;
    render(true);
    var q = document.getElementById('q'); q.focus(); q.setSelectionRange(pos, pos);
  });
  document.addEventListener('keydown', function (e) {
    if (S.tab !== 'radar' || /INPUT|SELECT|TEXTAREA/.test(e.target.tagName)) return;
    var d = e.key === 'j' || e.key === 'ArrowDown' ? 1 : e.key === 'k' || e.key === 'ArrowUp' ? -1 : 0;
    if (!d) return;
    var list = visible(), i = list.indexOf(BY[S.sel]) + d;
    if (list[i]) { e.preventDefault(); select(list[i].slug); var r = app.querySelector('tr[aria-selected="true"]'); if (r) r.scrollIntoView({ block: 'nearest' }); }
  });
  app.addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && e.target.dataset && e.target.dataset.slug) { S.sel = e.target.dataset.slug; if (window.innerWidth <= 1100) S.view = 'detail'; render(); }
  });

  readHash();
  render();
})();
