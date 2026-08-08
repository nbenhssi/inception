NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml

DATA_DIR = /home/nbenhssi/data
DB_DIR = $(DATA_DIR)/mariadb
WP_DIR = $(DATA_DIR)/wordpress

all: up

dirs:
	mkdir -p $(DB_DIR)
	mkdir -p $(WP_DIR)

build: dirs
	$(COMPOSE) build

up: dirs
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart: down up

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down --rmi all

fclean:
	$(COMPOSE) down --rmi all --volumes --remove-orphans
	docker system prune -af
	sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all dirs build up down start stop restart logs ps clean fclean re