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

## Atalhos Principais

`Leader` = `Espaço`

- `<leader><leader>` abre o explorador de arquivos
- `<space>pf` busca arquivos
- `<space>ps` faz busca por texto no projeto
- `<leader>e` abre diagnósticos do buffer
- `<leader>f` formata via LSP
- `<leader>gg` abre o Git
- `<leader>a` adiciona arquivo no Harpoon
- `<C-e>` abre o menu do Harpoon
- `<leader><C-i>` abre o terminal flutuante
- `<leader>k` salva todos os buffers

## Observações

- O setup é mais completo do que minimalista: ele tenta preparar tooling para várias linguagens.
- No Windows e no Linux o terminal flutuante escolhe o shell automaticamente.
- Se você quiser um setup mais enxuto, o melhor caminho é remover do `lsp.lua` as linguagens que você não usa.
