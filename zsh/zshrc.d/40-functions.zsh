# ~/.zshrc.d/40-functions.zsh
# Eigene Shell-Funktionen

# gitpush: staged/untracked/gelöschte Dateien committen und pushen.
# Nutzung:
#   gitpush "Nachricht"
#   gitpush            -> fragt interaktiv nach Commit-Message
gitpush() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Nicht in einem Git-Repository." >&2
    return 1
  fi
  if git diff --quiet && git diff --cached --quiet; then
    echo "Keine Änderungen zum Commit." >&2
    return 0
  fi

  git add -A || return

  local msg
  if [ $# -eq 0 ]; then
    printf "Commit-Nachricht: "
    IFS= read -r msg || { echo "Abgebrochen." >&2; return 2; }
    if [ -z "$msg" ]; then
      echo "Abgebrochen: leere Nachricht." >&2
      return 2
    fi
  else
    msg="$*"
  fi

  git commit -m "$msg" || return

  # Push: falls noch kein Upstream existiert, automatisch setzen.
  if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    git push
  else
    local remote="origin"
    git remote get-url origin >/dev/null 2>&1 || remote="$(git remote | head -n1)"
    if [ -z "$remote" ]; then
      echo "Kein Remote konfiguriert. Nutze: git remote add origin <URL>" >&2
      return 3
    fi
    git push -u "$remote" HEAD
  fi
}

# ssh-new: entfernt alte Host-Key-Einträge und akzeptiert neue automatisch
ssh-new() {
  local target="" port=""
  local prev=""

  for arg in "$@"; do
    if [ "$prev" = "-p" ]; then
      port="$arg"
      prev=""
      continue
    fi
    prev="$arg"
  done

  target="${prev##*@}"
  if [ -n "$target" ]; then
    if [ -n "$port" ]; then
      ssh-keygen -R "[$target]:$port" >/dev/null 2>&1 || true
    fi
    ssh-keygen -R "$target" >/dev/null 2>&1 || true
  fi

  ssh -o StrictHostKeyChecking=accept-new "$@"
}

# ssl-cert-generate: Zertifikat per DNS-01 Challenge mit certbot erstellen
# Nutzung: ssl-cert-generate example.com
# Optional:
#   LETSENCRYPT_BASE   – Basisverzeichnis für Config/Logs (Default: ~/.letsencrypt-local)
#   LETSENCRYPT_EMAIL  – E-Mail für Let's Encrypt Registrierung
ssl-cert-generate() {
  if [ -z "$1" ]; then
    echo "Nutzung: ssl-cert-generate example.com"
    return 1
  fi

  if ! command -v certbot >/dev/null 2>&1; then
    echo "certbot fehlt. Installiere mit: brew install certbot"
    return 1
  fi

  local DOMAIN="$1"
  local BASE="${LETSENCRYPT_BASE:-$HOME/.letsencrypt-local}"
  local CFG="$BASE/config"
  local WORK="$BASE/work"
  local LOGS="$BASE/logs"
  mkdir -p "$CFG" "$WORK" "$LOGS"

  local EMAIL_FLAG="--register-unsafely-without-email"
  [ -n "$LETSENCRYPT_EMAIL" ] && EMAIL_FLAG="--email $LETSENCRYPT_EMAIL"

  echo "Erstelle Zertifikat für: $DOMAIN"
  echo "Certbot zeigt dir gleich den TXT-Eintrag. Lege ihn im DNS an und bestätige mit Enter."

  certbot certonly \
    --manual \
    --preferred-challenges dns \
    --agree-tos \
    $EMAIL_FLAG \
    --config-dir "$CFG" \
    --work-dir "$WORK" \
    --logs-dir "$LOGS" \
    -d "$DOMAIN"

  local RC=$?
  if [ $RC -ne 0 ]; then
    echo "Fehler. Siehe Logs: $LOGS"
    return $RC
  fi

  local LIVE="$CFG/live/$DOMAIN"
  echo "Fertig. Zertifikat liegt hier:"
  echo "  Fullchain: $LIVE/fullchain.pem"
  echo "  Privkey:   $LIVE/privkey.pem"
}
