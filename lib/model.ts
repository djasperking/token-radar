// Token Radar model "comps-2": one snapshot of the protocol universe in, one ranked board out.
//
// The value model is fitted from the snapshot's own live-token protocols, so no protocol name is ever
// special-cased and nothing is hardcoded about any one protocol:
//
//   1. Comparables: every protocol that records a token (and is not a CEX) gives one observation,
//      mcap / TVL, the price the market puts on a dollar of TVL.
//   2. Size: across those observations log(mcap/TVL) falls as log(TVL) rises. The slope `beta` is fitted by
//      least squares and clamped to [-0.5, 0]; every observation is restated at the comps' reference TVL.
//   3. Category: the median restated ratio of the protocol's DefiLlama category, shrunk toward the market
//      median with weight n / (n + SHRINK) so a category with one comp cannot set a price on its own.
//   4. Implied value = TVL x ratio x sizeMult x growthMult x maturityMult, where
//        sizeMult     = clamp((TVL / ref)^beta, 0.35, 1.5)
//        growthMult   = 1 + 0.5 x clamp(change_7d, -50, 100) / 100     (null change counts as 0)
//        maturityMult = 0.75 + 0.35 x min(age_days, 1095) / 1095       (null age counts as 365 days)
//
// The page recomputes the same product from the row's own figures and checks it against board.json.

export interface SnapshotProtocol {
  slug: string;
  name: string;
  category: string | null;
  chains: string[];
  tvl_usd: number;
  change_7d: number | null;
  mcap_usd: number | null;
  listed_at: string | null;
  gecko_id: string | null;
  symbol: string | null;
}

export interface Snapshot {
  as_of: string;
  source: string;
  floor_usd: number;
  protocols: SnapshotProtocol[];
  watchlist: string[];
}

export const MODEL_VERSION = 'comps-2';
export const SHRINK = 4;
export const GROWTH_FLOOR = -50;
export const GROWTH_CAP = 100;
export const GROWTH_WEIGHT = 0.5;
export const MATURITY_FLOOR = 0.75;
export const MATURITY_RANGE = 0.35;
export const MATURITY_DAYS = 1095;
export const UNKNOWN_AGE_DAYS = 365;
export const SIZE_MIN = 0.35;
export const SIZE_MAX = 1.5;
export const RATIO_MIN = 0.02;
export const RATIO_MAX = 2;

export interface FarmStep {
  text: string;
  cost: string;
  time: string;
  cost_usd: number;
  days: number;
}

export interface Comp {
  slug: string;
  name: string;
  category: string | null;
  tvl_usd: number;
  mcap_usd: number;
  ratio: number;
}

export interface CategoryStat {
  name: string;
  comps: number;
  pre_token: number;
  median_ratio: number | null;
  used_ratio: number;
  weight: number;
  confidence: 'high' | 'medium' | 'low';
}

export interface Fit {
  beta: number;
  ref_tvl: number;
  market_ratio: number;
  comps: number;
  categories: CategoryStat[];
}

export interface BoardRow {
  rank: number;
  slug: string;
  name: string;
  category: string | null;
  chains: string[];
  tvl_usd: number;
  change_7d: number | null;
  mcap_usd: number | null;
  listed_at: string | null;
  gecko_id: string | null;
  symbol: string | null;
  token_status: 'no token recorded';
  tier: 'watchlist' | 'early';
  age_days: number | null;
  implied_value_usd: number;
  confidence: 'high' | 'medium' | 'low';
  model: {
    version: string;
    peer_ratio: number;
    size_multiplier: number;
    growth_multiplier: number;
    maturity_multiplier: number;
    comps_in_category: number;
  };
  plan_capital_usd: number;
  plan_gas_usd: number;
  plan_days: number;
  farm_steps: string[];
}

