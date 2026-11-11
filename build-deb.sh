#!/usr/bin/env bash
set -e
VERSION="1.0.0"
PKG="nag_${VERSION}_all"
ROOT="build/$PKG"

mvn -q clean package
rm -rf build
mkdir -p "$ROOT/DEBIAN" "$ROOT/usr/share/nag"

cp target/project-1.0-SNAPSHOT-jar-with-dependencies.jar "$ROOT/usr/share/nag/nag.jar"

sed -e '/nag\.log/d' \
    -e 's|2>/tmp/nag.err|2>/dev/null|' \
    -e 's|^export NAG_JAR=.*|export NAG_JAR="/usr/share/nag/nag.jar"|' \
    scripts/nag.bash > "$ROOT/usr/share/nag/nag.bash"

cat > "$ROOT/DEBIAN/control" << CTL
Package: nag
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: openjdk-17-jre-headless | openjdk-21-jre-headless | openjdk-25-jre-headless
Recommends: tmux
Maintainer: NAGYs77 <ton-email@example.com>
Description: Historique de commandes interactif (Tab Tab)
 Appuie deux fois sur Tab pour ouvrir l'historique,
 choisis une commande et elle est collee dans le terminal.
CTL

cat > "$ROOT/DEBIAN/postinst" << 'PIN'
#!/bin/sh
set -e
LINE='[ -f /usr/share/nag/nag.bash ] && . /usr/share/nag/nag.bash'
grep -qxF "$LINE" /etc/bash.bashrc || echo "$LINE" >> /etc/bash.bashrc
exit 0
PIN

cat > "$ROOT/DEBIAN/postrm" << 'POUT'
#!/bin/sh
set -e
if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
  sed -i '\|/usr/share/nag/nag.bash|d' /etc/bash.bashrc
fi
exit 0
POUT

chmod 755 "$ROOT/DEBIAN/postinst" "$ROOT/DEBIAN/postrm"
dpkg-deb --build --root-owner-group "$ROOT"
echo "Paquet cree : build/$PKG.deb"
