.DEFAULT_GOAL := help
ENV          ?= dev
TF_DIR       := terraform/envs/$(ENV)

.PHONY: help init validate plan apply destroy deploy clean fmt

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform for ENV (default: dev)
	@echo "==> Initializing Terraform [$(ENV)]"
	terraform -chdir=$(TF_DIR) init -upgrade

fmt: ## Format all Terraform files
	@echo "==> Formatting Terraform files"
	terraform fmt -recursive terraform/

validate: init ## Validate Terraform configuration
	@echo "==> Validating [$(ENV)]"
	terraform -chdir=$(TF_DIR) validate

plan: validate ## Plan infrastructure changes
	@echo "==> Planning [$(ENV)]"
	terraform -chdir=$(TF_DIR) plan -out=tfplan

apply: ## Apply planned changes (requires prior plan)
	@echo "==> Applying [$(ENV)]"
	terraform -chdir=$(TF_DIR) apply tfplan

apply-auto: validate ## Plan and apply automatically (non-interactive)
	@echo "==> Auto-applying [$(ENV)] — use with caution!"
	terraform -chdir=$(TF_DIR) apply -auto-approve

destroy: ## Destroy all infrastructure for ENV
	@echo "==> [WARNING] Destroying [$(ENV)] infrastructure"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ]
	terraform -chdir=$(TF_DIR) destroy -auto-approve

output: ## Show Terraform outputs
	terraform -chdir=$(TF_DIR) output

deploy: ## Deploy application to EC2
	@echo "==> Deploying application [$(ENV)]"
	@bash scripts/deploy.sh $(ENV)

bootstrap-backend: ## Bootstrap S3 + DynamoDB remote state
	@echo "==> Bootstrapping remote state backend"
	terraform -chdir=terraform/shared/backend init
	terraform -chdir=terraform/shared/backend apply -auto-approve

clean: ## Remove local Terraform artifacts
	@find terraform/ -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find terraform/ -name "tfplan" -delete 2>/dev/null || true
	@find terraform/ -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "==> Cleaned local Terraform artifacts"

docker-up: ## Start full stack locally with Docker Compose
	docker compose -f docker/docker-compose.yml up -d --build

docker-down: ## Stop local Docker Compose stack
	docker compose -f docker/docker-compose.yml down

docker-logs: ## Tail Docker Compose logs
	docker compose -f docker/docker-compose.yml logs -f

app-build: ## Build Spring Boot application JAR
	./app/api/mvnw -f app/api/pom.xml clean package -DskipTests

lint: fmt validate ## Run all linting and validation checks
