[Capture vidéo du 2026-11-20 23-05-41.webm](https://github.com/user-attachments/assets/396b443e-d25a-4a3d-8893-b6a8f0ae8f26)

# nag

**NAG** (*NAGYs77 Terminal Helper*) — Aide contextuelle et historique interactif pour le terminal.
Tape une commande (par exemple `docker`) puis appuie sur **Ctrl+G** pour afficher son aide, ou appuie sur **Ctrl+G** sur une ligne vide pour parcourir l'historique des commandes sans doublons ni caractères indésirables.

## Fonctionnalités

- Ouverture rapide avec **Ctrl+G**
- Affichage de l'aide de la commande tapée (ex. `docker` + **Ctrl+G** affiche l'aide de `docker`)
- Historique des commandes filtré (sans caractères indésirables ni doublons), les plus récentes en haut
- Ligne survolée en surbrillance
- Insertion de la commande ou de l'option choisie sans l'exécuter : tu appuies sur Entrée toi-même
- Ouverture dans une fenêtre latérale ou un panneau dédié selon l'environnement

## Installation

### Toutes les distributions Linux (installateur universel)

Recommandé si tu n'es pas sur Debian/Ubuntu ou si tu veux une installation rapide en une commande (nécessite **Java 17+**, `curl` ou `wget`) :

```bash
curl -fsSL https://raw.githubusercontent.com/NAGYs77/nag_project/master/scripts/install.sh | bash
```

*(Ou avec `wget` :)*

```bash
wget -qO- https://raw.githubusercontent.com/NAGYs77/nag_project/master/scripts/install.sh | bash
```

Puis ouvre un nouveau terminal (ou exécute `source ~/.bashrc`).

### Ubuntu / Debian (apt)

```bash
echo "deb [trusted=yes] https://NAGYs77.github.io/apt ./" | sudo tee /etc/apt/sources.list.d/nag.list
sudo apt update
sudo apt install nag
```

Puis ouvre un nouveau terminal.

### Fichier .deb

```bash
wget https://github.com/NAGYs77/nag_project/releases/download/v2.0.3/nag_2.0.3_all.deb
sudo apt install ./nag_2.0.3_all.deb
```

### Depuis les sources

Prérequis : **Java 17+** et **Maven**.

```bash
git clone https://github.com/NAGYs77/nag_project.git
cd nag_project
mvn clean package
mkdir -p ~/.nag
cp target/project-1.0-SNAPSHOT-jar-with-dependencies.jar ~/.nag/nag.jar
cp scripts/nag.bash ~/.nag/nag.bash
echo 'source "$HOME/.nag/nag.bash"' >> ~/.bashrc
```

## Utilisation

| Touche | Action |
|---|---|
| **Ctrl+G** | Affiche l'aide de la commande en cours (ex. `docker`) ou l'historique si la ligne est vide |
| Flèches haut / bas | Naviguer |
| **Entrée** | Coller l'élément sélectionné sur la ligne |
| **Échap** | Fermer sans rien choisir |

**Tab** garde son rôle normal d'autocomplétion de bash.

## Désinstallation

- **Via APT / `.deb` :**

```bash
sudo apt remove nag
```

- **Via l'installateur universel ou depuis les sources :**

Retire la ligne qui source `nag.bash` dans `~/.bashrc` et supprime les fichiers installés (`~/.nag` ou `~/.local/share/nag`).

## Limites actuelles

- Bash uniquement (zsh et fish ne sont pas encore supportés)
- Linux uniquement
- Nécessite Java 17 ou plus
- Lit l'historique shell (`~/.bash_history` ou `HISTFILE`) en ignorant les caractères indésirables et les doublons

## Développement

```bash
mvn clean package
./build-deb.sh
```

Structure du projet :

```
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
```

## Licence

MIT, voir le fichier [LICENSE](LICENSE).
