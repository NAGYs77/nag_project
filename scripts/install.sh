#!/usr/bin/env bash
set -euo pipefail

# Remplace par ton vrai dépôt GitHub (ex: "nagy-dev/nag")
REPO="${NAG_REPO:-NAGYs77/nag_project}"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nag"
LEGACY_DIR="$HOME/.nag"
BASHRC="$HOME/.bashrc"
SOURCE_LINE='[ -f "$HOME/.local/share/nag/nag.bash" ] && source "$HOME/.local/share/nag/nag.bash"'

info()  { printf "\033[1;34m[nag]\033[0m %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m  %s\n" "$1"; }
err()   { printf "\033[1;31m[err]\033[0m %s\n" "$1" >&2; }

uninstall_nag() {
  info "Désinstallation de nag..."
  rm -rf "$INSTALL_DIR"
  [ -L "$LEGACY_DIR" ] && rm -f "$LEGACY_DIR"
  if [ -f "$BASHRC" ]; then
    grep -vF '.local/share/nag/nag.bash' "$BASHRC" | grep -vF '.nag/nag.bash' > "${BASHRC}.tmp" && mv "${BASHRC}.tmp" "$BASHRC"
  fi
  ok "nag a été désinstallé. Ouvre un nouveau terminal pour finaliser."
  exit 0
}

check_java() {
  if ! command -v java >/dev/null 2>&1; then
    err "Java n'est pas installé sur ce système (Java 17 ou supérieur requis)."
    echo "Installe-le selon ta distribution :"
    echo "  • Debian / Ubuntu / Mint : sudo apt update && sudo apt install -y openjdk-17-jre"
    echo "  • Fedora / RHEL          : sudo dnf install -y java-17-openjdk"
    echo "  • Arch / Manjaro         : sudo pacman -S jre17-openjdk"
    echo "  • openSUSE               : sudo zypper install java-17-openjdk"
    exit 1
  fi

  local ver
  ver=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
  if [ -n "$ver" ] && [ "$ver" -lt 17 ] 2>/dev/null; then
    err "Version de Java détectée : $ver. Java 17+ est recommandé."
  fi
}

download_file() {
  local url="$1"
  local dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    err "Ni curl ni wget n'est installé. Installe l'un des deux pour télécharger nag."
    exit 1
  fi
}

if [ "${1:-}" = "--uninstall" ]; then
  uninstall_nag
fi

check_java
mkdir -p "$INSTALL_DIR"

if [ "${1:-}" = "--local" ]; then
  info "Installation locale depuis le dossier courant..."
  JAR_SRC=$(find target -maxdepth 1 -name "*-jar-with-dependencies.jar" | head -n 1)
  if [ -z "$JAR_SRC" ] || [ ! -f "scripts/nag.bash" ]; then
    err "Fichiers introuvables. Lance d'abord 'mvn clean package' depuis la racine du projet."
    exit 1
  fi
  cp "$JAR_SRC" "$INSTALL_DIR/nag.jar"
  cp "scripts/nag.bash" "$INSTALL_DIR/nag.bash"
else
  BASE_URL="https://github.com/${REPO}/releases/latest/download"
  info "Téléchargement de nag depuis GitHub ($REPO)..."
  download_file "$BASE_URL/nag.jar" "$INSTALL_DIR/nag.jar"
  download_file "$BASE_URL/nag.bash" "$INSTALL_DIR/nag.bash"
fi

# Compatibilité avec ~/.nag
if [ -d "$LEGACY_DIR" ] && [ ! -L "$LEGACY_DIR" ]; then
  rm -rf "$LEGACY_DIR"
fi
ln -sfn "$INSTALL_DIR" "$LEGACY_DIR"

# Ajout propre dans ~/.bashrc
touch "$BASHRC"
if ! grep -qF '.local/share/nag/nag.bash' "$BASHRC"; then
  printf "\n# nag - autocomplétion et historique terminal\n%s\n" "$SOURCE_LINE" >> "$BASHRC"
fi

ok "Installation terminée dans $INSTALL_DIR !"
info "Lance 'source ~/.bashrc' ou ouvre un nouveau terminal pour utiliser nag (Tab Tab ou Ctrl+G)."
