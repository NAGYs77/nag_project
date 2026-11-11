# nag

Historique de commandes interactif pour le terminal.
Appuie deux fois sur **Tab**, choisis une commande dans la liste, et elle est collée directement sur ta ligne de commande.

## Fonctionnalités

- Ouverture rapide avec **Tab Tab** (ou **Ctrl+G**)
- Liste des commandes les plus récentes en haut
- Ligne survolée en surbrillance
- Insertion de la commande sans l'exécuter : tu appuies sur Entrée toi-même
- Dans **tmux**, le panneau s'ouvre à droite du terminal

## Installation

### Ubuntu / Debian (apt)

```bash
echo "deb [trusted=yes] https://NAGYs77.github.io/apt ./" | sudo tee /etc/apt/sources.list.d/nag.list
sudo apt update
sudo apt install nag
```

Puis ouvre un nouveau terminal.

### Fichier .deb

```bash
wget https://github.com/NAGYs77/nag_project/releases/download/v1.0.0/nag_1.0.0_all.deb
sudo apt install ./nag_1.0.0_all.deb
```

### Depuis les sources

Prérequis : Java 17+ et Maven.

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
| **Tab Tab** (rapide) | Ouvre la liste de l'historique |
| **Ctrl+G** | Ouvre la liste (raccourci de secours) |
| Flèches haut / bas | Naviguer |
| **Entrée** | Coller la commande sur la ligne |
| **Échap** | Fermer sans rien choisir |

Un seul Tab garde l'autocomplétion normale de bash.

## Désinstallation

```bash
sudo apt remove nag
```

Si tu as installé depuis les sources, retire la ligne `source "$HOME/.nag/nag.bash"` de `~/.bashrc` et supprime `~/.nag`.

## Limites actuelles

- Bash uniquement (zsh et fish ne sont pas encore supportés)
- Linux uniquement
- Nécessite Java 17 ou plus
- Lit `~/.bash_history` : les commandes de la session en cours sont ajoutées avant l'ouverture de la liste

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
├── scripts/nag.bash
└── src/main/java/com/nag/
    ├── Main.java
    ├── TerminalUI.java
    └── HistoryReader.java
```

## Licence

À définir (par exemple MIT).
