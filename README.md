# nvim2

Config pessoal de Neovim com foco em produtividade no dia a dia:

- LSP e autocomplete prontos
- Git integrado
- busca com Telescope
- explorador de arquivos com Oil
- Treesitter
- terminal flutuante
- suporte para Java, C#, JS/TS, Lua, Python, Go, Docker, YAML, Flutter e mais

## Versão De Referência

Versão usada aqui no ambiente atual:

- Linux: `NVIM v0.11.4`
- Windows: a recomendação é usar `NVIM v0.11.4` também, para ficar alinhado com esta config

## O Que Já Vem Configurado

- `lazy.nvim` para gerenciar plugins
- `mason.nvim` para instalar LSPs, formatters, linters e DAPs
- `blink.cmp` + Copilot para autocomplete
- `telescope.nvim` para arquivos e busca global
- `gitsigns.nvim` + `vim-fugitive` para Git
- `trouble.nvim` para diagnósticos
- `harpoon` para navegação rápida
- `nvim-treesitter` para highlight e parsing

## Requisitos

### Obrigatórios

- `git`
- `neovim >= 0.11`

### Recomendados

- `ripgrep` para o `live grep` do Telescope
- `fd` para buscas mais rápidas no Telescope
- compilador C/C++ para parsers do Treesitter em alguns ambientes

### Opcionais Por Linguagem

Se você usa essas stacks, vale ter as runtimes no `PATH`:

- `node` para várias ferramentas web, LSPs e Copilot
- `java` para Java/JDTLS
- `go` para Go e parte das ferramentas do Mason
- `python` para ferramentas Python
- `flutter` / `dart` para Flutter
- `.NET` para C#
- `sql`, `sqlcl` ou `sqlplus` se quiser validação real de PL/SQL Oracle

Sem isso, o Neovim abre normal, mas algumas instalações do Mason podem ser puladas ou gerar aviso.

## Instalação No Linux

Referência recomendada para esta repo: `NVIM v0.11.4`.

Instale os pacotes básicos da sua distro. Exemplo no Debian/Ubuntu:

```bash
sudo apt update
sudo apt install -y git neovim ripgrep fd-find curl unzip gcc
```

Depois clone a config:

```bash
git clone https://github.com/yannynz/nvim2.git ~/.config/nvim
```

Abra o Neovim:

```bash
nvim
```

Na primeira abertura, o `lazy.nvim` instala os plugins e o `Mason` começa a instalar ferramentas.

## Instalação No Windows

Sim, dá para usar no Windows nativo.

Referência recomendada para esta repo: `NVIM v0.11.4`.

### O Que Vale Instalar Antes

- `Git`
- `Neovim 0.11+`
- `ripgrep`
- `fd` opcional
- `Node.js` se quiser aproveitar Copilot e tooling web

Depois clone a config no diretório padrão do Neovim:

```powershell
git clone https://github.com/yannynz/nvim2.git "$env:LOCALAPPDATA\nvim"
```

Abra o Neovim:

```powershell
nvim
```

Na primeira abertura, os plugins serão instalados automaticamente.

## Windows Em Máquina Bloqueada

Se a máquina bloqueia instalador `.msi`, `Program Files` ou alteração global de `PATH`, o pulo do gato é usar o Neovim portátil.

### Como Fazer

1. Baixe a versão `.zip` do Neovim `v0.11.4`.
2. Extraia em uma pasta do usuário, por exemplo:

```powershell
$env:LOCALAPPDATA\nvim-win64
```

3. Clone esta config:

```powershell
git clone https://github.com/yannynz/nvim2.git "$env:LOCALAPPDATA\nvim"
```

4. Rode o Neovim direto pelo executável:

```powershell
& "$env:LOCALAPPDATA\nvim-win64\bin\nvim.exe"
```

### Se Não Der Para Mexer No PATH

Você pode criar um atalho simples no seu usuário.

