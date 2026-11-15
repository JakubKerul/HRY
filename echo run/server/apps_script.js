// ECHO RUN - server pre spolocny rebricek (Google Apps Script nad Google tabulkou)
//
// Listy v tabulke:
//   players : jeden riadok na hraca = ucet + jeho najlepsie skore (toto je "rebricek")
//   scores  : kazda dohrana hra (meno, skore, kolo, rezim, datum) - z toho sa pocitaju denne rebricky
//
// Rezimy: 0 = endless, 1 = denna vyzva (pocita sa do endless), 2 = kampan
//
// Discord prihlasenie: client secret je vo vlastnosti DISCORD_SECRET (tiez nie v kode).
// Discord: adresa webhooku sa NEPISE sem do kodu. Je ulozena vo vlastnostiach skriptu
// (Nastavenia projektu -> Vlastnosti skriptu -> DISCORD_WEBHOOK), aby nebola verejne na GitHube.

const SHEET_ID = '1fKlLLXRNdBeR0-hxZAlQ1WRlfZ_edoxxL27u9pUTIRw';  // tabulka "Echo Run scores"
const P_HEAD = ['name', 'key', 'salt', 'hash', 'token', 'created', 'best_campaign', 'best_endless', 'round_campaign', 'round_endless', 'date_campaign', 'date_endless', 'discord'];
const S_HEAD = ['name', 'score', 'round', 'mode', 'date', 'time'];
const COL = { name: 0, key: 1, salt: 2, hash: 3, token: 4, created: 5, bc: 6, be: 7, rc: 8, re: 9, dc: 10, de: 11, did: 12 };
const DISCORD_CLIENT_ID = '1571505542361382982';  // aplikacia Echo Run v Discord Developer Portali

function ss_() { return SpreadsheetApp.openById(SHEET_ID); }

function sheet_(name, head) {
  let sh = ss_().getSheetByName(name);
  if (!sh) {
    sh = ss_().insertSheet(name);
    sh.appendRow(head);
    sh.setFrozenRows(1);
  }
  return sh;
}

function out_(o) {
  return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON);
}

// Mena: pismena (aj s diakritikou), cislice, medzera, bodka, pomlcka, podciarnik; 2 az 16 znakov.
function cleanName_(n) {
  return String(n || '').replace(/[^\p{L}\p{N} ._-]/gu, '').replace(/\s+/g, ' ').trim().slice(0, 16);
}

function key_(n) { return n.toLocaleLowerCase('sk'); }

function hash_(salt, pass) {
  let h = salt + '|' + pass;
  for (let i = 0; i < 200; i++) {
    h = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, h, Utilities.Charset.UTF_8)
      .map(b => ('0' + (b & 255).toString(16)).slice(-2)).join('');
  }
  return h;
}

function day_(v, tz) {
  return v instanceof Date ? Utilities.formatDate(v, tz, 'yyyy-MM-dd') : String(v);
}

// ------------------------------------------------------------------ citanie rebricka
// GET ?top=50&m=2&d=2026-11-15   (m: "2" kampan, "01" endless; d prazdne = celkovo)
function doGet(e) {
  const q = e.parameter || {};
  const camp = String(q.m || '2') === '2';
  const day = String(q.d || '');
  const n = Math.min(100, parseInt(q.top) || 50);
  let rows = [];
  if (!day) {
    // celkovo: priamo z uctov, jeden riadok na hraca
    const tz = ss_().getSpreadsheetTimeZone();
    sheet_('players', P_HEAD).getDataRange().getValues().slice(1).forEach(r => {
      const s = Number(camp ? r[COL.bc] : r[COL.be]) || 0;
      if (s > 0) rows.push({ n: String(r[COL.name]), s: s, r: Number(camp ? r[COL.rc] : r[COL.re]) || 0, m: camp ? 2 : 0, d: day_(camp ? r[COL.dc] : r[COL.de], tz) });
    });
  } else {
    // dnes: najlepsia hra kazdeho hraca v dany den
    const tz = ss_().getSpreadsheetTimeZone();
    const best = {};
    sheet_('scores', S_HEAD).getDataRange().getValues().slice(1).forEach(r => {
      const m = Number(r[3]);
      if ((m === 2) !== camp) return;
      if (day_(r[4], tz) !== day) return;
      const row = { n: String(r[0]), s: Number(r[1]), r: Number(r[2]), m: m, d: day };
      if (!best[row.n] || row.s > best[row.n].s) best[row.n] = row;
    });
    rows = Object.keys(best).map(k => best[k]);
  }
  rows.sort((a, b) => b.s - a.s);
  return out_(rows.slice(0, n));
}

