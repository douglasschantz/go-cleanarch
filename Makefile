ifeq ($(wildcard cmd/ordersystem/.env),)
    $(shell cp .env.example .env)
endif

include cmd/ordersystem/.env
export

DOCKER_COMPOSE_FILE=docker-compose.yaml

## ---------- UTILS
.PHONY: help
help: ## Show this menu
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: clean-temp
clean-temp: ## Clean all temp files
	@rm -rf tmp/

## ---------- INSTALL
.PHONY: install-migrate
install-migrate: ## install migrate
	@if [ ! -f /usr/local/bin/migrate ]; then \
		wget -O /tmp/migrate.tar.gz https://github.com/golang-migrate/migrate/releases/download/v4.17.0/migrate.linux-amd64.tar.gz; \
		tar -C /tmp -xzvf /tmp/migrate.tar.gz; \
		sudo mv /tmp/migrate /usr/local/bin/migrate; \
	else \
		echo "Great, you already have [migrate] installed"; \
	fi

.PHONY: install
install: install-migrate ## install all requirements

## ---------- MIGRATIONS
.PHONY: migration_init
migration_init: ## init migrations
	@migrate create -ext=sql -dir=sql/migrations -seq init

.PHONY: migration_up
migration_up: ## run migrations up
	@migrate -path=sql/migrations -database "mysql://root:${DB_PASSWORD}@tcp(localhost:3306)/${DB_NAME}" -verbose up
	@docker exec -it -e MYSQL_PASSWORD=root mysql mysql -uroot -p${DB_PASSWORD} -D ${DB_NAME} -e "show tables;"

.PHONY: migration_down
migration_down: ## run migrations down
	@migrate -path=sql/migrations -database "mysql://root:${DB_PASSWORD}@tcp(localhost:3306)/${DB_NAME}" -verbose down --all
	@docker exec -it -e MYSQL_PASSWORD=root mysql mysql -uroot -p${DB_PASSWORD} -D ${DB_NAME} -e "show tables;"

.PHONY: migration_clean
migration_clean: migration_down migration_up ## run migration down and up to cleanup all data

## ---------- MAIN
.PHONY: test
test: ## Run unit-tests
	@go test -v ./...

.PHONY: build
build: ## Build the container image
	@docker build -t go-cleanarch:dev -f Dockerfile .

.PHONY: up
up: ## Put the compose containers up
	@docker-compose up -d

.PHONY: down
down: ## Put the compose containers down
	@docker-compose down

# Docker support

FILES := $(shell docker ps -aq)

.PHONY: down-local
down-local:
	@docker stop $(FILES)
	@docker rm $(FILES)

logs-local:
	@docker logs -f $(FILES)

.PHONY:clean
clean:
	@echo "Cleaning Docker containers and images..."
	@docker compose -f $(DOCKER_COMPOSE_FILE) down -v --rmi all
	@docker system prune -f

.PHONY: run
run: ## Run the rest-api, grpc and graphql servers
	@cd cmd/ordersystem && go run main.go wire_gen.go
	@cd -