# YNZ SQL Tools

Extensao pequena para usar no VS Code junto com `VSCodeVim`, sem depender de `nvim.exe`.

Ela porta funcionalidades da config de Neovim:

- `YNZ SQL: Format PL/SQL`
- `YNZ SQL: SVL Union`
- `YNZ SQL: Apolices Por Analista`
- `YNZ SQL: Apolices Por Analista Hoje`
- `YNZ SQL: PL/SQL Definition`
- hover local simples para algumas palavras-chave PL/SQL

## Como Instalar Sem Build

Copie esta pasta inteira para:

```text
C:\Users\SEU_USUARIO\.vscode\extensions\ynz-sql-tools
```

Depois reinicie o VS Code.

## Config Do VSCodeVim

No `settings.json` do VS Code:

```json
{
  "vim.leader": "<space>",
  "vim.normalModeKeyBindingsNonRecursive": [
    {
      "before": ["<leader>", "f"],
      "commands": ["ynzSqlTools.formatPlsql"]
    },
    {
      "before": ["<leader>", "s", "v"],
      "commands": ["ynzSqlTools.sqlSvlUnion"]
    },
    {
      "before": ["<leader>", "p", "a"],
      "commands": ["ynzSqlTools.sqlApolicesAnalista"]
    },
    {
      "before": ["<leader>", "p", "h"],
      "commands": ["ynzSqlTools.sqlApolicesAnalistaToday"]
    },
    {
      "before": ["g", "d"],
      "commands": ["ynzSqlTools.plsqlDefinition"]
    }
  ]
}
```

Se o `ferramentasSql` nao estiver em `Documents\ferramentasSql`, configure:

```json
{
  "ynzSqlTools.ferramentasSqlRoot": "C:\\Users\\SEU_USUARIO\\Documents\\ferramentasSql"
}
```

## Limite

`PlsqlCheck` nao foi portado aqui porque depende de `sql`, `sqlcl` ou `sqlplus` executavel no Windows.