// ------------------------------------------------------------------ zapis
// POST (text/plain JSON):
//   {a:"register", n, p}  -> {ok, n, t} | {ok:false, err:"taken"|"name"|"pass"}
//   {a:"login", n, p}     -> {ok, n, t} | {ok:false, err:"bad"}
//   {a:"discord", c}     -> {ok, n, t} | {ok:false, err:"discord"|"nodc"}  (kod z Discord Activity)
//   {a:"score", t, s, r, m, d} -> {ok, best, rank} | {ok:false, err:"auth"}
function doPost(e) {
  let p = {};
  try { p = JSON.parse(e.postData.contents); } catch (err) {}
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(15000)) return out_({ ok: false, err: 'busy' });
  try {
    if (p.a === 'register') return out_(register_(p));
    if (p.a === 'login') return out_(login_(p));
    if (p.a === 'score') return out_(score_(p));
    if (p.a === 'discord') return out_(discordLogin_(p));
    return out_({ ok: false, err: 'action' });
  } finally {
    lock.releaseLock();
  }
}

function findBy_(rows, col, val) {
  for (let i = 1; i < rows.length; i++) if (String(rows[i][col]) === val) return i;
  return -1;
}

function register_(p) {
  const name = cleanName_(p.n);
  const pass = String(p.p || '');
  if (name.length < 2) return { ok: false, err: 'name' };
  if (pass.length < 4) return { ok: false, err: 'pass' };
  const sh = sheet_('players', P_HEAD);
  const rows = sh.getDataRange().getValues();
  if (findBy_(rows, COL.key, key_(name)) > 0) return { ok: false, err: 'taken' };
  const salt = Utilities.getUuid();
  const token = Utilities.getUuid();
  sh.appendRow([name, key_(name), salt, hash_(salt, pass), token, new Date(), 0, 0, 0, 0, '', '']);
  return { ok: true, n: name, t: token };
}

function login_(p) {
  const name = cleanName_(p.n);
  const pass = String(p.p || '');
  const sh = sheet_('players', P_HEAD);
  const rows = sh.getDataRange().getValues();
  const i = findBy_(rows, COL.key, key_(name));
  if (i < 0 || hash_(String(rows[i][COL.salt]), pass) !== String(rows[i][COL.hash])) return { ok: false, err: 'bad' };
  return { ok: true, n: String(rows[i][COL.name]), t: String(rows[i][COL.token]) };
}

// Prihlasenie cez Discord: kod -> access token -> Discord ucet -> nas ucet (jeden na Discord ID)
function discordLogin_(p) {
  const secret = PropertiesService.getScriptProperties().getProperty('DISCORD_SECRET');
  if (!secret) return { ok: false, err: 'nodc' };
  const code = String(p.c || '');
  if (!code) return { ok: false, err: 'discord' };
  const tr = UrlFetchApp.fetch('https://discord.com/api/oauth2/token', {
    method: 'post',
    payload: { client_id: DISCORD_CLIENT_ID, client_secret: secret, grant_type: 'authorization_code', code: code },
    muteHttpExceptions: true
  });
  if (tr.getResponseCode() !== 200) return { ok: false, err: 'discord' };
  const at = JSON.parse(tr.getContentText()).access_token;
  const ur = UrlFetchApp.fetch('https://discord.com/api/users/@me', { headers: { Authorization: 'Bearer ' + at }, muteHttpExceptions: true });
  if (ur.getResponseCode() !== 200) return { ok: false, err: 'discord' };
  const u = JSON.parse(ur.getContentText());
  const did = String(u.id || '');
  if (!did) return { ok: false, err: 'discord' };

  const sh = sheet_('players', P_HEAD);
  if (sh.getLastColumn() < P_HEAD.length) sh.getRange(1, P_HEAD.length).setValue(P_HEAD[P_HEAD.length - 1]);
  const rows = sh.getDataRange().getValues();
  const i = findBy_(rows, COL.did, did);
  if (i > 0) return { ok: true, n: String(rows[i][COL.name]), t: String(rows[i][COL.token]) };

  // novy hrac: meno z Discordu; ked je obsadene, skusime alternativy
  const tries = [u.global_name, u.username, String(u.username || '') + '_dc', 'dc' + did.slice(-6)];
  let name = '';
  for (const t of tries) {
    const c = cleanName_(t);
    if (c.length >= 2 && findBy_(rows, COL.key, key_(c)) < 0) { name = c; break; }
  }
  if (!name) name = 'dc' + did;
  const token = Utilities.getUuid();
  // hash "discord" nie je platny hash, takze sa na tento ucet neda prihlasit heslom
  sh.appendRow([name, key_(name), Utilities.getUuid(), 'discord', token, new Date(), 0, 0, 0, 0, '', '', "'" + did]);
  return { ok: true, n: name, t: token };
}