export interface RadarRow {
  rank: number;
  slug: string;
  name: string;
  category: string | null;
  chains: string[];
  tvl_usd: number;
  change_7d: number | null;
  listed_at: string | null;
  age_days: number | null;
  tier: 'watchlist' | 'early';
  implied_value_usd: number;
  confidence: 'high' | 'medium' | 'low';
  ratio: number;
  size_mult: number;
  growth_mult: number;
  maturity_mult: number;
  comps_n: number;
  comps: Comp[];
  capital_usd: number;
  gas_usd: number;
  days: number;
  steps: FarmStep[];
}

export interface LiveRow {
  slug: string;
  name: string;
  category: string | null;
  chains: string[];
  tvl_usd: number;
  mcap_usd: number;
  ratio: number;
  change_7d: number | null;
}

export interface RadarData {
  as_of: string;
  source: string;
  floor_usd: number;
  model_version: string;
  constants: Record<string, number>;
  fit: Fit;
  watchlist_size: number;
  watchlist_covered: number;
  universe: number;
  excluded: number;
  rows: RadarRow[];
  live: LiveRow[];
}

export class SnapshotError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'SnapshotError';
  }
}

const DAY_MS = 86_400_000;
const clamp = (n: number, lo: number, hi: number): number => Math.min(hi, Math.max(lo, n));
const finite = (value: unknown, fallback: number): number => (typeof value === 'number' && Number.isFinite(value) ? value : fallback);
const byText = (a: string, b: string): number => (a < b ? -1 : a > b ? 1 : 0);

export function ageDays(asOf: string, listedAt: string | null): number | null {
  if (listedAt === null) return null;
  const a = Date.parse(`${asOf}T00:00:00Z`);
  const b = Date.parse(`${listedAt}T00:00:00Z`);
  if (!Number.isFinite(a) || !Number.isFinite(b)) return null;
  return Math.max(0, Math.floor((a - b) / DAY_MS));
}

/** Whether a protocol records no token at all. */
export function isPreToken(p: SnapshotProtocol): boolean {
  return p.mcap_usd === null && p.gecko_id === null && p.symbol === null;
}

const WRAPPED_CATEGORIES = new Set(['Bridge', 'Canonical Bridge', 'Liquid Staking', 'Liquid Restaking', 'Restaked BTC', 'CEX']);
const VERSIONED = /\s(V\d+(\.\d+)?|v\d+(\.\d+)?|\d+\.\d+)$/;
const WRAPPED_WORD = /\b(wrapped|staked|staking)\b/i;
const EXCHANGE = /^(binance|coinbase|bybit|kraken|bitget|okx|bitfinex|gemini)/i;

/** The house rule for a protocol that is a wrapped, staked, bridged or exchange product of another one. */
export function isDerivative(p: SnapshotProtocol): boolean {
  return (p.category !== null && WRAPPED_CATEGORIES.has(p.category)) || VERSIONED.test(p.name) || WRAPPED_WORD.test(p.name) || EXCHANGE.test(p.name);
}

/** Whether the board may rank a protocol: it records no token and is not a derivative of another one. */
export function isRankable(p: SnapshotProtocol): boolean {
  return isPreToken(p) && !isDerivative(p);
}

function median(values: number[]): number {
  const v = [...values].sort((a, b) => a - b);
  const m = v.length >> 1;
  return v.length % 2 === 1 ? v[m]! : (v[m - 1]! + v[m]!) / 2;
}

/** The comparables: protocols that record a token and a market cap, CEXs set aside. */
export function comparables(snapshot: Snapshot): Comp[] {
  const out: Comp[] = [];
  for (const p of snapshot.protocols) {
    if (p.mcap_usd === null || p.mcap_usd <= 0 || p.tvl_usd <= 0 || p.category === 'CEX') continue;
    out.push({ slug: p.slug, name: p.name, category: p.category, tvl_usd: p.tvl_usd, mcap_usd: p.mcap_usd, ratio: p.mcap_usd / p.tvl_usd });
  }
  return out;
}

