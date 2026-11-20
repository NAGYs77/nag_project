#!/usr/bin/env bash
set -euo pipefail

PROJECT_REPO="${NAG_PROJECT_REPO:-NAGYs77/nag_project}"
PROJECT_BRANCH="${NAG_PROJECT_BRANCH:-master}"
RELEASE_REPO="${NAG_RELEASE_REPO:-NAGYs77/apt}"
APT_REPO_URL="${NAG_APT_URL:-https://raw.githubusercontent.com/NAGYs77/apt/main}"
APT_LIST_FILE="/etc/apt/sources.list.d/nag.list"

INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nag"
LEGACY_DIR="$HOME/.nag"
BASHRC="$HOME/.bashrc"
SOURCE_LINE='[ -f "$HOME/.local/share/nag/nag.bash" ] && source "$HOME/.local/share/nag/nag.bash"'

info()  { printf "\033[1;34m[nag]\033[0m %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m  %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m %s\n" "$1"; }
err()   { printf "\033[1;31m[err]\033[0m %s\n" "$1" >&2; }

detect_distro() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "${ID:-unknown}"
  else
    echo "unknown"
  fi
}

check_java() {
  if command -v java >/dev/null 2>&1; then
    local ver
    ver=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    if [ -n "$ver" ] && [ "$ver" -lt 17 ] 2>/dev/null; then
      warn "Version de Java détectée : $ver. Java 17+ est recommandé."
    fi
    return 0
  fi

  local distro
  distro=$(detect_distro)
  err "Java (JRE/JDK 17+) n'est pas installé."
  case "$distro" in
    ubuntu|debian|linuxmint|pop)
      echo "Installe Java avec : sudo apt update && sudo apt install -y openjdk-17-jre-headless"
      ;;
    fedora|rhel|centos|rocky|almalinux)
      echo "Installe Java avec : sudo dnf install -y java-17-openjdk-headless"
      ;;
    arch|manjaro|endeavouros)
      echo "Installe Java avec : sudo pacman -S --noconfirm jre17-openjdk-headless"
      ;;
    opensuse*|sles)
      echo "Installe Java avec : sudo zypper install -y java-17-openjdk-headless"
      ;;
    alpine)
      echo "Installe Java avec : sudo apk add openjdk17-jre"
      ;;
    *)
      echo "Installe openjdk-17-jre-headless (ou équivalent Java 17+) avec le gestionnaire de paquets de ta distribution."
      ;;
  esac
  exit 1
}

fetch_url() {
  local url="$1"
  local dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    err "Ni curl ni wget n'est installé."
    return 1
  fi
}

configure_bashrc() {
  if [ -d "$LEGACY_DIR" ] && [ ! -L "$LEGACY_DIR" ]; then
    rm -rf "$LEGACY_DIR"
  fi
  ln -sfn "$INSTALL_DIR" "$LEGACY_DIR"

  touch "$BASHRC"
  if ! grep -qF '.local/share/nag/nag.bash' "$BASHRC"; then
    printf "\n# nag - autocomplétion et historique terminal\n%s\n" "$SOURCE_LINE" >> "$BASHRC"
  fi
}

uninstall_nag() {
  info "Désinstallation de nag..."
  if command -v apt-get >/dev/null 2>&1 && dpkg -s nag >/dev/null 2>&1; then
    sudo apt-get remove -y nag || true
  fi
  if [ -f "$APT_LIST_FILE" ]; then
    sudo rm -f "$APT_LIST_FILE"
  fi
  rm -rf "$INSTALL_DIR"
  [ -L "$LEGACY_DIR" ] && rm -f "$LEGACY_DIR"
  if [ -f "$BASHRC" ]; then
    grep -vF '.local/share/nag/nag.bash' "$BASHRC" | grep -vF '.nag/nag.bash' > "${BASHRC}.tmp" && mv "${BASHRC}.tmp" "$BASHRC"
  fi
  ok "nag a été désinstallé. Ouvre un nouveau terminal pour finaliser."
  exit 0
}

