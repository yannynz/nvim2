const fs = require("fs");
const os = require("os");
const path = require("path");
const vscode = require("vscode");

const keywordDocs = {
  begin: "Abre um bloco executavel PL/SQL.",
  "bulk collect": "Carrega varias linhas em colecoes em uma unica operacao.",
  case: "Estrutura condicional por expressoes ou predicados.",
  cursor: "Cursor explicito para percorrer resultados de consulta.",
  declare: "Abre a secao de declaracao de um bloco anonimo.",
  elsif: "Ramo condicional intermediario dentro de IF.",
  exception: "Secao de tratamento de erros do bloco.",
  "execute immediate": "Executa SQL ou PL/SQL dinamico.",
  forall: "Executa DML em lote sobre colecoes.",
  function: "Subprograma que retorna valor.",
  loop: "Estrutura de repeticao.",
  package: "Agrupa especificacao e implementacao de objetos PL/SQL.",
  pragma: "Diretiva para o compilador PL/SQL.",
  procedure: "Subprograma sem retorno direto.",
  raise: "Dispara uma excecao.",
  record: "Tipo composto com campos nomeados.",
  rowtype: "Tipo baseado na estrutura de uma linha de tabela ou cursor.",
  trigger: "Rotina executada por evento de banco."
};

const analystAliases = {
  EMPURRADOR: "EMPURRADOR",
  YANN: "Yann",
  NATTACHA: "NATTACHA",
  OPERACOESPEND: "OPERACOES-PEND",
  JOCELIOPEND: "JocelioPend"
};

const svlOrder = ["SVL502", "SVL503", "SVL505", "SVL509"];
const svlTables = {
  SVL502: "tron2000.a2109435_vcr",
  SVL503: "tron2000.a2109393_vcr",
  SVL505: "tron2000.a2109457_vcr",
  SVL509: "tron2000.a2109406_vcr"
};

function trimRight(line) {
  return line.replace(/\s+$/u, "");
}

function isBlank(line) {
  return /^\s*$/u.test(line);
}

function isSqlplusExecuteLine(line) {
  return /^\s*\/\s*$/u.test(line);
}

function decreaseBefore(line) {
  const upper = line.toUpperCase();
  return /^\s*END[\s;]/u.test(upper)
    || /^\s*EXCEPTION\s*$/u.test(upper)
    || /^\s*ELSE\s*$/u.test(upper)
    || /^\s*ELSIF\s+/u.test(upper)
    || /^\s*WHEN\s+.*\s+THEN\s*$/u.test(upper);
}