Crie a pasta:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\bin"
```

Crie o arquivo `nvim.cmd` dentro de `%USERPROFILE%\bin` com este conteúdo:

```bat
@echo off
"%LOCALAPPDATA%\nvim-win64\bin\nvim.exe" %*
```

Se essa pasta já estiver no seu `PATH`, basta rodar:

```powershell
nvim
```

Se não estiver, ainda dá para chamar assim:

```powershell
& "$env:USERPROFILE\bin\nvim.cmd"
```

### Limite Real

Se a máquina bloquear a execução do `nvim.exe` por AppLocker, Defender ou whitelist de binários, aí não existe contorno limpo pela config. Nesse caso precisa pedir liberação para o TI.

## Pós-Instalação

Se quiser conferir se está tudo certo:

```vim
:checkhealth
:Mason
```

Se algum LSP ou formatter falhar, normalmente é falta da runtime da linguagem no `PATH`.

## Suporte A PL/SQL Oracle

Esta config agora tem uma camada local para PL/SQL que nao depende de LSP real para ficar utilizavel em maquina travada.

### O Que Funciona Sem Instalar LSP

- detecta extensoes Oracle como `.pks`, `.pkb`, `.pls`, `.plb`, `.prc`, `.fnc`, `.trg`, `.tps` e `.tpb` como `plsql`
- tenta promover `.sql` para `plsql` quando o conteudo parecer Oracle
- ativa formatter local para reindentar blocos `DECLARE/BEGIN/EXCEPTION/END`
- ativa `gd` para procurar definicao local ou no workspace
- ativa `gH` para hover basico de palavras-chave PL/SQL
- ativa omni completion via `syntaxcomplete`

### O Que Funciona Se Houver Cliente Oracle No PATH

Se existir `sql`, `sqlcl` ou `sqlplus`, voce ganha validacao do buffer atual com:

- `<leader>pc`
- `:PlsqlCheck`

Para isso, defina uma conexao em variavel de ambiente:

```bash
export PLSQL_CONNECT_STRING='usuario/senha@host:1521/servico'
```

Ou:

```bash
export ORACLE_CONNECT_STRING='usuario/senha@host:1521/servico'
```

### Limite Real

Isso melhora bastante a experiencia no Neovim, mas nao substitui um LSP Oracle completo. A parte de formatacao, navegacao e hover roda localmente; compilacao e erros reais dependem de `sqlcl/sqlplus`.

## Atalhos E Comandos

Esta seção lista os atalhos que esta config adiciona ou sobrescreve. O resto continua seguindo o comportamento normal do Neovim.

### Convenções

- `Leader` = `Espaço`
- `Alt` e `Meta` são a mesma coisa aqui: `<A-x>` = `<M-x>`
- Letras maiúsculas como `H`, `J`, `K`, `L`, `S` significam `Shift` + letra

### Arquivos, Busca E Diagnóstico

- `<leader><leader>` abre o explorador de arquivos com `Oil`
- `<space>pf` busca arquivos com `Telescope`
- `<space>ps` faz busca por texto no projeto com `Telescope live_grep`
- `<leader>e` abre os diagnósticos do buffer atual com `Trouble`
- `<leader>pe` abre a lista de diagnósticos no `Telescope`
- `<leader>cn` copia para a área de transferência apenas o nome do arquivo atual

### Navegação E Movimento

- `H` volta para o começo da palavra anterior
- `L` vai até o fim da palavra atual ou da próxima palavra
- `K` sobe para o bloco/parágrafo anterior
- `J` desce para o próximo bloco/parágrafo
- `n` vai para a próxima busca e centraliza a tela
- `N` vai para a busca anterior e centraliza a tela
- `<C-d>` desce meia página e centraliza a tela
- `<C-u>` sobe meia página e centraliza a tela
- `s` ativa o `Leap` para saltar para frente
- `S` ativa o `Leap` para saltar para trás
- `gs` ativa o `Leap` entre janelas
- Em modo visual ou operador: `x` faz `Leap` até antes do alvo para frente
- Em modo visual ou operador: `X` faz `Leap` até antes do alvo para trás

### Edição De Texto

- Em modo visual: `J` move a seleção uma linha para baixo e reindenta
- Em modo visual: `K` move a seleção uma linha para cima e reindenta
- `<leader>j` junta a linha atual com a próxima sem perder a posição do cursor
- `<leader>p` cola por cima da seleção sem destruir o registrador padrão
- `<leader>y` copia para a área de transferência do sistema
- `<leader>Y` copia a linha atual para a área de transferência do sistema
- `<leader>s` já abre a substituição da palavra sob o cursor no arquivo inteiro
- Em modo visual: `<` diminui a indentação e mantém a seleção
- Em modo visual: `>` aumenta a indentação e mantém a seleção

### Duplicação E Indentação Rápida

- Em modo normal: `<A-J>` duplica a linha atual para baixo
- Em modo normal: `<A-K>` duplica a linha atual para cima
- Em modo normal: `<A-H>` remove indentação da linha atual
- Em modo normal: `<A-L>` adiciona indentação à linha atual
- Em modo visual: `<A-J>` duplica o bloco selecionado para baixo
- Em modo visual: `<A-K>` duplica o bloco selecionado para cima
- Em modo visual: `<A-H>` remove indentação da seleção
- Em modo visual: `<A-L>` adiciona indentação à seleção

### Janelas, Quickfix E Scroll Horizontal

- `<leader>w` envia o prefixo de janelas do Neovim (`<C-w>`). Exemplo: `<leader>wv`, `<leader>ws`, `<leader>wh`
- `<Up>` diminui a altura da janela atual
- `<Down>` aumenta a altura da janela atual
- `<Left>` diminui a largura da janela atual
- `<Right>` aumenta a largura da janela atual
- `<C-f>` vai para o próximo item da quickfix
- `<C-b>` volta para o item anterior da quickfix
- `<leader><C-L>` desloca horizontalmente a visualização para a direita
- `<leader><C-H>` desloca horizontalmente a visualização para a esquerda

### Salvar, Sair E Prompt

- `<leader>k` salva todos os buffers
- `<M-s>` salva todos os buffers
- `<M-q>` fecha o Neovim inteiro
- `<M-t>` abre o prompt de comando `:`
- `<M-m>` abre o `Mason`

### Terminal Flutuante

- Em modo normal: `<leader><C-i>` abre ou fecha o terminal flutuante
- Em modo terminal: `<leader><C-i>` fecha o terminal flutuante
- Em modo terminal: `<leader>q` sai do modo terminal e volta para o modo normal
- Em modo terminal: `<Tab>` insere um `Tab` literal dentro do shell

### Git

- `<leader>gg` abre o `vim-fugitive` com `:Git`
- `<leader>gp` roda `:Git pull`
- `<leader>gl` liga ou desliga o blame da linha atual com `Gitsigns`
- `<leader>gld` liga ou desliga diff por palavra, linhas deletadas e destaque de linha com `Gitsigns`

### Harpoon

- `<leader>a` adiciona o arquivo atual à lista do `Harpoon`
- `<C-e>` abre ou fecha o menu rápido do `Harpoon`
- `<C-j>` abre o item 1 do `Harpoon`
- `<C-k>` abre o item 2 do `Harpoon`
- `<C-l>` abre o item 3 do `Harpoon`
- `<C-m>` abre o item 4 do `Harpoon`

### Multicursor

- `<C-A-j>` adiciona um cursor na linha de baixo
- `<C-A-k>` adiciona um cursor na linha de cima
- `<C-A-l>` adiciona cursor na próxima ocorrência do texto
- `<C-A-h>` adiciona cursor na ocorrência anterior
- Em modo visual: `I` insere no começo de todas as linhas selecionadas
- Em modo visual: `A` adiciona no fim de todas as linhas selecionadas
- Depois de criar os cursores, use `i` ou `a` normalmente para editar em todos ao mesmo tempo
- `<Esc>` limpa os cursores extras e volta para um cursor só

### LSP

Esses atalhos só existem no buffer quando um servidor LSP está anexado.

- `gd` vai para a definição
- `gD` vai para a declaração
- `gi` vai para a implementação
- `gr` lista referências
- `gH` abre o hover/documentação do símbolo
- `<C-k>` mostra a assinatura da função
- `<leader>rn` renomeia símbolo
- `<leader>ca` abre code actions
- `<leader>f` formata o buffer via LSP

### PL/SQL Oracle

Em buffers `plsql` ou `sql` sem LSP Oracle:

- `gd` procura a definicao do simbolo no buffer atual e depois no workspace
- `gH` abre um hover curto para palavras-chave PL/SQL conhecidas
- `<leader>f` formata o buffer com o formatter local de PL/SQL
- `<leader>pc` valida o buffer via `sql`, `sqlcl` ou `sqlplus`, se configurado
- `:PlsqlFormat` formata o buffer atual
- `:PlsqlCheck` valida o buffer atual usando a conexao Oracle configurada
- `:PlsqlDefinition` procura a definicao do simbolo atual

### DAP Debug

- `<F5>` continua a execução
- `<F10>` step over
- `<F11>` step into
- `<F12>` step out
- `<leader>b` alterna breakpoint

### Autocomplete E Copilot

O `blink.cmp` está com o preset `enter`, então em modo insert:

- `<CR>` aceita o item selecionado da autocomplete
- `<C-space>` abre o menu de autocomplete e alterna a documentação
- `<C-e>` cancela o menu de autocomplete
- `<Up>` e `<Down>` navegam na lista de sugestões
- `<C-p>` e `<C-n>` navegam na lista de sugestões
- `<C-b>` e `<C-f>` rolam a documentação da sugestão
- `<C-k>` mostra ou esconde a assinatura
- `<S-Tab>` volta no snippet

O comportamento de `Copilot` em modo insert ficou assim:

- `<Tab>` avança snippet quando houver snippet ativo; se houver sugestão visível do Copilot, aceita a sugestão; caso contrário insere `Tab`
- `<C-l>` aceita a sugestão inteira do Copilot
- `<C-\>` aceita só a próxima palavra do Copilot
- `<C-|>` aceita só a próxima linha do Copilot

### Comandos Customizados

- `:SqlSvlUnion` lê o buffer SQL atual e abre um novo buffer com os filtros consolidados de `SVL502`, `SVL503`, `SVL505` e `SVL509`
- `:SqlApolicesAnalista` usa por padrão a data de hoje para localizar `errosDDMMYY.html`, cruza com os lotes SQL e lista as apólices agrupadas por analista no formato `'apolice',`
- `:SqlApolicesAnalista 220426` faz a mesma consulta para uma data específica
- `:SqlApolicesAnalista 22/04/2026` também aceita data com barras

### Notas Importantes Sobre Sobrescritas

- `J` e `K` em modo normal foram redefinidos para navegação por bloco. Para juntar linhas, use `<leader>j`
- `K` não abre mais hover do LSP. O hover agora fica em `gH`
- Em buffers com LSP, o `<C-k>` do LSP tem prioridade sobre o `<C-k>` global do Harpoon
- O `s` padrão do Vim foi trocado pelo `Leap`. Se você era acostumado a usar `s` para substituir um caractere, esse comportamento mudou

## Observações

- O setup é mais completo do que minimalista: ele tenta preparar tooling para várias linguagens.
- No Windows e no Linux o terminal flutuante escolhe o shell automaticamente.
- Os atalhos com `Alt` e `Ctrl+Alt` funcionam no Windows e no Linux, mas dependem do terminal ou GUI repassar essas combinações para o Neovim. Se o terminal, o gerenciador de janelas ou o sistema interceptarem o atalho, basta liberar ou remapear fora do Neovim.
- Se você quiser um setup mais enxuto, o melhor caminho é remover do `lsp.lua` as linguagens que você não usa.
- Para ter uma máquina “capada” sem mexer no setup principal, crie `lua/config/local.lua` baseado em `lua/config/local.example.lua` e deixe só os LSPs/tools/DAPs que quer manter.
