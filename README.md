# Terminal-Setup & Befehlsübersicht

Dieses Repo richtet ein identisches Terminal-Setup ein: Zsh mit Plugins, Aliases/Funktionen, modernen CLI-Tools und Starship-Prompt.

## Schnellstart
- Einzeiler zum Klonen und Ausführen: `git clone https://github.com/lasseveenliese/zsh.git && cd zsh && chmod +x setup.sh && ./setup.sh`
- Danach neue Shell starten oder `exec zsh`.

## Was passiert bei `setup.sh`?
- OS-Erkennung: macOS (Homebrew) oder Linux (apt/apk/dnf/yum/pacman/zypper).
- Installiert Tools: eza, fd, ripgrep (`rg`), dust, zoxide (`z`), bat, certbot, bun, node/npm, pnpm, starship.
- Starship läuft mit dem Preset "Plain Text Symbols" (keine Nerd Font nötig).
- Klont Zsh-Plugins nach `~/.zsh-plugins`:
  - zsh-autosuggestions (Inline-History-Vorschläge)
  - zsh-you-should-use (Alias-Hinweise)
  - zsh-bat (bat-Integration)
  - fast-syntax-highlighting (Syntax-Hervorhebung)
  - zsh-completions (extra Completions)
- Sichert bestehende Shell-Dateien nach `~/.dotfile-backups/<timestamp>` und kopiert die versionierten Configs aus `zsh/` nach `~/.zshrc` und `~/.zshrc.d/`.
- Legt bei Bedarf einen Symlink `fdfind -> fd` auf Linux an.

## Zsh-Konfiguration (Versioniert in `zsh/`)
- `zsh/zshrc` lädt modulare Dateien unter `~/.zshrc.d/`.
- `zsh/zshrc.d/00-env.zsh`: Platz für EDITOR/LANG etc.
- `10-paths.zsh`: PATH-Erweiterungen (LM Studio, bun, npm global, pnpm).
- `20-completion.zsh`: compinit, Docker-Completions, zsh-completions.
- `30-aliases.zsh`: `ssh-new`, `python->python3`, `codex-api`, `ls/ll/la/lt -> eza`, `f/ff -> fd`, `grep/rgi -> rg`, `du -> dust`.
- `40-functions.zsh`: `gitpush`, `rmssh`, `ssl-cert-generate`.
- `50-plugins.zsh`: lädt die Plugin-Repos, zoxide-Init, Syntax-Highlighting.
- `starship/starship.toml`: Preset "Plain Text Symbols" (kopiert nach `~/.config/starship.toml`).

## Manuelle Anpassungen
- Optionale lokale Overrides: `~/.zshrc.local` (wird automatisch geladen, nicht versioniert).
- Optionaler Prompt-Feinschliff: `~/.config/starship.toml` (nicht enthalten, Standard von Starship wird genutzt).

## Hinweise für GitHub-Nutzung
- Nach dem Klonen nur `./setup.sh` ausführen; kein separater Plugin-Manager nötig (Plugins werden direkt geklont).
- Bei jedem Lauf werden vorhandene `~/.zshrc` und `~/.zshrc.d/` gesichert und überschrieben; eigene Anpassungen an den versionierten Dateien müssen danach erneut eingepflegt oder geforkt werden.
- Unterstützte Paketmanager: Homebrew, apt, apk, dnf/yum, pacman, zypper. Wenn keiner gefunden wird, listet das Script die benötigten Tools zur manuellen Installation.