function increaseAfter(line) {
  const upper = line.toUpperCase();
  if (/^\s*(DECLARE|BEGIN|EXCEPTION|ELSE)\s*$/u.test(upper)) return true;
  if (/^\s*ELSIF\s+.*\s+THEN\s*$/u.test(upper)) return true;
  if (/^\s*WHEN\s+.*\s+THEN\s*$/u.test(upper)) return true;
  if (/\bLOOP\b\s*$/u.test(upper)) return true;
  if (/\bTHEN\b\s*$/u.test(upper)) return true;
  if ((/^\s*CASE\s+/u.test(upper) || /^\s*CASE\s*$/u.test(upper)) && !/\bEND\b/u.test(upper)) return true;
  if (/^\s*CREATE\s+OR\s+REPLACE\s+PACKAGE\s+BODY\s+[\w_$#]+\s+AS\s*$/u.test(upper)) return true;
  if (/^\s*CREATE\s+OR\s+REPLACE\s+PACKAGE\s+[\w_$#]+\s+AS\s*$/u.test(upper)) return true;
  if (/^\s*CREATE\s+OR\s+REPLACE\s+FUNCTION\s+[\w_$#]+/u.test(upper) && /\s+(IS|AS)\s*$/u.test(upper)) return true;
  if (/^\s*CREATE\s+OR\s+REPLACE\s+PROCEDURE\s+[\w_$#]+/u.test(upper) && /\s+(IS|AS)\s*$/u.test(upper)) return true;
  return false;
}

function reindent(text, shiftWidth) {
  const lines = text.split(/\r?\n/u);
  const formatted = [];
  let indent = 0;

  for (const original of lines) {
    const line = trimRight(original);
    if (isBlank(line)) {
      formatted.push("");
      continue;
    }
    if (isSqlplusExecuteLine(line)) {
      formatted.push("/");
      continue;
    }

    let current = indent;
    if (decreaseBefore(line)) current = Math.max(indent - 1, 0);
    formatted.push(" ".repeat(current * shiftWidth) + line.trim());
    indent = current;
    if (increaseAfter(line)) indent += 1;
  }

  return formatted.join("\n");
}

function fullDocumentRange(document) {
  const lastLine = document.lineAt(document.lineCount - 1);
  return new vscode.Range(new vscode.Position(0, 0), lastLine.range.end);
}

async function replaceDocumentText(editor, text) {
  await editor.edit((edit) => edit.replace(fullDocumentRange(editor.document), text));
}

async function formatActivePlsql() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) return;
  const tabSize = Number(editor.options.tabSize) || 4;
  await replaceDocumentText(editor, reindent(editor.document.getText(), tabSize));
}

function collectSvl(lines) {
  const svlMap = Object.fromEntries(svlOrder.map((name) => [name, []]));
  const seen = Object.fromEntries(svlOrder.map((name) => [name, new Set()]));
  let blockLines = [];
  let blockDepth = 0;

  function addClause(svlName, poliza, spto) {
    const clause = `( a.num_poliza = '${poliza}' AND A.NUM_SPTO = ${spto} )`;
    if (!seen[svlName].has(clause)) {
      seen[svlName].add(clause);
      svlMap[svlName].push(clause);
    }
  }

  function processBlock(block) {
    const lowerText = block.join("\n").toLowerCase();
    const targets = svlOrder.filter((name) => lowerText.includes(svlTables[name]));
    if (targets.length === 0) return;

    for (const line of block) {
      const lower = line.toLowerCase();
      let match = lower.match(/num_poliza\s*=\s*'([^']+)'\s*and\s*[a-z_][\w_]*\.?num_spto\s*=\s*([0-9]+)/u);
      if (!match) match = lower.match(/num_poliza\s*=\s*'([^']+)'\s*and\s*num_spto\s*=\s*([0-9]+)/u);
      if (!match) continue;
      for (const target of targets) addClause(target, match[1], match[2]);
    }
  }

  for (const line of lines) {
    const lower = line.toLowerCase();
    const beginCount = (lower.match(/\bbegin\b/gu) || []).length;
    const endCount = (lower.match(/\bend\b\s*;/gu) || []).length;

    if (beginCount > 0 && blockDepth === 0) blockLines = [];
    if (blockDepth > 0 || beginCount > 0) blockLines.push(line);

    blockDepth += beginCount - endCount;
    if (blockDepth === 0 && blockLines.length > 0) {
      processBlock(blockLines);
      blockLines = [];
    }
  }

  return svlMap;
}

function renderSvl(svlMap) {
  const lines = [];
  svlOrder.forEach((name, sectionIndex) => {
    lines.push(name);
    const items = svlMap[name] || [];
    if (items.length === 0) {
      lines.push("-- nenhum registro encontrado");
    } else {
      items.forEach((item, index) => lines.push(item + (index < items.length - 1 ? " OR" : "")));
    }
    if (sectionIndex < svlOrder.length - 1) lines.push("");
  });
  return lines.join("\n");
}

async function sqlSvlUnion() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) return;
  const result = renderSvl(collectSvl(editor.document.getText().split(/\r?\n/u)));
  const doc = await vscode.workspace.openTextDocument({ content: result, language: "sql" });
  await vscode.window.showTextDocument(doc, { preview: false });
}

function normalizeSpace(value) {
  return String(value || "").replace(/\u00a0/gu, " ").replace(/&nbsp;/giu, " ").replace(/\s+/gu, " ").trim();
}

function normalizeAnalystName(value) {
  const cleaned = normalizeSpace(value).replace(/_/gu, "-");
  if (!cleaned) return "SEM_ANALISTA";
  const aliasKey = cleaned.toUpperCase().replace(/[^A-Z0-9]+/gu, "");
  return analystAliases[aliasKey] || cleaned;
}

function extractCells(rowHtml) {
  const cells = [];
  for (const match of rowHtml.matchAll(/<T[DdHh][^>]*>(.*?)<\/T[DdHh]>/gsu)) {
    cells.push(normalizeSpace(match[1].replace(/<[^>]+>/gu, "")));
  }
  return cells;
}

function parseHtmlText(text) {
  const rowsByAnalyst = new Map();
  const currentPolicies = new Set();

  for (const match of text.matchAll(/<[Tt][Rr][^>]*>(.*?)<\/[Tt][Rr]>/gsu)) {
    const cells = extractCells(match[1]);
    if (cells.length >= 16 && cells[0] !== "TIPO_SVL") {
      const analyst = normalizeAnalystName(cells[15]);
      if (!rowsByAnalyst.has(analyst)) rowsByAnalyst.set(analyst, new Set());
      rowsByAnalyst.get(analyst).add(cells[4]);
      currentPolicies.add(cells[4]);
    }
  }

  return { rowsByAnalyst, currentPolicies };
}

function normalizeDateToken(raw) {
  if (!raw) {
    const now = new Date();
    return `${String(now.getDate()).padStart(2, "0")}${String(now.getMonth() + 1).padStart(2, "0")}${String(now.getFullYear()).slice(-2)}`;
  }
  const digits = String(raw).replace(/\D/gu, "");
  if (digits.length === 8) return `${digits.slice(0, 2)}${digits.slice(2, 4)}${digits.slice(6, 8)}`;
  if (digits.length === 6) return digits;
  return null;
}

function getFerramentasSqlRoot() {
  const configured = vscode.workspace.getConfiguration("ynzSqlTools").get("ferramentasSqlRoot");
  if (configured) return configured;
  if (process.env.FERRAMENTAS_SQL_ROOT) return process.env.FERRAMENTAS_SQL_ROOT;
  return path.join(os.homedir(), "Documents", "ferramentasSql");
}

function walkFiles(dir, predicate, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) walkFiles(fullPath, predicate, out);
    else if (predicate(fullPath)) out.push(fullPath);
  }
  return out;
}