/** Fit the size slope, the market median and every category's shrunk median from the comparables. */
export function fitModel(snapshot: Snapshot): Fit {
  const comps = comparables(snapshot);
  const xs = comps.map((c) => Math.log(c.tvl_usd));
  const ys = comps.map((c) => Math.log(clamp(c.ratio, 0.01, 10)));
  const mx = xs.reduce((a, b) => a + b, 0) / Math.max(1, xs.length);
  const my = ys.reduce((a, b) => a + b, 0) / Math.max(1, ys.length);
  let sxy = 0;
  let sxx = 0;
  for (let i = 0; i < xs.length; i++) {
    sxy += (xs[i]! - mx) * (ys[i]! - my);
    sxx += (xs[i]! - mx) ** 2;
  }
  const beta = clamp(sxx > 0 ? sxy / sxx : 0, -0.5, 0);
  const restated = comps.map((_, i) => ys[i]! - beta * (xs[i]! - mx));
  const marketLog = restated.length > 0 ? median(restated) : Math.log(0.17);
  const names = new Set<string>();
  for (const p of snapshot.protocols) names.add(p.category ?? 'Uncategorised');
  const stats: CategoryStat[] = [];
  for (const name of [...names].sort(byText)) {
    const idx = comps.map((c, i) => ((c.category ?? 'Uncategorised') === name ? i : -1)).filter((i) => i >= 0);
    const n = idx.length;
    const catLog = n > 0 ? median(idx.map((i) => restated[i]!)) : marketLog;
    const weight = n / (n + SHRINK);
    const used = clamp(Math.exp(weight * catLog + (1 - weight) * marketLog), RATIO_MIN, RATIO_MAX);
    const pre = snapshot.protocols.filter((p) => (p.category ?? 'Uncategorised') === name && isRankable(p)).length;
    stats.push({
      name,
      comps: n,
      pre_token: pre,
      median_ratio: n > 0 ? Math.exp(catLog) : null,
      used_ratio: used,
      weight,
      confidence: n >= 8 ? 'high' : n >= 3 ? 'medium' : 'low',
    });
  }
  return { beta, ref_tvl: Math.exp(mx), market_ratio: Math.exp(marketLog), comps: comps.length, categories: stats };
}

/** The multipliers and implied value one protocol gets under the fitted model. */
export function impliedValue(p: SnapshotProtocol, asOf: string, fit: Fit): { implied: number; ratio: number; size: number; growth: number; maturity: number; age: number | null; conf: 'high' | 'medium' | 'low'; n: number } {
  const age = ageDays(asOf, p.listed_at);
  const stat = fit.categories.find((c) => c.name === (p.category ?? 'Uncategorised'));
  const ratio = stat !== undefined ? stat.used_ratio : fit.market_ratio;
  const size = clamp(Math.pow(p.tvl_usd / fit.ref_tvl, fit.beta), SIZE_MIN, SIZE_MAX);
  const growth = 1 + (clamp(finite(p.change_7d, 0), GROWTH_FLOOR, GROWTH_CAP) / 100) * GROWTH_WEIGHT;
  const maturity = MATURITY_FLOOR + (Math.min(Math.max(age ?? UNKNOWN_AGE_DAYS, 0), MATURITY_DAYS) / MATURITY_DAYS) * MATURITY_RANGE;
  const implied = Math.max(1, Math.round(p.tvl_usd * ratio * size * growth * maturity));
  return { implied, ratio, size, growth, maturity, age, conf: stat?.confidence ?? 'low', n: stat?.comps ?? 0 };
}

/** The three comparables nearest in TVL: the protocol's category first, the whole market to fill. */
function nearestComps(p: SnapshotProtocol, comps: Comp[]): Comp[] {
  const dist = (c: Comp): number => Math.abs(Math.log(c.tvl_usd / p.tvl_usd));
  const same = comps.filter((c) => c.category === p.category).sort((a, b) => dist(a) - dist(b) || byText(a.slug, b.slug));
  const rest = comps.filter((c) => c.category !== p.category).sort((a, b) => dist(a) - dist(b) || byText(a.slug, b.slug));
  return [...same, ...rest].slice(0, 3);
}

// ---------------------------------------------------------------------------------------------------
// Farm plans: derived from the protocol's own record (category, chains, TVL, growth, age). The gas figures
// are the model's per-transaction estimates by chain, stated on the Method tab; they are estimates.

