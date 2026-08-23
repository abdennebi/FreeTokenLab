# ⚡ FreeTokenLab — Plateforme IA Locale Sécurisée

[![CI/CD & GHCR Release](https://github.com/abdennebi/FreeTokenLab/actions/workflows/build-publish-ghcr.yml/badge.svg)](https://github.com/abdennebi/FreeTokenLab/actions/workflows/build-publish-ghcr.yml)
[![Défense en Profondeur](https://img.shields.io/badge/Sécurité-5%20Niveaux%20de%20Défense-red.svg)](README_FR.md#-architecture-axée-sur-la-sécurité-défense-en-profondeur)
[![Landlock LSM Noyau](https://img.shields.io/badge/nono-Confinement%20Noyau%20Landlock-success.svg)](https://nono.sh)
[![Docker Multi-Arch](https://img.shields.io/badge/Architecture-AMD64%20%7C%20ARM64-blue.svg)](https://github.com/abdennebi/FreeTokenLab/pkgs/container/freetoken)
[![CUDA 13.0](https://img.shields.io/badge/NVIDIA-CUDA%2013.0-green.svg)](https://developer.nvidia.com/cuda-toolkit)
[![DeepSeek Harness](https://img.shields.io/badge/DSH-v0.1.1--rc.2-blueviolet.svg)](https://github.com/deepseek-ai/deepseek-harness)
[![Dependabot](https://img.shields.io/badge/Dependabot-Actif-brightgreen.svg?logo=dependabot)](https://github.com/abdennebi/FreeTokenLab/security/dependabot)
[![License](https://img.shields.io/badge/Licence-Apache%202.0-orange.svg)](LICENSE)
[![English Documentation](https://img.shields.io/badge/Lang-English-blue.svg)](README.md)

**FreeTokenLab** est une plateforme de développement IA locale **conçue avec une approche stricte de sécurité par conception (Security by Design)** et **zéro fuite de données**. Elle associe l'inférence ultra-rapide de modèles **Mixture-of-Experts (MoE) de 35 milliards de paramètres** sur GPU grand public (**8 Go de VRAM**) à l'agent de code autonome **DeepSeek Harness (`dsh`)**, protégé par **5 couches concentriques de sécurité et de sandboxing noyau**.

---

## 🛡️ Architecture Axée sur la Sécurité (Défense en Profondeur)

FreeTokenLab a été spécialement conçu pour permettre aux développeurs d'utiliser des agents autonomes et d'exécuter du code généré par IA sans risquer l'exfiltration de données, le vol de clés secrètes ou la corruption du système hôte.

```mermaid
flowchart TD
    subgraph L5 ["🔒 Niveau 5 : Intégrité de la Supply Chain & Images Pinned"]
        SC["Audit Dependabot Hebdomadaire + Tags GHCR Immuables + Caching Multi-Couches"]
        subgraph L4 ["🔒 Niveau 4 : Isolation Matérielle & Mémoire DMA PCIe"]
            MEM["ulimits: memlock=-1 (Streaming DMA PCIe direct vers GPU en mémoire verrouillée)"]
            subgraph L3 ["🔒 Niveau 3 : Confinement Noyau Linux Landlock LSM (nono)"]
                NONO["Bac à sable nono (Actif par défaut dans Docker & Hôte)\n• Blocage strict : ~/.ssh, ~/.aws, ~/.gnupg, /etc\n• Accès r+w exclusif : /workspace/project & ~/.dsh"]
                subgraph L2 ["🔒 Niveau 2 : Isolation des Processus & Namespaces (Bubblewrap)"]
                    BWRAP["Namespaces Linux bwrap (Confinement des commandes shell de l'agent)"]
                    subgraph L1 ["🔒 Niveau 1 : Zéro Exfiltration (Inférence 100% Locale)"]
                        LLM["Moteur GPU Local FreeToken\n(Aucun appel Cloud • Clés factices • 100% Hors-Ligne)"]
                    end
                end
            end
        end
    end

    classDef sec fill:#1a1d20,stroke:#e63946,stroke-width:2px,color:#fff;
    class L1,L2,L3,L4,L5 sec;
```

### 1. 🔒 Niveau 1 : Zéro Exfiltration de Données (Inférence 100% Hors-Ligne)
- **Aucun appel réseau externe** : Les inférences s'exécutent entièrement en local sur votre GPU et votre RAM hôte. Aucun morceau de code, aucun prompt et aucun secret ne quittent votre machine physique.
- **Clés d'API factices pré-provisionnées** : La stack utilise des clés factices (`dummy-key`) locales pour empêcher tout routage involontaire vers des API cloud publiques.

### 2. 🛡️ Niveau 2 : Confinement Noyau Linux Landlock LSM (`nono`)
- **Sandboxing automatique au démarrage** : Dès que vous lancez `docker compose up`, `dsh` est automatiquement encapsulé sous `nono` (Linux Landlock LSM).
- **Protection absolue des secrets hôtes** : L'accès en lecture/écriture à vos dossiers sensibles (`~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.bashrc`, `/etc`) est strictement bloqué au niveau des appels système du noyau Linux.
- **Principe du Moindre Privilège** : L'agent IA n'a de droits d'écriture que sur votre répertoire de projet actif (`/workspace/project`) et sa configuration locale (`~/.dsh`).

### 3. 📦 Niveau 3 : Isolation des Namespaces (`Bubblewrap`)
- DeepSeek Harness encapsule chaque outil shell et exécution de commande dans des **namespaces Linux non privilégiés** (`bwrap`), empêchant tout risque d'élévation de privilèges ou d'évasion de conteneur.

### 4. ⚡ Niveau 4 : Contrôle Matériel DMA & Mémoire Verrouillée (`memlock`)
- **`ulimits: memlock: -1`** : Permet à PyTorch et FreeToken de verrouiller les tampons de RAM physique pour le transfert direct haute vitesse (Direct Memory Access / DMA via PCIe Gen3/4 x16) des experts MoE, éliminant les fautes de page tout en isolant l'espace d'adressage.

### 5. 🔄 Niveau 5 : Sécurité de la Chaîne d'Approvisionnement (Supply Chain)
- Images Docker allégées (Node 22 Bookworm Slim & CUDA Minimal), tags immuables épinglés, et surveillance continue des vulnérabilités de dépendances via **Dependabot**.

---

## 🌟 Points Forts

- **🚀 Expérience One-Click Instantanée** : Démarrage complet de la stack (moteur GPU + Web UI DSH sécurisée) en une seule commande (`make up`).
- **🧠 Modèle MoE 35B sur GPU 8 Go** : Fait tourner **`Ornith-1.5-35B-A3B-NVFP4`** avec un **contexte de 65 536 tokens (64k)** grâce au cache MoE intelligent (800 slots experts en VRAM, streaming dynamique du reste via PCIe).
- **🌐 Interface Web DeepSeek Harness** : Environnement complet dans le navigateur (`http://127.0.0.1:8080`) avec chat interactif, explorateur de fichiers, visualiseur de diffs git et historique de sessions.
- **📦 Images Pré-compilées Multi-Arch** : Aucune compilation locale requise ; les images `linux/amd64` et `linux/arm64` sont téléchargées directement depuis **GHCR.io**.

---

## 🏗️ Schéma Fonctionnel de la Stack

```mermaid
flowchart LR
    subgraph MachineHote ["Machine Hôte"]
        Navigateur["🌐 Navigateur Web\nhttp://127.0.0.1:8080"]
        DossierProjet["📁 Répertoire du Projet\n(/workspace/project)"]
        CacheHF["💾 Cache Modèles\n(/mnt/storage/huggingface)"]
    end

    subgraph StackDocker ["Stack Docker Compose (One-Click)"]
        direction TB
        subgraph S1 ["1. Service : freetoken"]
            FT["Moteur GPU FreeToken\n(Port 1919)\nContexte 64k • 800 MoE Cache"]
            HC["Healthcheck HTTP\n(GET /v1/models)"]
        end

        subgraph S2 ["2. Service : dsh"]
            DSH["DeepSeek Harness Web UI\n(Port 8080)"]
            NONO["Bac à sable nono\n(Filtrage Syscall Landlock)"]
            BWRAP["Moteur Bubblewrap\n(Isolation Namespaces)"]
        end

        FT --> HC
        HC -->|depends_on: service_healthy| DSH
        DSH -->|http://127.0.0.1:1919/v1| FT
        DSH -.-> NONO
        DSH -.-> BWRAP
    end

    Navigateur -->|HTTP 8080| DSH
    DossierProjet -->|Montage Volume| DSH
    CacheHF -->|Montage Volume| FT
```

---

## ⚡ Démarrage Rapide

### Prérequis
- **Système Linux** (x86_64 ou ARM64)
- **Docker** et **Docker Compose v2**
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) (Pilotes NVIDIA >= 550)

### 1. Cloner et Lancer
```bash
git clone https://github.com/abdennebi/FreeTokenLab.git
cd FreeTokenLab

# Démarre FreeToken et DSH avec confinement nono automatique
make up
```

### 2. Accéder à l'Interface Web
Ouvrez votre navigateur sur **[http://127.0.0.1:8080](http://127.0.0.1:8080)**.

### 3. Arrêter la Stack
```bash
make down
```

---

## 🛠️ Commandes Disponibles

| Commande | Description |
| :--- | :--- |
| **`make up`** | 🚀 Démarre l'ensemble de la stack (téléchargement automatique des images GHCR). |
| **`make down`** | 🛑 Arrête et supprime les conteneurs de la stack. |
| **`make open`** | 🌐 Ouvre l'interface Web DSH dans le navigateur par défaut. |
| **`make logs`** | 📜 Affiche en direct les logs combinés de `freetoken` et `dsh`. |
| **`make ps`** | 📊 Vérifie l'état de santé des conteneurs. |
| **`make pull`** | ⬇️ Met à jour les images épinglées depuis GHCR.io. |
| **`make dsh-secure`** | 🔒 Lance DSH en natif sur l'hôte sous confinement noyau `nono` (Landlock). |
| **`make dsh-headless-secure`** | 🛡️ Exécute une tâche IA headless sécurisée sur l'hôte via `nono`. |
| **`make healthcheck`** | 🔍 Teste la disponibilité de l'API FreeToken (`/v1/models`). |
| **`make docker-multiarch`** | 🌍 Compile et publie les images multi-architectures (`amd64` + `arm64`). |

---

## 📊 Matrice Comparative de Sécurité

| Fonctionnalité de Sécurité | FreeTokenLab (Par Défaut) | Outils LLM Locaux Standards | Agents LLM Cloud |
| :--- | :---: | :---: | :---: |
| **Filtrage Noyau Landlock LSM (`nono`)** | ✅ **Actif (Systématique)** | ❌ Aucun | ❌ Aucun |
| **Sandboxing Namespaces (`bwrap`)** | ✅ **Actif (Systématique)** | ❌ Rare | ❌ Aucun |
| **Risque d'Exfiltration de Données** | 🛡️ **Zéro (100% Hors-Ligne)** | ⚠️ Partiel | 🚨 Élevé (API Cloud) |
| **Protection des Clés d'Accès (`~/.ssh`)** | 🛡️ **Verrouillé au Noyau** | ❌ Exposé | ⚠️ Risque de fuite |
| **Streaming DMA RAM/GPU (`memlock`)** | ✅ **Optimisé et Isolé** | ❌ Mémoire non verrouillée | N/A |
| **Audit Automatisé des Dépendances** | ✅ **Actif (Dependabot)** | ❌ Manuel | ⚠️ Propriétaire |

---

## 📜 Licence et Remerciements

- Distribué sous licence [Apache 2.0](LICENSE).
- Propulsé par [FreeToken](https://github.com/FlashML-org/FreeToken), [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) et [nono](https://nono.sh).
