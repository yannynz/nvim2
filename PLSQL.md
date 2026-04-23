# PL/SQL No Neovim

Guia rapido para usar PL/SQL Oracle nesta config, inclusive em maquina travada.

## O Que Ja Funciona

Sem depender de um LSP Oracle completo, esta config ja entrega:

- reconhecimento de arquivos Oracle como `plsql`
- formatter local para reindentar blocos PL/SQL
- `gd` para procurar definicao no buffer e no workspace
- `gH` para hover basico de palavras-chave
- `:PlsqlCheck` para validar o buffer atual via cliente Oracle, se houver

## Extensoes Reconhecidas

As extensoes abaixo sao tratadas como `plsql`:

- `.sql`
- `.pls`
- `.plb`
- `.pks`
- `.pkb`
- `.prc`
- `.fnc`
- `.trg`
- `.tps`
- `.tpb`

Arquivos `.sql` tambem podem ser promovidos para `plsql` quando o conteudo parecer Oracle, por exemplo com `CREATE OR REPLACE PACKAGE`, `PROCEDURE`, `FUNCTION`, `TRIGGER` ou bloco `DECLARE`.

## Formatacao E Navegacao

Nos buffers `plsql` ou `sql`:

- `<leader>f` formata o buffer atual
- `:PlsqlFormat` formata o buffer atual
- `gd` procura a definicao do simbolo atual
- `gH` abre um hover curto para palavras-chave conhecidas
- `:PlsqlDefinition` procura a definicao do simbolo atual

## Da Para Logar Na Base Pelo Neovim?

Da, mas usando um cliente Oracle externo rodando dentro ou ao lado do Neovim.

Os clientes aceitos pela config sao:

- `sql`
- `sqlcl`
- `sqlplus`

Se um deles estiver no `PATH`, o Neovim consegue usar esse executavel para validar o SQL/PLSQL do buffer atual.

## Como Configurar A Conexao

Defina uma das variaveis abaixo no shell antes de abrir o Neovim:

```bash
export PLSQL_CONNECT_STRING='usuario/senha@host:1521/servico'
```

Ou:

```bash
export ORACLE_CONNECT_STRING='usuario/senha@host:1521/servico'
```

Exemplo real de formato:

```bash
export PLSQL_CONNECT_STRING='meu_usuario/minha_senha@10.0.0.15:1521/ORCL'
```

## Validando O Buffer Atual

Depois de abrir um arquivo PL/SQL no Neovim:

```vim
:PlsqlCheck
```

Ou use o atalho:

```text
<leader>pc
```

Esse comando:

- usa `sql`, `sqlcl` ou `sqlplus`
- conecta com a string definida no ambiente
- executa o buffer atual
- roda `show errors`
- abre o resultado na quickfix quando encontrar erro

Se nenhum cliente Oracle existir no `PATH`, o comando apenas avisa que nao ha cliente disponivel.

## Sessao Interativa Dentro Do Neovim

Se voce quiser abrir uma sessao manual na base pelo terminal embutido do Neovim, pode usar:

```vim
:terminal sql usuario/senha@host:1521/servico
```

Ou:

```vim
:terminal sqlcl usuario/senha@host:1521/servico
```

Ou:

```vim
:terminal sqlplus usuario/senha@host:1521/servico
```

Isso nao depende do `:PlsqlCheck`; e uma sessao interativa normal rodando dentro do terminal do Nvim.

## Limite Real

Isso melhora bastante a experiencia de PL/SQL no Neovim, mas nao vira um LSP Oracle completo.

Hoje o que esta coberto bem:

- filetype
- indentacao
- formatacao local
- navegacao basica
- hover basico
- validacao via cliente Oracle

O que ainda depende de tooling Oracle real:

- diagnostico sem conexao
- semantic completion de schema
- introspeccao profunda de objetos do banco
- experiencias equivalentes a SQL Developer ou extensao Oracle do VS Code