const GAS_L2 = ['Arbitrum', 'Base', 'Optimism', 'OP Mainnet', 'Linea', 'Scroll', 'zkSync Era', 'Blast', 'Mantle', 'Unichain', 'Ink', 'Soneium', 'Polygon', 'Avalanche', 'BSC', 'Binance', 'Sonic', 'Berachain', 'Plasma', 'Hyperliquid L1', 'Katana'];

/** Estimated dollars of gas for one transaction on the chain. */
export function gasUsd(chain: string): number {
  if (chain === 'Ethereum') return 4;
  if (chain === 'Solana') return 0.02;
  if (chain === 'Tron') return 1.5;
  if (GAS_L2.includes(chain)) return 0.15;
  return 0.5;
}

/** The cheapest of the protocol's first three chains for a farmer, else its first chain. */
function farmChain(p: SnapshotProtocol): string {
  if (p.chains.length === 0) return 'its main chain';
  const pool = p.chains.slice(0, 4);
  return [...pool].sort((a, b) => gasUsd(a) - gasUsd(b) || byText(a, b))[0]!;
}

function capitalFor(tvl: number): number {
  if (tvl >= 1_000_000_000) return 300;
  if (tvl >= 250_000_000) return 200;
  if (tvl >= 50_000_000) return 150;
  return 100;
}

function holdDaysFor(age: number | null, growth: number): number {
  const base = age === null ? 45 : age < 120 ? 75 : age < 365 ? 60 : age < 730 ? 45 : 30;
  return growth > 25 ? base + 15 : base;
}

type Kind = 'lending' | 'dex' | 'yield' | 'curator' | 'basis' | 'rwa' | 'stake' | 'chain' | 'insurance' | 'payments' | 'prediction' | 'stable' | 'govern' | 'generic';

function kindOf(category: string | null): Kind {
  const c = (category ?? '').toLowerCase();
  if (c.includes('risk curator') || c.includes('allocator') || c.includes('curator')) return 'curator';
  if (c.includes('lend') || c.includes('cdp') || c.includes('collateral')) return 'lending';
  if (c.includes('dex') || c.includes('liquidity') || c.includes('amm') || c.includes('options')) return 'dex';
  if (c.includes('yield') || c.includes('farm') || c.includes('vault')) return 'yield';
  if (c.includes('basis') || c.includes('cedefi') || c.includes('derivative') || c.includes('perp')) return 'basis';
  if (c.includes('rwa') || c.includes('treasury') || c.includes('real world')) return 'rwa';
  if (c.includes('stak') || c.includes('restak')) return 'stake';
  if (c === 'chain' || c.includes('chain')) return 'chain';
  if (c.includes('insur')) return 'insurance';
  if (c.includes('payment') || c.includes('card')) return 'payments';
  if (c.includes('prediction')) return 'prediction';
  if (c.includes('stable')) return 'stable';
  if (c.includes('govern')) return 'govern';
  return 'generic';
}

const money = (n: number): string => (n < 1 ? `$${n.toFixed(2)}` : `$${Math.round(n)}`);

