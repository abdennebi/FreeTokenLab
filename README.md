# 🧪 FreeTokenLab — Guide d'Installation & Déploiement Complet

Bienvenue dans le laboratoire **FreeTokenLab**. Ce dépôt rassemble toute la documentation, les scripts d'automatisation et les configurations pré-calibrées pour déployer **FreeToken** et son écosystème d'**Agents de Codage IA** sur une machine Linux (avec GPU NVIDIA).

---

## 📑 Sommaire
1. [Architecture & Spécifications Matérielles](#-architecture--spécifications-matérielles)
2. [Structure du Projet FreeTokenLab](#-structure-du-projet-freetokenlab)
3. [Installation Rapide (en 4 commandes)](#-installation-rapide-en-4-commandes)
4. [Guide Détaillé Pas-à-Pas](#-guide-détaillé-pas-à-pas)
   - [Étape 1 : Prérequis système & Python](#étape-1--prérequis-système--python)
   - [Étape 2 : Compilation & Calibration de FreeToken](#étape-2--compilation--calibration-de-freetoken)
   - [Étape 3 : Démarrage du Serveur FreeToken](#étape-3--démarrage-du-serveur-freetoken)
   - [Étape 4 : Installation & Configuration des 4 Agents](#étape-4--installation--configuration-des-4-agents)
5. [Guide d'Utilisation des 4 Agents IA](#-guide-dutilisation-des-4-agents-ia)
   - [1. OpenCode](#1-opencode)
   - [2. Pi Coding Agent](#2-pi-coding-agent)
   - [3. DeepSeek Harness (dsh)](#3-deepseek-harness-dsh)
   - [4. Hermes Agent](#4-hermes-agent)
6. [Surveillance & Contrôle en Direct](#-surveillance--contrôle-en-direct)

---

## ⚡ Architecture & Spécifications Matérielles

Cette configuration est spécifiquement optimisée pour les machines disposant d'un GPU grand public (ex. **RTX 3070 8 Go**) couplé à une mémoire vive standard (**32 Go DDR4/DDR5**) et un processeur multicœur (**AVX2**).

| Composant | Rôle dans FreeToken | Dimensionnement Recommandé |
| :--- | :--- | :--- |
| **GPU VRAM (8 Go)** | Poids denses (3.1 Go) + Cache MoE LRU (1.3 Go) + Cache KV (32K tokens, 640 Mo) + Tenseurs d'activation | **~6.8 Go occupés** (marge de sécurité de 1.2 Go) |
| **RAM Hôte (32 Go)** | Stockage complet des 256 experts NVFP4 en mémoire paginée épinglée (*pinned memory*) | **~19 Go occupés** |
| **CPU (8+ cœurs)** | Exécution concurrente des experts non-cachés via noyaux C++ AVX2 (`_cpu_moe`) | **7 threads de calcul** |
| **PCIe (Gen3/Gen4)** | Préchangement asynchrone des experts GPU (taux de préchargement de 21.6%) | **Bande passante ~12-16 Go/s** |

---

## 📂 Structure du Projet FreeTokenLab

```text
FreeTokenLab/
├── README.md                # Le présent guide complet
├── env.sh                   # Script d'export des variables d'environnement & PATH
│
├── configs/                 # Fichiers de configuration des 4 agents
│   ├── opencode/
│   │   └── config.json      # Limite contexte 32k, auto-compaction 80%
│   ├── pi/
│   │   ├── models.json      # Définition du provider freetoken (OpenAI-compatible)
│   │   └── settings.json    # Modèle et provider par défaut
│   ├── dsh/
│   │   ├── settings.yaml    # Config du plugin llm-pi-ai / deepseek-official
│   │   └── .credentials.yaml# Clé d'API locale dummy
│   └── hermes/
│       └── config.yaml      # Provider custom, base_url, context_length 65536
│
└── scripts/                 # Scripts d'automatisation
    ├── 01_setup_host.sh     # Outils système, Node.js v22 LTS, uv, PyTorch CUDA
    ├── 02_build_freetoken.sh# Compilation C++ (_pinned_tensor, _cpu_moe) & bench
    ├── 03_install_agents.sh # Installation d'OpenCode, Pi, DSH et Hermes
    ├── 04_apply_configs.sh  # Déploiement des configs dans vos dossiers home
    ├── start_server.sh      # Lancement du serveur FreeToken calibré
    └── test_agents.sh       # Suite de validation rapide des 4 agents
```

---

## 🚀 Installation Rapide (en 4 commandes)

Sur une nouvelle machine Linux Ubuntu/Debian :

```bash
# 1. Cloner FreeToken et FreeTokenLab côte à côte
git clone https://github.com/FlashML-org/FreeToken.git
git clone <url_de_ce_repo_ou_copie> FreeTokenLab

# 2. Exécuter l'installation système, Node.js et PyTorch
cd FreeTokenLab
./scripts/01_setup_host.sh

# 3. Compiler les noyaux C++ de FreeToken
./scripts/02_build_freetoken.sh

# 4. Installer les 4 agents et déployer les configurations
./scripts/03_install_agents.sh
./scripts/04_apply_configs.sh
```

---

## 📖 Guide Détaillé Pas-à-Pas

### Étape 1 : Prérequis système & Python

Le script `./scripts/01_setup_host.sh` effectue automatiquement :
1. L'installation des paquets système indispensables : `build-essential`, `git`, `curl`, `wget`, `xz-utils`, `libopenblas-dev`.
2. L'installation de **Node.js LTS (v22.23.2+)** dans `~/.local/` (nécessaire pour `dsh` et les routines de décompression Zstandard).
3. L'installation du gestionnaire d'environnements ultra-rapide **`uv`**.
4. La création de l'environnement virtuel Python 3.12 (`.venv`).
5. L'installation de **PyTorch avec support CUDA** (`torch`, `torchvision`, `torchaudio`) et des noyaux optimisés (`sglang-kernel>=0.4.5`).

### Étape 2 : Compilation & Calibration de FreeToken

Le script `./scripts/02_build_freetoken.sh` compile les extensions natives :
```bash
source env.sh
pip install -e . --no-build-isolation
```
Cela génère :
- `freetoken.kernel._pinned_tensor` : allocation de mémoire hôte épinglée sans copie.
- `freetoken.kernel._cpu_moe` : calcul matriciel vectorisé AVX2 pour les experts exécutés sur CPU.

### Étape 3 : Démarrage du Serveur FreeToken

Pour lancer le serveur d'inférence avec la calibration optimale pour carte 8 Go :

```bash
source env.sh
./scripts/start_server.sh
```

*Détail des arguments appliqués :*
- `--model nvidia/Qwen3.6-35B-A3B-NVFP4` : Télécharge et charge le modèle 35B quantifié NVFP4.
- `--moe-backend auto` : Active le mode hybride automatique (GPU Cache + CPU AVX2 Workers).
- `--moe-cache-size 800` : Réserve 800 slots d'experts dans la VRAM GPU (~1.3 Go).
- `--num-tokens 32768` : Alloue 32 768 tokens de cache KV en VRAM (~640 Mo).
- `--max-prefill-length 2048` : **Essentiel** — découpe les longs prompts par blocs de 2048 tokens afin d'éliminer tout pic de mémoire VRAM lors de l'attention.
- `--memory-ratio 0.85` : Laisse une marge de sécurité de 15% de VRAM libre pour le système d'exploitation et le compositeur d'affichage.

### Étape 4 : Installation & Configuration des 4 Agents

Exécutez :
```bash
./scripts/03_install_agents.sh
./scripts/04_apply_configs.sh
```
Vos fichiers de configuration locaux (`~/.config/opencode/`, `~/.pi/agent/`, `~/.dsh/`, `~/.hermes/`) sont instantanément prêts.

---

## 🤖 Guide d'Utilisation des 4 Agents IA

Tous les agents sont configurés pour communiquer avec l'endpoint local `http://127.0.0.1:1919/v1`.

### 1. OpenCode
Agent de code avec interface TUI moderne dans le terminal :
```bash
# Mode interactif
opencode
# ou via le lanceur dynamique FreeToken :
ft launch opencode

# Mode commande unique
opencode -p "Analyse le fichier python/freetoken/engine/engine.py"
```

### 2. Pi Coding Agent (`pi`)
Agent minimaliste, extrêmement rapide et hautement extensible (créé par Armin Ronacher) :
```bash
# Mode interactif dans le terminal
pi

# Mode avec tâche initiale
pi "Explique l'encodage RoPE dans python/freetoken/layers/rotary.py"

# Mode audit en lecture seule (pas de modifications de fichiers)
pi --tools read,grep,find,ls "Recherche toutes les allocations de mémoire hôte"

# Mode non-interactif (batch)
pi -p "Quelles sont les dépendances C++ de ce projet ?"
```

### 3. DeepSeek Harness (`dsh`)
L'agent officiel open-source développé par DeepSeek AI (architecture 100% modulaire) :
```bash
# Lancer l'interface Web interactive dans le navigateur
dsh web
# ou via FreeToken :
ft launch dsh

# Mode tâche unique en ligne de commande (Headless)
dsh --profile headless "Exécute un audit de sécurité sur le serveur HTTP"
```

### 4. Hermes Agent
L'agent autonome de Nous Research doté de 82 compétences intégrées :
```bash
# Chat REPL classique
hermes

# Interface TUI moderne
hermes --tui

# Exécution d'une commande unique (One-shot)
hermes -z "Résume les classes principales du package freetoken.moe"
```

---

## 📊 Surveillance & Contrôle en Direct

Pour suivre les performances, la mémoire et le débit en temps réel :

```bash
# 1. Statistiques globales (Prefill t/s, Decode t/s, VRAM, KV Cache pages)
ft ctl stats

# 2. Historique des requêtes HTTP et temps de latence
ft ctl requests

# 3. Ajustement à chaud du cache KV sans redémarrage
ft ctl cache --kv 16384
```

---

## 🧪 Validation globale

Pour vérifier que l'ensemble des 4 agents répondent correctement :
```bash
./scripts/test_agents.sh
```

---

## 🐳 Déploiement Containerisé (Docker avec support NVIDIA GPU)

FreeToken peut être exécuté dans un conteneur Docker isolé avec support matériel complet (CUDA 13 + pass-through GPU NVIDIA RTX + mémoire partagée IPC) :

### 1. Construction de l'image Docker
```bash
cd ~/Repos/FreeTokenLab
docker build -t freetoken:latest .
```

### 2. Lancement avec `docker run`
```bash
./scripts/docker_run.sh "ornith-ai/Ornith-1.5-35B-A3B-NVFP4" 1919
```
Ou directement via la commande standard :
```bash
docker run -d \
  --gpus all \
  --ipc=host \
  --name freetoken-server \
  -p 1919:1919 \
  -v /mnt/storage/huggingface:/mnt/storage/huggingface \
  -v /mnt/storage/huggingface:/root/.cache/huggingface \
  -e HF_HOME=/mnt/storage/huggingface \
  freetoken:latest \
  --model ornith-ai/Ornith-1.5-35B-A3B-NVFP4 \
  --moe-backend auto \
  --moe-cache-size 800 \
  --num-tokens 32768 \
  --max-prefill-length 2048 \
  --memory-ratio 0.85 \
  --host 0.0.0.0 \
  --port 1919
```

### 3. Lancement avec `docker-compose`
```bash
docker compose up -d
```

### 4. Surveillance des logs du container
```bash
docker logs -f freetoken-server
```

---

## 🛠️ Industrialisation avec Makefile

Un `Makefile` complet automatise toutes les opérations courantes :

```bash
cd ~/Repos/FreeTokenLab

# Afficher l'aide de toutes les cibles
make help

# 1. Initialisation complète de la machine hôte et des agents
make init-all

# 2. Gestion de l'image et du container Docker
make docker-build       # Construction de l'image avec CUDA 13
make docker-run         # Lancement du container GPU en arrière-plan
make docker-logs        # Consultation des logs en direct
make docker-stop        # Arrêt du container

# 3. Tests & Santé
make healthcheck        # Vérification du serveur /v1/models
make test               # Test des 4 agents IA

# 4. Déploiement Docker Compose
make docker-compose-up
make docker-compose-down
```

---

## 🚀 Intégration Continue & Publication GHCR.io (GitHub Actions)

Deux workflows GitHub Actions automatisent le cycle de vie CI/CD :

1. **[`build-publish-ghcr.yml`](.github/workflows/build-publish-ghcr.yml)** :
   - Construit l'image Docker multi-stage optimisée NVIDIA CUDA 13.
   - Utilise le cache GitHub Actions (`type=gha`) pour des builds en < 2 minutes.
   - Publie automatiquement sur GitHub Container Registry : `ghcr.io/abdennebi/freetoken:latest` et `ghcr.io/abdennebi/freetoken:vX.Y.Z`.
   - Déclencheurs : Nouvelles releases, pushs sur `main` / tags `v*`, et déclenchement manuel (`workflow_dispatch`).

2. **[`upstream-sync-release.yml`](.github/workflows/upstream-sync-release.yml)** :
   - Sonde toutes les 6 heures le dépôt amont [`FlashML-org/FreeToken`](https://github.com/FlashML-org/FreeToken).
   - Dès qu'une nouvelle version amont est publiée, le workflow crée automatiquement le tag correspondant et déclenche la compilation et publication de la nouvelle image Docker sur **GHCR.io**.

---

## ⚡ Expérience "One-Click" avec DeepSeek Harness Web UI

Grâce à Docker Compose et Bubblewrap, vous pouvez démarrer l'ensemble de la stack (Serveur GPU + Interface Web DSH) en une seule commande :

```bash
cd ~/Repos/FreeTokenLab

# Démarrer le moteur GPU et l'interface Web DSH
make up

# Ouvrir l'interface dans votre navigateur
make open   # ou rendez-vous sur http://127.0.0.1:8080
```

### 🔒 Sandboxing avec Bubblewrap (`bwrap`)
Le conteneur `dsh-web` intègre nativement **Bubblewrap** en mode privilégié (`privileged: true`), permettant à l'agent DeepSeek Harness d'isoler l'exécution des commandes shell et des outils sans risque pour la machine hôte.

### 🛑 Arrêter la stack
```bash
make down
```
