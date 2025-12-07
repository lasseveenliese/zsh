#!/usr/bin/env bash
# Automatisches Setup für Zsh + Plugins + Tools
# Unterstützt macOS (Homebrew) und Linux (apt, apk, dnf/yum, pacman, zypper).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_ROOT="$HOME/.dotfile-backups"
TIMESTAMP="$(date +"%Y%m%d-%H%M%S")"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
ZSH_FILES_SOURCE="$REPO_DIR/zsh"
ZSHRC_TARGET="$HOME/.zshrc"
ZSHD_TARGET="$HOME/.zshrc.d"
STARSHIP_CONFIG_SOURCE="$REPO_DIR/starship/starship.toml"
STARSHIP_CONFIG_TARGET="$HOME/.config/starship.toml"
ZSH_PLUGINS="${ZSH_PLUGINS:-$HOME/.zsh-plugins}"
SUDO_CMD=""

log() { printf "[setup] %s\n" "$*"; }
warn() { printf "[setup][WARN] %s\n" "$*" >&2; }

ensure_sudo() {
  if [ "$EUID" -eq 0 ]; then
    SUDO_CMD=""
  elif command -v sudo >/dev/null 2>&1; then
    SUDO_CMD="sudo"
  else
    warn "sudo nicht gefunden. Bitte als root ausführen oder sudo installieren."
    exit 1
  fi
}

run_root() {
  if [ -n "$SUDO_CMD" ]; then
    "$SUDO_CMD" "$@"
  else
    "$@"
  fi
}

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

detect_pkgmgr() {
  if command -v brew >/dev/null 2>&1; then
    echo "brew"
  elif command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v apk >/dev/null 2>&1; then
    echo "apk"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v zypper >/dev/null 2>&1; then
    echo "zypper"
  else
    echo "none"
  fi
}

install_dust_apt() {
  if run_root apt-cache show du-dust >/dev/null 2>&1; then
    run_root apt-get install -y du-dust
    return
  fi
  if run_root apt-cache show dust >/dev/null 2>&1; then
    run_root apt-get install -y dust
    return
  fi
  warn "dust/du-dust nicht im Repo gefunden. Installiere dust manuell (z.B. via cargo oder Release-Binary)."
}

nerd_font_installed() {
  if command -v fc-list >/dev/null 2>&1; then
    if fc-list | grep -qi "JetBrainsMono Nerd Font"; then
      return 0
    fi
  fi
  if [ -d "$HOME/Library/Fonts" ]; then
    if compgen -G "$HOME/Library/Fonts"/JetBrainsMono* >/dev/null; then
      return 0
    fi
  fi
  return 1
}

install_nerd_font() {
  local os="$1"
  local pkgmgr="$2"

  if nerd_font_installed; then
    log "JetBrainsMono Nerd Font bereits installiert"
    return
  fi

  if [ "$pkgmgr" = "brew" ]; then
    brew tap homebrew/cask-fonts >/dev/null 2>&1 || warn "Konnte homebrew/cask-fonts nicht tappen"
    if brew install --cask font-jetbrains-mono-nerd-font; then
      log "JetBrainsMono Nerd Font via Homebrew installiert"
      return
    else
      warn "Installation via brew fehlgeschlagen, versuche Download"
    fi
  fi

  local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  local tmpdir
  tmpdir="$(mktemp -d)"
  local font_dir
  if [ "$os" = "macos" ]; then
    font_dir="$HOME/Library/Fonts"
  else
    font_dir="$HOME/.local/share/fonts"
  fi
  mkdir -p "$font_dir"
  if curl -fL "$font_url" -o "$tmpdir/JetBrainsMono.zip"; then
    unzip -o "$tmpdir/JetBrainsMono.zip" -d "$font_dir" >/dev/null
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f "$font_dir" >/dev/null || warn "fc-cache konnte den Font-Cache nicht aktualisieren"
    fi
    log "JetBrainsMono Nerd Font installiert nach $font_dir"
    log "Bitte im Terminal die Schriftart auf 'JetBrainsMono Nerd Font' umstellen."
  else
    warn "Download von JetBrainsMono Nerd Font fehlgeschlagen. Bitte manuell installieren: $font_url"
  fi
  rm -rf "$tmpdir"
}

ensure_backup_dir() {
  mkdir -p "$BACKUP_DIR"
}

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    ensure_backup_dir
    local dest
    dest="$BACKUP_DIR/$(basename "$target")"
    log "Backup $target -> $dest"
    mv "$target" "$dest"
  fi
}

copy_zsh_configs() {
  log "Installiere Zsh-Konfiguration nach $HOME"
  backup_if_exists "$ZSHRC_TARGET"
  backup_if_exists "$ZSHD_TARGET"
  mkdir -p "$ZSHD_TARGET"
  cp "$ZSH_FILES_SOURCE/zshrc" "$ZSHRC_TARGET"
  cp "$ZSH_FILES_SOURCE/zshrc.d/"*.zsh "$ZSHD_TARGET/"
}

