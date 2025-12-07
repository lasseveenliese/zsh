# ~/.zshrc.d/50-plugins.zsh
# Plugin-Setup ohne Plugin-Manager (Verzeichnis: ~/.zsh-plugins)

# Basisverzeichnis für Plugins (falls nicht bereits gesetzt)
ZSH_PLUGINS="${ZSH_PLUGINS:-$HOME/.zsh-plugins}"

# 1) zsh-autosuggestions
# Vorschläge aus History in grau, Übernahme mit Pfeil rechts
if [ -d "$ZSH_PLUGINS/zsh-autosuggestions" ]; then
  # Konfiguration vor dem Laden setzen
  ZSH_AUTOSUGGEST_USE_ASYNC=1
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# 2) you-should-use
# Warnt, wenn du ein vorhandenes Alias statt des langen Befehls nutzen könntest
if [ -d "$ZSH_PLUGINS/zsh-you-should-use" ]; then
  source "$ZSH_PLUGINS/zsh-you-should-use/you-should-use.plugin.zsh"
fi

# 3) zsh-bat
# Ersetzt cat/man durch bat mit Syntax-Highlighting (erfordert 'bat' im PATH)
if [ -d "$ZSH_PLUGINS/zsh-bat" ]; then
  source "$ZSH_PLUGINS/zsh-bat/zsh-bat.plugin.zsh"
fi

# 4) zoxide Integration
# 'z <pattern>' springt in häufig genutzte Ordner
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# 5) fast-syntax-highlighting
# Befehlssyntax wird farbig hervorgehoben (immer spät laden)
if [ -d "$ZSH_PLUGINS/fast-syntax-highlighting" ]; then
  source "$ZSH_PLUGINS/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
fi
