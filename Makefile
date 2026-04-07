# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: brivera <brivera@student.42madrid.com>     +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/03/26 17:38:02 by brivera           #+#    #+#              #
#    Updated: 2026/03/28 20:01:56 by brivera          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

RED          = \033[91;1m
GREEN        = \033[92;1m
CYAN         = \033[96;1m
CLEAR_COLOR  = \033[0m

NAME    = inception
COMPOSE = docker compose -f srcs/docker-compose.yml
SRCS    = $(shell find srcs -type f)

# Load environment variables
include srcs/.env

# Load secrets
DB_PASSWORD := $(shell cat secrets/db_password 2>/dev/null)
DB_ROOT_PASSWORD := $(shell cat secrets/db_root_password 2>/dev/null)

all: $(NAME)

$(NAME): $(SRCS) secrets/server.crt
	@echo "$(CYAN)[$(NAME)] Building and starting containers...$(CLEAR_COLOR)"
	@$(COMPOSE) up -d
	@echo "$(GREEN)[$(NAME)] Setup complete!$(CLEAR_COLOR)"
	@touch $(NAME)

dirs:
	@echo "$(CYAN)[$(NAME)] Creating directories...$(CLEAR_COLOR)"
	@mkdir -p $(HOME)/data/wordpress
	@mkdir -p $(HOME)/data/mariadb
	@mkdir -p secrets

secrets/server.crt: | dirs
	@echo "$(CYAN)[$(NAME)] Generating TLS certificate...$(CLEAR_COLOR)"
	@openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout secrets/server.key \
		-out    secrets/server.crt \
		-subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=$(USER).42.fr"
	@echo "$(GREEN)[$(NAME)] Certificate created!$(CLEAR_COLOR)"

cert: dirs
	@echo "$(CYAN)[$(NAME)] Regenerating TLS certificate...$(CLEAR_COLOR)"
	@rm -f secrets/server.crt secrets/server.key
	@$(MAKE) secrets/server.crt

down:
	@echo "$(CYAN)[$(NAME)] Stopping containers...$(CLEAR_COLOR)"
	@$(COMPOSE) down
	@echo "$(GREEN)[$(NAME)] Containers stopped!$(CLEAR_COLOR)"

stop:
	@echo "$(CYAN)[$(NAME)] Pausing containers...$(CLEAR_COLOR)"
	@$(COMPOSE) stop
	@echo "$(GREEN)[$(NAME)] Containers paused!$(CLEAR_COLOR)"

start:
	@echo "$(CYAN)[$(NAME)] Starting containers...$(CLEAR_COLOR)"
	@$(COMPOSE) start
	@echo "$(GREEN)[$(NAME)] Containers started!$(CLEAR_COLOR)"

ps:
	@$(COMPOSE) ps

status: ps

logs:
	@$(COMPOSE) logs

db:
	@echo "$(CYAN)[$(NAME)] Accessing MariaDB as wpuser...$(CLEAR_COLOR)"
	docker exec -it mariadb mysql -u $(MYSQL_USER) -p$(DB_PASSWORD)

db-root:
	@echo "$(CYAN)[$(NAME)] Accessing MariaDB as root...$(CLEAR_COLOR)"
	docker exec -it mariadb mysql -u root -p$(DB_ROOT_PASSWORD)

db-show:
	@echo "$(CYAN)[$(NAME)] Databases:$(CLEAR_COLOR)"
	docker exec mariadb mysql -u $(MYSQL_USER) -p$(DB_PASSWORD) -e "SHOW DATABASES;"
	@echo "\n$(CYAN)[$(NAME)] Users:$(CLEAR_COLOR)"
	docker exec mariadb mysql -u root -p$(DB_ROOT_PASSWORD) -e "SELECT User, Host FROM mysql.user;"

clean:
	@echo "$(RED)[$(NAME)] Cleaning volumes and containers...$(CLEAR_COLOR)"
	@$(COMPOSE) down -v
	@rm -f $(NAME)
	@echo "$(GREEN)[$(NAME)] Clean complete!$(CLEAR_COLOR)"

fclean:
	@echo "$(RED)[$(NAME)] Full cleanup...$(CLEAR_COLOR)"
	@$(COMPOSE) down -v --rmi all --remove-orphans
	@docker volume ls -q --filter label=com.docker.compose.project=inception \
		| xargs -r docker volume rm
	@docker system prune -af
	@sudo rm -rf $(HOME)/data/wordpress/*
	@sudo rm -rf $(HOME)/data/mariadb/*
	@sudo rm -rf $(HOME)/data/*
	@rm -f secrets/server.crt secrets/server.key
	@rm -f $(NAME)
	@echo "$(GREEN)[$(NAME)] Full cleanup complete!$(CLEAR_COLOR)"

re: fclean all

help:
	@echo "Targets disponibles:"
	@echo "  $(GREEN)all$(CLEAR_COLOR)		— build y start"
	@echo "  $(GREEN)down$(CLEAR_COLOR)		— parar y eliminar contenedores"
	@echo "  $(GREEN)stop$(CLEAR_COLOR)		— parar sin eliminar"
	@echo "  $(GREEN)start$(CLEAR_COLOR)	— arrancar contenedores parados"
	@echo "  $(GREEN)ps$(CLEAR_COLOR)		— estado de contenedores"
	@echo "  $(GREEN)logs$(CLEAR_COLOR)		— ver logs"
	@echo "  $(GREEN)db$(CLEAR_COLOR)		— acceder a MariaDB como wpuser"
	@echo "  $(GREEN)db-root$(CLEAR_COLOR)	— acceder a MariaDB como root"
	@echo "  $(GREEN)db-show$(CLEAR_COLOR)	— mostrar bases de datos y usuarios"
	@echo "  $(GREEN)cert$(CLEAR_COLOR)		— regenerar certificado TLS"
	@echo "  $(RED)clean$(CLEAR_COLOR)   	— down + borrar volúmenes"
	@echo "  $(RED)fclean$(CLEAR_COLOR)  	— limpieza total (imágenes, volúmenes, datos)"
	@echo "  $(GREEN)re $(CLEAR_COLOR)		— fclean + all"

.PHONY: all dirs down stop start ps status logs db db-root db-show cert clean fclean re help