copy_starship_config() {
  if [ ! -r "$STARSHIP_CONFIG_SOURCE" ]; then
    warn "Starship-Konfiguration fehlt, überspringe"
    return
  fi

  mkdir -p "$(dirname "$STARSHIP_CONFIG_TARGET")"
  backup_if_exists "$STARSHIP_CONFIG_TARGET"
  cp "$STARSHIP_CONFIG_SOURCE" "$STARSHIP_CONFIG_TARGET"
  log "Starship-Konfiguration installiert nach $STARSHIP_CONFIG_TARGET"
}

current_login_shell() {
  local user
  user="${USER:-$(id -un 2>/dev/null || true)}"
  if [ -n "${SHELL:-}" ]; then
    echo "$SHELL"
    return
  fi

  if command -v getent >/dev/null 2>&1; then
    if [ -n "$user" ]; then
      getent passwd "$user" | cut -d: -f7
    fi
  fi
}

ensure_shell_listed() {
  local shell_path="$1"

  if [ ! -f /etc/shells ]; then
    warn "/etc/shells nicht gefunden, kann Login-Shell ggf. nicht setzen"
    return
  fi

  if grep -Fx "$shell_path" /etc/shells >/dev/null 2>&1; then
    return
  fi

  if [ -w /etc/shells ]; then
    echo "$shell_path" >> /etc/shells
  elif [ -n "$SUDO_CMD" ]; then
    run_root sh -c "echo '$shell_path' >> /etc/shells"
  else
    warn "Bitte Shell manuell zu /etc/shells hinzufügen: echo '$shell_path' | sudo tee -a /etc/shells"
  fi
}

set_default_shell_to_zsh() {
  local zsh_path current_shell user
  zsh_path="$(command -v zsh || true)"
  current_shell="$(current_login_shell || true)"
  user="${USER:-$(id -un 2>/dev/null || true)}"

  if [ -z "$zsh_path" ]; then
    warn "zsh nicht gefunden, Login-Shell nicht umgestellt"
    return
  fi

  if [ "$current_shell" = "$zsh_path" ]; then
    log "Login-Shell ist bereits zsh"
    return
  fi

  ensure_shell_listed "$zsh_path"

  if [ -z "$user" ]; then
    warn "Konnte Benutzer nicht ermitteln, Login-Shell bleibt unverändert"
    return
  fi

  if command -v chsh >/dev/null 2>&1; then
    if chsh -s "$zsh_path" "$user" >/dev/null 2>&1; then
      log "Login-Shell auf zsh gesetzt"
      return
    fi
    if [ -n "$SUDO_CMD" ] && run_root chsh -s "$zsh_path" "$user" >/dev/null 2>&1; then
      log "Login-Shell auf zsh gesetzt (sudo)"
      return
    fi
  fi

  warn "Konnte Login-Shell nicht automatisch umstellen. Bitte manuell ausführen: chsh -s $zsh_path"
}

clone_or_update_plugin() {
  local name="$1"
  local repo="$2"
  local dest="$ZSH_PLUGINS/$name"
  if [ -d "$dest/.git" ]; then
    log "Update Plugin $name"
    git -C "$dest" pull --ff-only >/dev/null || warn "Konnte $name nicht aktualisieren"
  elif [ -d "$dest" ]; then
    warn "$dest existiert ohne Git, überspringe"
  else
    log "Clone Plugin $name"
    git clone --depth 1 "$repo" "$dest" >/dev/null || warn "Clone fehlgeschlagen: $name"
  fi
}

setup_plugins() {
  mkdir -p "$ZSH_PLUGINS"
  clone_or_update_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
  clone_or_update_plugin "zsh-you-should-use" "https://github.com/MichaelAquilina/zsh-you-should-use.git"
  clone_or_update_plugin "zsh-bat" "https://github.com/fdellwing/zsh-bat.git"
  clone_or_update_plugin "fast-syntax-highlighting" "https://github.com/zdharma-continuum/fast-syntax-highlighting.git"
  clone_or_update_plugin "zsh-completions" "https://github.com/zsh-users/zsh-completions.git"
}

install_bun() {
  if command -v bun >/dev/null 2>&1; then
    return
  fi
  log "Installiere bun (https://bun.sh)"
  curl -fsSL https://bun.sh/install | bash
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    return
  fi
  log "Installiere starship prompt"
  case "$1" in
    brew) brew install starship ;;
    apt) curl -fsSL https://starship.rs/install.sh | sh -s -- -y ;;
    apk)
      ensure_sudo
      if ! run_root apk add --no-cache starship; then
        warn "Starship-Paket nicht verfügbar, fallback auf Install-Skript"
        curl -fsSL https://starship.rs/install.sh | sh -s -- -y || warn "Starship-Installer (curl) fehlgeschlagen"
      fi
      ;;
    dnf|yum) ensure_sudo; run_root "$1" install -y starship || warn "Starship-Installation über $1 fehlgeschlagen" ;;
    pacman) ensure_sudo; run_root pacman -Sy --noconfirm starship || warn "Starship-Installation über pacman fehlgeschlagen" ;;
    zypper) ensure_sudo; run_root zypper install -y starship || warn "Starship-Installation über zypper fehlgeschlagen" ;;
    *) warn "Starship nicht installiert (kein unterstützter Paketmanager)" ;;
  esac
}