function sorted(values) {
  return [...values].sort((a, b) => a.localeCompare(b));
}

function collectSqlPaths(projectRoot, token) {
  const candidates = [];
  const lotesDir = path.join(projectRoot, "consultas", "lotesDiarios");
  const errosDir = path.join(projectRoot, "dados", "errosDiariosHtml");

  candidates.push(...walkFiles(lotesDir, (file) => /^query.*\.sql$/iu.test(path.basename(file))));
  candidates.push(...walkFiles(errosDir, (file) => /^inserts.*\.sql$/iu.test(path.basename(file))));
  candidates.push(...walkFiles(errosDir, (file) => file.includes(token) && /\.sql$/iu.test(file)));
  return sorted(new Set(candidates));
}

function policiesPresentInSql(sqlPaths, currentPolicies) {
  const inSql = new Set();
  for (const sqlPath of sqlPaths) {
    let text = "";
    try {
      text = fs.readFileSync(sqlPath, "utf8");
    } catch (_) {
      continue;
    }
    for (const match of text.matchAll(/'(\d{12,13})'/gu)) {
      if (currentPolicies.has(match[1])) inSql.add(match[1]);
    }
  }
  return inSql;
}

function renderApolices(htmlPath, rowsByAnalyst, policiesInSql) {
  const lines = [`BASE_HTML: ${path.basename(htmlPath)}`, ""];
  for (const analyst of sorted(rowsByAnalyst.keys())) {
    lines.push(`ANALISTA: ${analyst}`);
    for (const policy of sorted(rowsByAnalyst.get(analyst))) {
      if (policiesInSql.has(policy)) lines.push(`'${policy}',`);
      else lines.push(`'${policy}', -- OBS: marcada no HTML, mas nao encontrada em nenhum .sql`);
    }
    lines.push("");
  }
  return lines.join("\n");
}