function ranking_(rows, col) {
  const list = [];
  for (let i = 1; i < rows.length; i++) {
    const s = Number(rows[i][col]) || 0;
    if (s > 0) list.push({ n: String(rows[i][COL.name]), s: s });
  }
  list.sort((a, b) => b.s - a.s);
  return list;
}

function score_(p) {
  const sh = sheet_('players', P_HEAD);
  const rows = sh.getDataRange().getValues();
  const i = findBy_(rows, COL.token, String(p.t || ''));
  if (i < 1 || !p.t) return { ok: false, err: 'auth' };
  const name = String(rows[i][COL.name]);
  const score = Math.max(0, Math.min(1000000, parseInt(p.s) || 0));
  const round = Math.max(0, Math.min(999, parseInt(p.r) || 0));
  const mode = Math.max(0, Math.min(2, parseInt(p.m) || 0));
  if (score <= 0) return { ok: true };
  const now = new Date();
  const day = /^\d{4}-\d{2}-\d{2}$/.test(String(p.d)) ? String(p.d) : Utilities.formatDate(now, 'UTC', 'yyyy-MM-dd');
  // kazda hra do logu (datum ako text, aby ho tabulka neposunula o den)
  sheet_('scores', S_HEAD).appendRow([name, score, round, mode, "'" + day, now]);

  const camp = mode === 2;
  const cBest = camp ? COL.bc : COL.be;
  const old = Number(rows[i][cBest]) || 0;
  if (score <= old) return { ok: true, best: old };

  // novy osobny rekord: prepis riadok hraca (v rebricku je kazdy hrac iba raz)
  const before = ranking_(rows, cBest);
  const oldRank = before.findIndex(x => x.n === name);
  rows[i][cBest] = score;
  const r = i + 1;
  sh.getRange(r, cBest + 1).setValue(score);
  sh.getRange(r, (camp ? COL.rc : COL.re) + 1).setValue(round);
  sh.getRange(r, (camp ? COL.dc : COL.de) + 1).setValue("'" + day);
  const after = ranking_(rows, cBest);
  const newRank = after.findIndex(x => x.n === name);

  // koho predbehol: hraci, ktori boli pred nim a teraz su za nim
  const passed = [];
  const limit = oldRank < 0 ? before.length : oldRank;
  for (let k = 0; k < limit; k++) {
    if (before[k].s < score && before[k].n !== name) passed.push(before[k].n);
  }
  try { discord_(name, score, camp, old, newRank + 1, passed); } catch (err) {}
  return { ok: true, best: score, rank: newRank + 1 };
}

// ------------------------------------------------------------------ Discord
function discord_(name, score, camp, old, rank, passed) {
  const esc = n => String(n).replace(/([*_~`|\\>])/g, '\\$1');
  name = esc(name);
  passed = passed.map(esc);
  const url = PropertiesService.getScriptProperties().getProperty('DISCORD_WEBHOOK');
  if (!url) return;
  const mode = camp ? 'Campaign' : 'Endless';
  let text;
  if (passed.length > 0) {
    const who = passed.slice(0, 3).map(n => '**' + n + '**').join(', ') + (passed.length > 3 ? ' +' + (passed.length - 3) : '');
    text = (rank === 1 ? '🏆 ' : '⚡ ') + '**' + name + '** overtook ' + who + ' in ' + mode + ' with **' + score + '** points and is now **#' + rank + '**!';
  } else if (old > 0) {
    text = '🔥 **' + name + '** set a new personal best in ' + mode + ': **' + score + '** (was ' + old + '). Rank **#' + rank + '**.';
  } else {
    text = '👋 **' + name + '** joined the ' + mode + ' rating with **' + score + '** points at **#' + rank + '**.';
  }
  UrlFetchApp.fetch(url, {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify({ username: 'Echo Run', content: text, allowed_mentions: { parse: [] } }),
    muteHttpExceptions: true
  });
}

// Spusti raz v editore (Run -> discordTest), aby Google povolil pripojenie na Discord.
function discordTest() {
  const url = PropertiesService.getScriptProperties().getProperty('DISCORD_WEBHOOK');
  if (!url) throw new Error('Chyba vlastnost DISCORD_WEBHOOK');
  UrlFetchApp.fetch(url, { method: 'post', contentType: 'application/json', payload: JSON.stringify({ username: 'Echo Run', content: '🎮 Echo Run rating is connected to this channel.' }) });
}
