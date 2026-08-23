# ==============================================================================
# FreeTokenLab — Makefile d'Industrialisation et d'Automatisation
# ==============================================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Variables
MODEL ?= ornith-ai/Ornith-1.5-35B-A3B-NVFP4
PORT ?= 1919
DSH_PORT ?= 8080
IMAGE_NAME ?= freetoken
REGISTRY ?= ghcr.io
OWNER ?= abdennebi
TAG ?= latest
PLATFORMS ?= linux/amd64,linux/arm64

# Couleurs pour l'affichage
CYAN  := \033[36m
GREEN := \033[32m
YELLOW:= \033[33m
RED   := \033[31m
RESET := \033[0m

.PHONY: help
help: ## Affiche l'aide et la liste des commandes disponibles
	@echo -e "$(CYAN)══════════════════════════════════════════════════════════════$(RESET)"
	@echo -e "$(GREEN)  FreeTokenLab — Commandes d'automatisation & Déploiement$(RESET)"
	@echo -e "$(CYAN)══════════════════════════════════════════════════════════════$(RESET)"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-25s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ==============================================================================
# 1. Déploiement "One-Click" Prêt à l'Emploi (Pull GHCR Automatique)
# ==============================================================================

.PHONY: up
up: ## Lance la stack One-Click (télécharge automatiquement les images précompilées de GHCR)
	@echo -e "$(GREEN)→ Démarrage de la stack Docker Compose (FreeToken GPU + DSH Web UI)...$(RESET)"
	@docker compose up -d
	@echo -e "$(GREEN)══════════════════════════════════════════════════════════════$(RESET)"
	@echo -e "$(GREEN)  ✓ Serveur Inférence : http://127.0.0.1:$(PORT)/v1$(RESET)"
	@echo -e "$(GREEN)  ✓ DeepSeek Harness  : http://127.0.0.1:$(DSH_PORT)$(RESET)"
	@echo -e "$(GREEN)══════════════════════════════════════════════════════════════$(RESET)"

.PHONY: pull
pull: ## Télécharge les dernières images précompilées officielles depuis GHCR.io
	@echo -e "$(GREEN)→ Téléchargement des dernières images depuis GHCR.io...$(RESET)"
	@docker compose pull

.PHONY: down
down: ## Éteint proprement l'ensemble des conteneurs (docker compose down)
	@echo -e "$(YELLOW)→ Arrêt des services Docker Compose...$(RESET)"
	@docker compose down

.PHONY: open
open: ## Ouvre l'interface Web de DeepSeek Harness dans votre navigateur
	@echo -e "$(GREEN)→ Ouverture de http://127.0.0.1:$(DSH_PORT)...$(RESET)"
	@xdg-open http://127.0.0.1:$(DSH_PORT) 2>/dev/null || sensible-browser http://127.0.0.1:$(DSH_PORT) 2>/dev/null || open http://127.0.0.1:$(DSH_PORT) 2>/dev/null || echo "Ouvrez http://127.0.0.1:$(DSH_PORT) dans votre navigateur."

.PHONY: ps
ps: ## Affiche l'état des conteneurs Compose
	@docker compose ps

# ==============================================================================
# 2. Construction Locale des Images (Pour Développeurs & Contributeurs)
# ==============================================================================

.PHONY: docker-build-all
docker-build-all: docker-build docker-build-dsh ## Compile localement les deux images Docker (Moteur GPU + DSH Web)

.PHONY: docker-build
docker-build: ## Compile localement l'image Docker FreeToken GPU
	@echo -e "$(GREEN)→ Compilation locale de $(REGISTRY)/$(OWNER)/$(IMAGE_NAME):$(TAG)...$(RESET)"
	@docker compose build freetoken

.PHONY: docker-build-dsh
docker-build-dsh: ## Compile localement l'image Docker DeepSeek Harness Web
	@echo -e "$(GREEN)→ Compilation locale de $(REGISTRY)/$(OWNER)/freetoken-dsh:latest...$(RESET)"
	@docker compose build dsh

.PHONY: docker-multiarch
docker-multiarch: ## Construit et publie les images Multi-Arch (linux/amd64,linux/arm64) sur GHCR
	@echo -e "$(GREEN)→ Construction Multi-Arch $(PLATFORMS) pour FreeToken et DSH...$(RESET)"
	@docker buildx build --platform $(PLATFORMS) -t $(REGISTRY)/$(OWNER)/$(IMAGE_NAME):$(TAG) --push .
	@docker buildx build --platform $(PLATFORMS) -t $(REGISTRY)/$(OWNER)/freetoken-dsh:latest -f Dockerfile.dsh --push .
	@echo -e "$(GREEN)✅ Publication Multi-Arch terminée sur $(REGISTRY)/$(OWNER)/$(RESET)"

# ==============================================================================
# 3. Installation & Environnement Hôte Natif (Optionnel sans Docker)
# ==============================================================================

.PHONY: init-all
init-all: setup build agents-install agents-config ## Déploiement natif sur l'hôte en une étape (Hôte + Agents)
	@echo -e "$(GREEN)✅ Initialisation native terminée !$(RESET)"

.PHONY: setup
setup: ## Installe les paquets système, Node.js, uv et initialise le venv Python sur l'hôte
	@./scripts/01_setup_host.sh

.PHONY: build
build: ## Compile les extensions C++ natives FreeToken (_pinned_tensor & _cpu_moe) sur l'hôte
	@./scripts/02_build_freetoken.sh

.PHONY: agents-install
agents-install: ## Installe les 4 agents IA sur l'hôte (OpenCode, Pi, DSH, Hermes)
	@./scripts/03_install_agents.sh

.PHONY: agents-config
agents-config: ## Applique les configurations optimales aux 4 agents sur l'hôte
	@./scripts/04_apply_configs.sh

.PHONY: serve
serve: ## Démarre le serveur FreeToken en natif sur l'hôte
	@./scripts/start_server.sh "$(MODEL)" 127.0.0.1 "$(PORT)"

.PHONY: test
test: ## Teste les 4 agents contre le serveur actif
	@./scripts/test_agents.sh

# ==============================================================================
# 4. Diagnostics & Nettoyage
# ==============================================================================

.PHONY: healthcheck
healthcheck: ## Vérifie l'état de l'API FreeToken
	@curl -sf http://127.0.0.1:$(PORT)/v1/models | jq . || echo -e "$(RED)❌ Le serveur ne répond pas sur le port $(PORT)$(RESET)"

.PHONY: logs
logs: ## Affiche les logs en direct des conteneurs
	@docker compose logs -f

.PHONY: clean
clean: ## Nettoie les caches de build Python et temporaires
	@echo -e "$(YELLOW)→ Nettoyage des caches...$(RESET)"
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@rm -rf build dist .pytest_cache
	@echo -e "$(GREEN)✓ Nettoyage terminé.$(RESET)"
