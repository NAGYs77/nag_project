[Capture vidéo du 2026-11-20 22-58-35.webm](https://github.com/user-attachments/assets/8d1d800d-7508-4f3b-b509-cc663a557127)
# nag

**NAG** (*NAGYs77 Terminal Helper*) — Aide contextuelle et historique interactif pour le terminal.
Tape une commande (par exemple `docker`) puis appuie deux fois sur **Tab** (**Tab Tab**) pour afficher son aide, ou appuie sur **Tab Tab** sur une ligne vide pour parcourir l'historique des commandes sans doublons ni caractères indésirables.

## Fonctionnalités

- Ouverture rapide avec **Tab Tab** (appui 2 fois sur **Tab**) ou **Ctrl+G**
- Affichage de l'aide de la commande tapée (ex. `docker` + **Tab Tab** affiche l'aide de `docker`)
- Historique des commandes filtré (sans caractères indésirables ni doublons), les plus récentes en haut
- Ligne survolée en surbrillance
- Insertion de la commande ou de l'option choisie sans l'exécuter : tu appuies sur Entrée toi-même
- Ouverture dans une fenêtre latérale ou un panneau dédié selon l'environnement

## Installation

### Toutes les distributions Linux (installateur universel)

Recommandé si tu n'es pas sur Debian/Ubuntu ou si tu veux une installation rapide en une commande (nécessite **Java 17+**, `curl` ou `wget`) :

curl -fsSL https://raw.githubusercontent.com/NAGYs77/nag_project/main/scripts/install.sh | bash

*(Ou avec `wget` :)*

wget -qO- https://raw.githubusercontent.com/NAGYs77/nag_project/main/scripts/install.sh | bash

Puis ouvre un nouveau terminal (ou exécute `source ~/.bashrc`).

### Ubuntu / Debian (apt)

echo "deb [trusted=yes] https://NAGYs77.github.io/apt ./" | sudo tee /etc/apt/sources.list.d/nag.list
sudo apt update
sudo apt install nag

Puis ouvre un nouveau terminal.

### Fichier .deb

wget https://github.com/NAGYs77/nag_project/releases/download/v1.0.0/nag_1.0.0_all.deb
sudo apt install ./nag_1.0.0_all.deb

### Depuis les sources

Prérequis : **Java 17+** et **Maven**.

git clone https://github.com/NAGYs77/nag_project.git
cd nag_project
mvn clean package
mkdir -p ~/.nag
cp target/project-1.0-SNAPSHOT-jar-with-dependencies.jar ~/.nag/nag.jar
cp scripts/nag.bash ~/.nag/nag.bash
echo 'source "$HOME/.nag/nag.bash"' >> ~/.bashrc

## Utilisation

| Touche | Action |
|---|---|
| **Tab Tab** (2 fois sur Tab) | Affiche l'aide de la commande en cours (ex. `docker`) ou l'historique si la ligne est vide |
| **Ctrl+G** | Ouvre la fenêtre / liste (raccourci de secours) |
| Flèches haut / bas | Naviguer |
| **Entrée** | Coller l'élément sélectionné sur la ligne |
| **Échap** | Fermer sans rien choisir |

Un seul **Tab** garde l'autocomplétion normale de bash.

## Désinstallation

- **Via APT / `.deb` :**

sudo apt remove nag

- **Via l'installateur universel ou depuis les sources :**

Retire la ligne qui source `nag.bash` dans `~/.bashrc` et supprime les fichiers installés (`~/.nag` ou `~/.local/share/nag`).

## Limites actuelles

- Bash uniquement (zsh et fish ne sont pas encore supportés)
- Linux uniquement
- Nécessite Java 17 ou plus
- Lit l'historique shell (`~/.bash_history` ou `HISTFILE`) en ignorant les caractères indésirables et les doublons

## Développement

mvn clean package
./build-deb.sh

Structure du projet :

nag_project/
├── pom.xml
├── build-deb.sh
├── scripts/
│   ├── install.sh
│   └── nag.bash
└── src/main/java/com/nag/
    ├── Main.java
    ├── TerminalUI.java
    └── HistoryReader.java

## Licence

MIT, voir le fichier [LICENSE](LICENSE).