/** A protocol's farm plan: concrete steps, each with what it costs and how long it takes. */
export function farmSteps(p: SnapshotProtocol, age: number | null, growth: number): FarmStep[] {
  const chain = farmChain(p);
  const g = gasUsd(chain);
  const capital = capitalFor(p.tvl_usd);
  const hold = holdDaysFor(age, growth);
  const weeks = Math.max(2, Math.floor(hold / 7));
  const kind = kindOf(p.category);
  const n = p.name;
  const cat = p.category ?? 'its category';
  const fund = Math.max(g * 6, 1);
  const steps: FarmStep[] = [];
  steps.push({
    text: `Confirm ${n} still records no token: read its docs and announcements, and search the ticker on a market tracker. DefiLlama's record can lag, so a token that already trades means skip this plan.`,
    cost: '$0',
    time: '10 minutes',
    cost_usd: 0,
    days: 0,
  });
  steps.push({
    text: `Open a fresh wallet that holds only farm funds, send ${money(capital)} of USDC plus ${money(fund)} of gas to it on ${chain}, and keep the seed phrase offline.`,
    cost: `${money(capital)} capital that stays yours, about ${money(g * 2)} of gas to move it`,
    time: '20 minutes',
    cost_usd: g * 2,
    days: 0,
  });
  let first: string;
  let second: string;
  let firstGas = g * 2;
  let secondGas = g * 2;
  switch (kind) {
    case 'lending':
      first = `Supply ${money(capital)} of USDC to ${n} on ${chain} and confirm the receipt token shows in your wallet.`;
      second = `Borrow about ${money(capital * 0.15)} of a stablecoin against it, a loan-to-value near 15%, so the borrow side is counted too, then repay and re-supply once before the hold ends.`;
      secondGas = g * 4;
      break;
    case 'dex':
      first = `Add ${money(capital)} of liquidity to ${n}'s deepest stablecoin pair on ${chain}, half and half, and keep the position token.`;
      second = `Make three small swaps of about ${money(capital * 0.1)} each through ${n}, on different days, so volume and liquidity are both on the wallet.`;
      secondGas = g * 3;
      break;
    case 'yield':
      first = `Deposit ${money(capital)} of USDC into ${n}'s largest unleveraged vault on ${chain}; skip any vault that needs borrowing to reach its headline rate.`;
      second = `Compound or harvest once at the half-way point of the hold so the wallet shows more than one interaction, and note the vault's share price.`;
      break;
    case 'curator':
      first = `Pick ${n}'s largest USDC vault on ${chain} and read which lending markets it allocates to before depositing ${money(capital * 0.6)} of USDC.`;
      second = `Add ${money(capital * 0.4)} to a second ${n} vault with different underlying markets, so risk and activity are spread across two vaults.`;
      break;
    case 'basis':
      first = `Deposit ${money(capital)} of USDC as margin into ${n} on ${chain} and read how its hedge is built before sizing anything.`;
      second = `Open the smallest position the app allows, about ${money(capital * 0.1)}, hold it through one funding period and close it, then log the fees.`;
      secondGas = g * 3;
      break;
    case 'rwa':
      first = `Check whether ${n} needs identity checks or a minimum ticket, then mint or buy ${money(capital)} of its yield-bearing asset on ${chain} if the terms fit.`;
      second = `Hold the asset through one yield or rebase cycle and keep the transaction record; do not swap out early.`;
      secondGas = g;
      break;
    case 'stake':
      first = `Stake ${money(capital)} of the supported asset through ${n} on ${chain} and keep the receipt token in the same wallet.`;
      second = `Use the receipt token once in a second app that ${n} lists as an integration, so the wallet shows both staking and use.`;
      break;
    case 'chain':
      first = `Bridge ${money(capital)} of USDC to ${n} using its native bridge and swap about ${money(capital * 0.2)} into the native gas token.`;
      second = `Use three different apps on ${n} (a swap, a lend and one other) with ${money(capital * 0.1)} each, on separate days.`;
      secondGas = g * 6;
      break;
    case 'insurance':
      first = `Buy ${money(capital * 0.5)} of cover through ${n} on ${chain} for a protocol you already use, and keep the policy token.`;
      second = `Renew or extend the cover once before it expires, then check the claims page so the policy reads as active.`;
      break;
    case 'payments':
      first = `Fund a ${n} account with ${money(capital)} of USDC on ${chain} and complete any identity step it asks for.`;
      second = `Make three small real payments of about ${money(capital * 0.05)} each over separate weeks, since activity here is spending, not depositing.`;
      secondGas = g * 3;
      break;
    case 'prediction':
      first = `Fund ${n} with ${money(capital)} of USDC on ${chain} and place one position of about ${money(capital * 0.2)} on a liquid market.`;
      second = `Place two more small positions on different markets over the hold and close one early, so the wallet shows trades and exits.`;
      secondGas = g * 4;
      break;
    case 'stable':
      first = `Mint or deposit ${money(capital)} through ${n} on ${chain} and hold the stable asset it returns.`;
      second = `Move the stable asset into its savings or staking option if ${n} offers one, and keep the position open.`;
      break;
    case 'govern':
      first = `Lock or deposit ${money(capital)} in ${n} on ${chain} to get voting weight, and note the lock length it requires.`;
      second = `Vote on at least two ${n} proposals or gauges during the hold; voting is the activity this category rewards.`;
      secondGas = g * 2;
      break;
    default:
      first = `Deposit ${money(capital)} of USDC into ${n}'s main product on ${chain} and keep the position open.`;
      second = `Use the one other feature ${n} documents, such as a borrow, a swap or a vote, once with a small amount.`;
  }
  steps.push({ text: first, cost: `${money(capital)} capital, about ${money(firstGas)} of gas`, time: '15 minutes', cost_usd: firstGas, days: 0 });
  steps.push({ text: second, cost: `about ${money(secondGas)} of gas`, time: '20 minutes', cost_usd: secondGas, days: 0 });
  const growthNote = growth > 25 ? ` TVL grew ${Math.round(growth)}% in 7 days, so early activity may count for more; plan a longer window.` : growth < -25 ? ` TVL fell ${Math.round(-growth)}% in 7 days, so check why before adding more.` : '';
  steps.push({
    text: `Come back once a week for ${weeks} weeks and make one qualifying action each time, such as a deposit top-up, a swap or a vote.${growthNote}`,
    cost: `about ${money(g * weeks)} of gas in all`,
    time: `10 minutes a week for ${weeks} weeks`,
    cost_usd: g * weeks,
    days: hold,
  });
  steps.push({
    text: `Keep the position open for at least ${hold} days${age === null ? '' : age < 180 ? ' (the protocol is young, so a longer window is likelier to span a snapshot)' : ''}, then check ${n}'s own site and announcements for a points or rewards page.`,
    cost: `the ${money(capital)} stays in the position`,
    time: `${hold} days`,
    cost_usd: 0,
    days: hold,
  });
  steps.push({
    text: `Before you claim or withdraw, use only the link on ${n}'s own site, never a link from a message, and unwind the position once the hold is done.`,
    cost: `about ${money(g * 2)} of gas to exit`,
    time: '15 minutes',
    cost_usd: g * 2,
    days: 0,
  });
  steps.push({
    text: `Write the wallet, the dates, each transaction and the ${cat} position size in a farm log, so you can repeat it, unwind it or prove the activity.`,
    cost: '$0',
    time: '5 minutes',
    cost_usd: 0,
    days: 0,
  });
  return steps;
}

