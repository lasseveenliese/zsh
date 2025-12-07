# ~/.zshrc.d/20-completion.zsh
# Zsh-Completion-System und zusätzliche Completion-Pfade

# Basisverzeichnis für Plugins (wird auch in 50-plugins.zsh genutzt)
ZSH_PLUGINS="${ZSH_PLUGINS:-$HOME/.zsh-plugins}"

# Docker CLI: zusätzliche Completion-Dateien
if [ -d "$HOME/.docker/completions" ]; then
  fpath=("$HOME/.docker/completions" $fpath)
fi

# zsh-completions aus Plugin-Ordner
if [ -d "$ZSH_PLUGINS/zsh-completions" ]; then
  fpath=("$ZSH_PLUGINS/zsh-completions/src" $fpath)
fi

# Doppelte Einträge aus PATH und fpath entfernen
typeset -gU PATH fpath

# Completion-System initialisieren (mit Cache)
autoload -Uz compinit
compinit -C