install_node_pnpm() {
  # Node/NPM: nur installieren, wenn npm fehlt.
  if ! command -v npm >/dev/null 2>&1; then
    case "$1" in
      brew) brew install node ;;
      apt) run_root apt-get install -y nodejs npm ;;
      apk) ensure_sudo; run_root apk add --no-cache nodejs npm ;;
      dnf|yum) ensure_sudo; run_root "$1" install -y nodejs npm ;;
      pacman) ensure_sudo; run_root pacman -Sy --noconfirm nodejs npm ;;
      zypper) ensure_sudo; run_root zypper install -y nodejs npm ;;
      *) warn "npm nicht installiert (kein unterstützter Paketmanager)" ;;
    esac
  fi
  if command -v npm >/dev/null 2>&1 && ! command -v pnpm >/dev/null 2>&1; then
    log "Installiere pnpm via npm"
    npm install -g pnpm
  fi
}

ensure_fd_symlink() {
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    local target_dir="/usr/local/bin"
    mkdir -p "$target_dir"
    if [ -w "$target_dir" ]; then
      ln -s "$(command -v fdfind)" "$target_dir/fd"
    elif [ -n "$SUDO_CMD" ]; then
      run_root ln -s "$(command -v fdfind)" "$target_dir/fd"
    else
      warn "fd-find installiert. Lege manuell Symlink an: sudo ln -s $(command -v fdfind) $target_dir/fd"
    fi
  fi
}

refresh_package_index() {
  local pkgmgr="$1"
  case "$pkgmgr" in
    brew)
      brew update
      ;;
    apt)
      ensure_sudo
      run_root apt-get update
      ;;
    apk)
      ensure_sudo
      run_root apk update
      ;;
    dnf|yum)
      ensure_sudo
      run_root "$pkgmgr" makecache -y || warn "Konnte Paketindex über $pkgmgr nicht aktualisieren"
      ;;
    pacman)
      ensure_sudo
      run_root pacman -Sy --noconfirm
      ;;
    zypper)
      ensure_sudo
      run_root zypper refresh
      ;;
  esac
}

install_packages() {
  local os="$1"
  local pkgmgr="$2"
  log "OS: $os, Paketmanager: $pkgmgr"

  if [ "$pkgmgr" = "none" ]; then
    warn "Kein unterstützter Paketmanager gefunden. Bitte installiere Tools manuell: eza, fd/fdfind, ripgrep, dust (du-dust), zoxide, bat, certbot, bun, npm, pnpm, starship."
    return
  fi

  case "$pkgmgr" in
    brew)
      refresh_package_index "$pkgmgr"
      brew install git curl zsh eza fd ripgrep dust zoxide bat certbot bun starship node pnpm
      ;;
    apt)
      ensure_sudo
      refresh_package_index "$pkgmgr"
      run_root apt-get install -y git curl zsh eza fd-find ripgrep zoxide bat certbot nodejs npm unzip
      install_dust_apt
      ;;
    apk)
      ensure_sudo
      refresh_package_index "$pkgmgr"
      run_root apk add --no-cache git curl zsh eza fd ripgrep dust zoxide bat certbot nodejs npm unzip starship || warn "Einige Pakete konnten nicht über apk installiert werden"
      ;;
    dnf|yum)
      ensure_sudo
      refresh_package_index "$pkgmgr"
      run_root "$pkgmgr" install -y git curl zsh eza fd-find ripgrep dust zoxide bat certbot nodejs npm unzip starship || warn "Einige Pakete konnten nicht über $pkgmgr installiert werden"
      ensure_fd_symlink
      ;;
    pacman)
      ensure_sudo
      refresh_package_index "$pkgmgr"
      run_root pacman -S --noconfirm git curl zsh eza fd ripgrep dust zoxide bat certbot nodejs npm pnpm unzip starship || warn "Einige Pakete konnten nicht über pacman installiert werden"
      ;;
    zypper)
      ensure_sudo
      refresh_package_index "$pkgmgr"
      run_root zypper install -y git curl zsh eza fd ripgrep dust zoxide bat certbot nodejs npm unzip starship || warn "Einige Pakete konnten nicht über zypper installiert werden"
      ;;
  esac

  install_bun
  install_starship "$pkgmgr"
  install_node_pnpm "$pkgmgr"
  install_nerd_font "$os" "$pkgmgr"
  ensure_fd_symlink
}

main() {
  local os pkgmgr
  os="$(detect_os)"
  pkgmgr="$(detect_pkgmgr)"

  if [ "$os" = "unknown" ]; then
    warn "Unbekanntes OS. Bitte Tools manuell installieren."
  else
    install_packages "$os" "$pkgmgr"
  fi

  set_default_shell_to_zsh
  copy_zsh_configs
  setup_plugins
  copy_starship_config

  log "Fertig. Neue Shell starten oder 'exec zsh' ausführen."
}

main "$@"