export function stepText(step: FarmStep): string {
  let s = `${step.text} Cost: ${step.cost}. Time: ${step.time}.`;
  if (s.length > 600) s = `${s.slice(0, 596)}...`;
  if (s.length < 20) s = `${s} Hold the position and check the protocol's own page.`;
  return s;
}

/** The live-token protocols, by market cap: the market's own values, never mixed into the ranked board. */
export function liveRows(snapshot: Snapshot, limit: number): LiveRow[] {
  return comparables(snapshot)
    .sort((a, b) => b.mcap_usd - a.mcap_usd || byText(a.slug, b.slug))
    .slice(0, limit)
    .map((c) => {
      const p = snapshot.protocols.find((x) => x.slug === c.slug)!;
      return { slug: c.slug, name: c.name, category: c.category, chains: p.chains, tvl_usd: c.tvl_usd, mcap_usd: c.mcap_usd, ratio: c.ratio, change_7d: p.change_7d };
    });
}

/** The board and the page's data, from one snapshot. Every watchlist protocol is on it, and so is every other rankable pre-token protocol. */
export function buildRadar(snapshot: Snapshot): { board: BoardRow[]; radar: RadarData } {
  const fit = fitModel(snapshot);
  const comps = comparables(snapshot);
  const watch = new Set(snapshot.watchlist);
  const chosen = snapshot.protocols.filter((p) => watch.has(p.slug) || isRankable(p));
  const scored = chosen.map((p) => ({ p, v: impliedValue(p, snapshot.as_of, fit) }));
  scored.sort((a, b) => b.v.implied - a.v.implied || byText(a.p.slug, b.p.slug));
  const board: BoardRow[] = [];
  const rows: RadarRow[] = [];
  scored.forEach(({ p, v }, i) => {
    const steps = farmSteps(p, v.age, clamp(finite(p.change_7d, 0), GROWTH_FLOOR, GROWTH_CAP));
    const capital = capitalFor(p.tvl_usd);
    const gas = steps.reduce((s, x) => s + x.cost_usd, 0);
    const days = steps.reduce((m, x) => Math.max(m, x.days), 0);
    const tier = watch.has(p.slug) ? 'watchlist' : 'early';
    board.push({
      rank: i + 1,
      slug: p.slug,
      name: p.name,
      category: p.category,
      chains: p.chains,
      tvl_usd: p.tvl_usd,
      change_7d: p.change_7d,
      mcap_usd: p.mcap_usd,
      listed_at: p.listed_at,
      gecko_id: p.gecko_id,
      symbol: p.symbol,
      token_status: 'no token recorded',
      tier,
      age_days: v.age,
      implied_value_usd: v.implied,
      confidence: v.conf,
      model: { version: MODEL_VERSION, peer_ratio: v.ratio, size_multiplier: v.size, growth_multiplier: v.growth, maturity_multiplier: v.maturity, comps_in_category: v.n },
      plan_capital_usd: capital,
      plan_gas_usd: Math.round(gas * 100) / 100,
      plan_days: days,
      farm_steps: steps.map(stepText),
    });
    rows.push({
      rank: i + 1,
      slug: p.slug,
      name: p.name,
      category: p.category,
      chains: p.chains,
      tvl_usd: p.tvl_usd,
      change_7d: p.change_7d,
      listed_at: p.listed_at,
      age_days: v.age,
      tier,
      implied_value_usd: v.implied,
      confidence: v.conf,
      ratio: v.ratio,
      size_mult: v.size,
      growth_mult: v.growth,
      maturity_mult: v.maturity,
      comps_n: v.n,
      comps: nearestComps(p, comps),
      capital_usd: capital,
      gas_usd: Math.round(gas * 100) / 100,
      days,
      steps,
    });
  });
  const radar: RadarData = {
    as_of: snapshot.as_of,
    source: snapshot.source,
    floor_usd: snapshot.floor_usd,
    model_version: MODEL_VERSION,
    constants: {
      shrink: SHRINK,
      growth_floor: GROWTH_FLOOR,
      growth_cap: GROWTH_CAP,
      growth_weight: GROWTH_WEIGHT,
      maturity_floor: MATURITY_FLOOR,
      maturity_range: MATURITY_RANGE,
      maturity_days: MATURITY_DAYS,
      unknown_age_days: UNKNOWN_AGE_DAYS,
      size_min: SIZE_MIN,
      size_max: SIZE_MAX,
    },
    fit,
    watchlist_size: snapshot.watchlist.length,
    watchlist_covered: snapshot.watchlist.filter((s) => board.some((r) => r.slug === s)).length,
    universe: snapshot.protocols.length,
    excluded: snapshot.protocols.filter((p) => isPreToken(p) && isDerivative(p) && !watch.has(p.slug)).length,
    rows,
    live: liveRows(snapshot, 30),
  };
  return { board, radar };
}