install_local() {
  check_java
  info "Installation locale..."
  local jar_src
  jar_src=$(find target -maxdepth 1 -name "*-jar-with-dependencies.jar" 2>/dev/null | head -n 1 || true)
  if [ -z "$jar_src" ] && [ -f "pom.xml" ] && command -v mvn >/dev/null 2>&1; then
    info "Compilation du JAR avec Maven..."
    mvn -q clean package
    jar_src=$(find target -maxdepth 1 -name "*-jar-with-dependencies.jar" 2>/dev/null | head -n 1 || true)
  fi
  if [ -z "$jar_src" ] || [ ! -f "scripts/nag.bash" ]; then
    err "JAR ou scripts/nag.bash introuvable. Lance 'mvn clean package' depuis la racine du projet."
    exit 1
  fi
  mkdir -p "$INSTALL_DIR"
  cp "$jar_src" "$INSTALL_DIR/nag.jar"
  cp "scripts/nag.bash" "$INSTALL_DIR/nag.bash"
  configure_bashrc
}

install_universal() {
  check_java
  mkdir -p "$INSTALL_DIR"

  info "Téléchargement de nag.bash..."
  fetch_url "https://raw.githubusercontent.com/${PROJECT_REPO}/${PROJECT_BRANCH}/scripts/nag.bash" "$INSTALL_DIR/nag.bash"

  local jar_ok=0
  for repo in "$PROJECT_REPO" "$RELEASE_REPO"; do
    local rel_url="https://github.com/${repo}/releases/latest/download/nag.jar"
    if fetch_url "$rel_url" "$INSTALL_DIR/nag.jar" 2>/dev/null && [ -s "$INSTALL_DIR/nag.jar" ]; then
      jar_ok=1
      break
    fi
  done

  if [ "$jar_ok" -ne 1 ]; then
    rm -f "$INSTALL_DIR/nag.jar"
    if [ -f "pom.xml" ] && command -v mvn >/dev/null 2>&1; then
      warn "nag.jar non trouvé sur les Releases GitHub. Compilation locale via Maven..."
      mvn -q clean package
      local jar_src
      jar_src=$(find target -maxdepth 1 -name "*-jar-with-dependencies.jar" 2>/dev/null | head -n 1 || true)
      if [ -n "$jar_src" ]; then
        cp "$jar_src" "$INSTALL_DIR/nag.jar"
        jar_ok=1
      fi
    fi
  fi

  if [ "$jar_ok" -ne 1 ]; then
    err "nag.jar introuvable (404 sur les Releases GitHub et aucun projet Maven local)."
    echo "Pour corriger :"
    echo "  1. Publie une Release sur https://github.com/${RELEASE_REPO}/releases (ou ${PROJECT_REPO}/releases) avec le fichier nag.jar en asset."
    echo "  2. Ou clone le dépôt et lance : mvn clean package && ./scripts/install.sh --local"
    exit 1
  fi

  configure_bashrc
}

install_via_apt() {
  info "Installation via le dépôt APT ($APT_REPO_URL)..."
  echo "deb [trusted=yes] ${APT_REPO_URL} ./" | sudo tee "$APT_LIST_FILE" >/dev/null
  sudo apt-get update
  sudo apt-get install -y nag
}

if [ "${1:-}" = "--uninstall" ]; then
  uninstall_nag
elif [ "${1:-}" = "--local" ]; then
  install_local
elif [ "${1:-}" = "--universal" ]; then
  install_universal
else
  if command -v apt-get >/dev/null 2>&1; then
    if ! install_via_apt; then
      warn "APT indisponible ou incomplet, passage à l'installation universelle..."
      install_universal
    fi
  else
    install_universal
  fi
fi

ok "Installation terminée !"
info "Lance 'source ~/.bashrc' ou ouvre un nouveau terminal pour utiliser nag (Tab Tab ou Ctrl+G)."
