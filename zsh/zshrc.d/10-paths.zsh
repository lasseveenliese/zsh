# ~/.zshrc.d/10-paths.zsh
# Pfade und Tool-Integrationen

# LM Studio CLI
export PATH="$PATH:$HOME/.cache/lm-studio/bin"

# Bun: Completions laden und Binärpfad voranstellen
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export PATH="$HOME/.bun/bin:$PATH"

# npm: globales bin voranstellen
if command -v npm >/dev/null 2>&1; then
  : "${NPM_GLOBAL_BIN:=$(npm prefix -g 2>/dev/null)/bin}"
  [ -n "$NPM_GLOBAL_BIN" ] && export PATH="$NPM_GLOBAL_BIN:$PATH"
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