async function sqlApolicesAnalista(requestedToken, shouldPrompt) {
  let tokenInput = requestedToken;
  if (shouldPrompt) {
    tokenInput = await vscode.window.showInputBox({
      prompt: "Data do HTML de erros. Vazio usa hoje.",
      placeHolder: "DDMMYY ou DD/MM/YYYY"
    });
    if (tokenInput === undefined) return;
  }

  const projectRoot = getFerramentasSqlRoot();
  const token = normalizeDateToken(tokenInput);
  if (!token) {
    vscode.window.showWarningMessage("Data invalida; use DDMMYY ou DD/MM/YYYY.");
    return;
  }

  const htmlPath = path.join(projectRoot, "dados", "errosDiariosHtml", `erros${token}.html`);
  if (!fs.existsSync(htmlPath)) {
    const doc = await vscode.workspace.openTextDocument({
      content: `-- HTML de erros nao encontrado para a data ${token}\n-- Caminho: ${htmlPath}`,
      language: "plaintext"
    });
    await vscode.window.showTextDocument(doc, { preview: false });
    return;
  }

  const htmlText = fs.readFileSync(htmlPath, "utf8");
  const { rowsByAnalyst, currentPolicies } = parseHtmlText(htmlText);
  const policiesInSql = policiesPresentInSql(collectSqlPaths(projectRoot, token), currentPolicies);
  const doc = await vscode.workspace.openTextDocument({
    content: renderApolices(htmlPath, rowsByAnalyst, policiesInSql),
    language: "plaintext"
  });
  await vscode.window.showTextDocument(doc, { preview: false });
}

function wordAt(document, position) {
  const range = document.getWordRangeAtPosition(position, /[\w$#]+/u);
  return range ? document.getText(range) : "";
}

async function plsqlDefinition() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) return;
  const target = wordAt(editor.document, editor.selection.active).toLowerCase();
  if (!target) return;

  const pattern = new RegExp(`\\bcreate\\s+or\\s+replace\\s+(package\\s+body|package|procedure|function|trigger|type\\s+body|type)\\s+${target}\\b|\\b(procedure|function)\\s+${target}\\b`, "iu");
  const files = await vscode.workspace.findFiles("**/*.{sql,pls,plb,pks,pkb,prc,fnc,trg,tps,tpb}", "**/{node_modules,.git}/**", 1000);
  const hits = [];

  for (const uri of files) {
    let text = "";
    try {
      text = fs.readFileSync(uri.fsPath, "utf8");
    } catch (_) {
      continue;
    }
    const lines = text.split(/\r?\n/u);
    lines.forEach((line, index) => {
      if (pattern.test(line)) hits.push({ uri, line: index, text: line.trim() });
    });
  }

  if (hits.length === 0) {
    vscode.window.showWarningMessage(`Definicao de '${target}' nao encontrada.`);
    return;
  }

  const hit = hits[0];
  const doc = await vscode.workspace.openTextDocument(hit.uri);
  const shown = await vscode.window.showTextDocument(doc, { preview: false });
  const pos = new vscode.Position(hit.line, 0);
  shown.selection = new vscode.Selection(pos, pos);
  shown.revealRange(new vscode.Range(pos, pos), vscode.TextEditorRevealType.InCenter);
}

function provideHover(document, position) {
  const word = wordAt(document, position).toLowerCase();
  const doc = keywordDocs[word];
  if (!doc) return undefined;
  return new vscode.Hover(`**${word.toUpperCase()}** - ${doc}`);
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand("ynzSqlTools.formatPlsql", formatActivePlsql),
    vscode.commands.registerCommand("ynzSqlTools.sqlSvlUnion", sqlSvlUnion),
    vscode.commands.registerCommand("ynzSqlTools.sqlApolicesAnalista", (token) => sqlApolicesAnalista(token, true)),
    vscode.commands.registerCommand("ynzSqlTools.sqlApolicesAnalistaToday", () => sqlApolicesAnalista(undefined, false)),
    vscode.commands.registerCommand("ynzSqlTools.plsqlDefinition", plsqlDefinition),
    vscode.languages.registerDocumentFormattingEditProvider(["sql", "plsql"], {
      provideDocumentFormattingEdits(document, options) {
        return [vscode.TextEdit.replace(fullDocumentRange(document), reindent(document.getText(), Number(options.tabSize) || 4))];
      }
    }),
    vscode.languages.registerHoverProvider(["sql", "plsql"], { provideHover })
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