/** The snapshot out of a file's text, refused unless it is the shape the model scores. */
export function parseSnapshot(text: string): Snapshot {
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    throw new SnapshotError('snapshot.json is not JSON');
  }
  if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) throw new SnapshotError('snapshot.json is not a JSON object');
  const o = raw as Record<string, unknown>;
  if (typeof o.as_of !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(o.as_of)) throw new SnapshotError('snapshot.json has no as_of date');
  if (typeof o.source !== 'string') throw new SnapshotError('snapshot.json has no source');
  if (typeof o.floor_usd !== 'number' || !Number.isSafeInteger(o.floor_usd) || o.floor_usd <= 0) throw new SnapshotError('snapshot.json has no floor_usd');
  if (!Array.isArray(o.protocols)) throw new SnapshotError('snapshot.json has no protocols array');
  if (!Array.isArray(o.watchlist) || o.watchlist.some((s) => typeof s !== 'string')) throw new SnapshotError('snapshot.json has no watchlist of slugs');
  const protocols = o.protocols.map((v, i) => {
    if (typeof v !== 'object' || v === null || Array.isArray(v)) throw new SnapshotError(`snapshot.json's protocol ${i} is not an object`);
    const p = v as Record<string, unknown>;
    if (typeof p.slug !== 'string' || typeof p.name !== 'string' || typeof p.tvl_usd !== 'number' || !Number.isFinite(p.tvl_usd)) {
      throw new SnapshotError(`snapshot.json's protocol ${i} lacks a slug, a name or a TVL`);
    }
    return {
      slug: p.slug,
      name: p.name,
      category: typeof p.category === 'string' ? p.category : null,
      chains: Array.isArray(p.chains) ? p.chains.filter((c): c is string => typeof c === 'string') : [],
      tvl_usd: p.tvl_usd,
      change_7d: typeof p.change_7d === 'number' && Number.isFinite(p.change_7d) ? p.change_7d : null,
      mcap_usd: typeof p.mcap_usd === 'number' && Number.isFinite(p.mcap_usd) ? p.mcap_usd : null,
      listed_at: typeof p.listed_at === 'string' ? p.listed_at : null,
      gecko_id: typeof p.gecko_id === 'string' ? p.gecko_id : null,
      symbol: typeof p.symbol === 'string' ? p.symbol : null,
    };
  });
  return { as_of: o.as_of, source: o.source, floor_usd: o.floor_usd, protocols, watchlist: o.watchlist as string[] };
}

