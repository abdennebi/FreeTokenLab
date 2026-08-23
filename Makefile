# ==============================================================================
# FreeTokenLab — Makefile d'Industrialisation et d'Automatisation
# ==============================================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Variables
MODEL ?= ornith-ai/Ornith-1.5-35B-A3B-NVFP4
PORT ?= 1919
IMAGE_NAME ?= freetoken
REGISTRY ?= ghcr.io
OWNER ?= abdennebi
TAG ?= latest

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
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ==============================================================================
# 1. Installation & Environnement Hôte
# ==============================================================================

.PHONY: setup
setup: ## Installe les paquets système, Node.js, uv et initialise le venv Python
	@echo -e "$(GREEN)→ Exécution de 01_setup_host.sh...$(RESET)"
	@./scripts/01_setup_host.sh

.PHONY: build
build: ## Compile les extensions C++ natives FreeToken (_pinned_tensor & _cpu_moe)
	@echo -e "$(GREEN)→ Exécution de 02_build_freetoken.sh...$(RESET)"
	@./scripts/02_build_freetoken.sh

.PHONY: agents-install
agents-install: ## Installe les 4 agents IA (OpenCode, Pi, DSH, Hermes)
	@echo -e "$(GREEN)→ Exécution de 03_install_agents.sh...$(RESET)"
	@./scripts/03_install_agents.sh

.PHONY: agents-config
agents-config: ## Applique les configurations optimales aux 4 agents
	@echo -e "$(GREEN)→ Exécution de 04_apply_configs.sh...$(RESET)"
	@./scripts/04_apply_configs.sh

.PHONY: init-all
init-all: setup build agents-install agents-config ## Déploiement complet en une seule étape (Hôte + Agents)
	@echo -e "$(GREEN)✅ Initialisation complète réussie !$(RESET)"

# ==============================================================================
# 2. Exécution Locale Hôte
# ==============================================================================

.PHONY: serve
serve: ## Démarre le serveur FreeToken en natif sur l'hôte (ex: make serve MODEL=...)
	@echo -e "$(GREEN)→ Démarrage du serveur FreeToken (Modèle: $(MODEL), Port: $(PORT))...$(RESET)"
	@./scripts/start_server.sh "$(MODEL)" 127.0.0.1 "$(PORT)"

.PHONY: test
test: ## Teste les 4 agents contre le serveur actif
	@echo -e "$(GREEN)→ Test des 4 agents...$(RESET)"
	@./scripts/test_agents.sh

# ==============================================================================
# 3. Docker & Containerisation GPU
# ==============================================================================

.PHONY: docker-build
docker-build: ## Construit l'image Docker locale avec support NVIDIA GPU
	@echo -e "$(GREEN)→ Construction de l'image Docker $(IMAGE_NAME):$(TAG)...$(RESET)"
	@docker build -t $(IMAGE_NAME):$(TAG) -t $(REGISTRY)/$(OWNER)/$(IMAGE_NAME):$(TAG) .

.PHONY: docker-run
docker-run: ## Lance le container FreeToken avec support GPU NVIDIA (détaché)
	@echo -e "$(GREEN)→ Lancement du container $(IMAGE_NAME)-server...$(RESET)"
	@docker rm -f $(IMAGE_NAME)-server 2>/dev/null || true
	@docker run -d \
		--gpus all \
		--ipc=host \
		--name $(IMAGE_NAME)-server \
		-p $(PORT):1919 \
		-v /mnt/storage/huggingface:/mnt/storage/huggingface \
		-v /mnt/storage/huggingface:/root/.cache/huggingface \
		-e HF_HOME=/mnt/storage/huggingface \
		$(IMAGE_NAME):$(TAG) \
		--model "$(MODEL)" \
		--moe-backend auto \
		--moe-cache-size 800 \
		--num-tokens 32768 \
		--max-prefill-length 2048 \
		--memory-ratio 0.85 \
		--host 0.0.0.0 \
		--port 1919
	@echo -e "$(GREEN)✓ Container $(IMAGE_NAME)-server démarré sur http://127.0.0.1:$(PORT)$(RESET)"

.PHONY: docker-stop
docker-stop: ## Arrête le container FreeToken
	@echo -e "$(YELLOW)→ Arrêt du container $(IMAGE_NAME)-server...$(RESET)"
	@docker stop $(IMAGE_NAME)-server || true

.PHONY: docker-logs
docker-logs: ## Affiche les logs en direct du container FreeToken
	@docker logs -f $(IMAGE_NAME)-server

.PHONY: docker-compose-up
docker-compose-up: ## Lance le service via Docker Compose
	@docker compose up -d

.PHONY: docker-compose-down
docker-compose-down: ## Arrête le service Docker Compose
	@docker compose down

.PHONY: docker-push
docker-push: ## Pousse l'image Docker sur GHCR.io
	@echo -e "$(GREEN)→ Publication sur $(REGISTRY)/$(OWNER)/$(IMAGE_NAME):$(TAG)...$(RESET)"
	@docker push $(REGISTRY)/$(OWNER)/$(IMAGE_NAME):$(TAG)

# ==============================================================================
# 4. Maintenance & Nettoyage
# ==============================================================================

.PHONY: healthcheck
healthcheck: ## Vérifie l'état de l'API FreeToken
	@curl -sf http://127.0.0.1:$(PORT)/v1/models | jq . || echo -e "$(RED)❌ Le serveur ne répond pas sur le port $(PORT)$(RESET)"

.PHONY: clean
clean: ## Nettoie les caches de build Python et temporaires
	@echo -e "$(YELLOW)→ Nettoyage des caches...$(RESET)"
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@rm -rf build dist .pytest_cache
	@echo -e "$(GREEN)✓ Nettoyage terminé.$(RESET)"
