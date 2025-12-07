# ~/.zshrc.d/30-aliases.zsh
# Aliase und kleine Komfortabkürzungen

# python = python3 (CLI-Komfort, Scripts sollten direkt python3 nutzen)
alias python='python3'

# Codex über API-Key-Konfiguration
alias codex-api='CODEX_HOME=$HOME/.codex-api codex -c preferred_auth_method=\"apikey\"'

# Moderne Ersatz-Tools, falls installiert

# ls -> eza
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lh --git --icons'
  alias la='eza -lha --git --icons'
  alias lt='eza --tree --level=2 --group-directories-first'
fi

# find -> fd
if command -v fd >/dev/null 2>&1; then
  alias f='fd'
  alias ff='fd --hidden --exclude .git'
fi

# grep -> ripgrep
if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
  alias rgi='rg -i'
fi

# du -> dust (oder ncdu manuell starten)
if command -v dust >/dev/null 2>&1; then
  alias du='dust'
fi