/** Why a board is not one the gate will take, or null: coverage, ranks, order, one shared implied value, and farm steps. */
export function boardIssue(board: BoardRow[], snapshot: Snapshot): string | null {
  if (board.length < 100) return `the board holds ${board.length} rows; the gate needs at least 100`;
  const slugs = new Set(board.map((r) => r.slug));
  if (slugs.size !== board.length) return 'a slug appears twice';
  const known = new Set(snapshot.protocols.map((p) => p.slug));
  const invented = board.filter((r) => !known.has(r.slug));
  if (invented.length > 0) return `${invented.length} rows name slugs the snapshot does not list`;
  const missing = snapshot.watchlist.filter((s) => !slugs.has(s));
  if (missing.length > 0) return `the board misses ${missing.length} watchlist slug${missing.length === 1 ? '' : 's'}: ${missing.slice(0, 5).join(', ')}`;
  const ranks = board.map((r) => r.rank).sort((a, b) => a - b);
  for (let i = 0; i < ranks.length; i++) if (ranks[i] !== i + 1) return `rank ${i + 1} is ${ranks[i]}`;
  for (let i = 1; i < board.length; i++) if (board[i]!.implied_value_usd > board[i - 1]!.implied_value_usd) return `row ${i + 1} outranks row ${i} on implied value`;
  if (board[0]!.implied_value_usd === board[board.length - 1]!.implied_value_usd) return `all ${board.length} rows share one implied value`;
  for (const r of board) {
    const steps = r.farm_steps;
    if (steps.length < 3 || steps.length > 12) return `${r.slug} has ${steps.length} farm steps`;
    for (const s of steps) if (s.trim().length < 20 || s.trim().length > 600) return `${r.slug} has a farm step of ${s.trim().length} characters`;
    if (!Number.isSafeInteger(r.implied_value_usd) || r.implied_value_usd <= 0 || r.implied_value_usd > 100_000_000_000_000) return `${r.slug} has implied value ${r.implied_value_usd}`;
  }
  return null;
}

/** A compact data.js: the dashboard's whole dataset as one script, no fetch and no network. */
export function dataScript(radar: RadarData): string {
  return `window.RADAR=${JSON.stringify(radar)};\n`;
}
