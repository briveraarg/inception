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
	@mkdir -p $(HOME)/data/redis
	@mkdir -p $(HOME)/data/static
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


# -------- BONUS -------- #
bonus: $(SRCS) secrets/server.crt
	@echo "$(CYAN)[$(NAME)] Building and starting containers with Redis, FTP and Static...$(CLEAR_COLOR)"
	@docker compose -f srcs_bonus/docker-compose.bonus.yml up -d
	@echo "$(GREEN)[$(NAME)] Bonus setup complete!$(CLEAR_COLOR)"

bonus-down:
	@echo "$(CYAN)[$(NAME)] Stopping bonus containers...$(CLEAR_COLOR)"
	@docker compose -f srcs_bonus/docker-compose.bonus.yml down
	@echo "$(GREEN)[$(NAME)] Bonus containers stopped!$(CLEAR_COLOR)"

bonus-stop:
	@echo "$(CYAN)[$(NAME)] Pausing bonus containers...$(CLEAR_COLOR)"
	@docker compose -f srcs_bonus/docker-compose.bonus.yml stop
	@echo "$(GREEN)[$(NAME)] Bonus containers paused!$(CLEAR_COLOR)"

bonus-start:
	@echo "$(CYAN)[$(NAME)] Starting bonus containers...$(CLEAR_COLOR)"
	@docker compose -f srcs_bonus/docker-compose.bonus.yml start
	@echo "$(GREEN)[$(NAME)] Bonus containers started!$(CLEAR_COLOR)"

bonus-ps:
	@docker compose -f srcs_bonus/docker-compose.bonus.yml ps

bonus-logs:
	@docker compose -f srcs_bonus/docker-compose.bonus.yml logs

bonus-clean:
	@echo "$(RED)[$(NAME)] Cleaning bonus volumes and containers...$(CLEAR_COLOR)"
	@docker compose -f srcs_bonus/docker-compose.bonus.yml down -v
	@echo "$(GREEN)[$(NAME)] Bonus clean complete!$(CLEAR_COLOR)"

bonus-fclean:
	@echo "$(RED)[$(NAME)] Full bonus cleanup...$(CLEAR_COLOR)"
	@docker compose -f srcs_bonus/docker-compose.bonus.yml down -v --rmi all --remove-orphans
	@docker volume ls -q --filter label=com.docker.compose.project=srcs_bonus \
		| xargs -r docker volume rm
	@docker system prune -af
	@sudo rm -rf $(HOME)/data/redis/*
	@sudo rm -rf $(HOME)/data/static/*
	@echo "$(GREEN)[$(NAME)] Full bonus cleanup complete!$(CLEAR_COLOR)"

bonus-redis-cli:
	@echo "$(CYAN)[$(NAME)] Connecting to Redis CLI...$(CLEAR_COLOR)"
	docker exec -it redis redis-cli

bonus-ftp-cli:
	@echo "$(CYAN)[$(NAME)] Connecting to FTP...$(CLEAR_COLOR)"
	docker exec -it ftp /bin/sh

help:
	@echo "Available targets:"
	@echo "  $(GREEN)all$(CLEAR_COLOR)		— build and start"
	@echo "  $(GREEN)down$(CLEAR_COLOR)		— stop and remove containers"
	@echo "  $(GREEN)stop$(CLEAR_COLOR)		— pause without removing"
	@echo "  $(GREEN)start$(CLEAR_COLOR)	— restart paused containers"
	@echo "  $(GREEN)ps$(CLEAR_COLOR)		— container status"
	@echo "  $(GREEN)logs$(CLEAR_COLOR)		— view logs"
	@echo "  $(GREEN)db$(CLEAR_COLOR)		— access MariaDB as wpuser"
	@echo "  $(GREEN)db-root$(CLEAR_COLOR)	— access MariaDB as root"
	@echo "  $(GREEN)db-show$(CLEAR_COLOR)	— show databases and users"
	@echo "  $(GREEN)cert$(CLEAR_COLOR)		— regenerate TLS certificate"
	@echo "  $(RED)clean$(CLEAR_COLOR)   	— down + remove volumes"
	@echo "  $(RED)fclean$(CLEAR_COLOR)  	— full cleanup (images, volumes, data)"
	@echo "  $(GREEN)re $(CLEAR_COLOR)		— fclean + all"
	@echo "  $(GREEN)------------------------------------- $(CLEAR_COLOR)"
	@echo "  $(CYAN)bonus$(CLEAR_COLOR)		— build and start with Redis + FTP + Static"
	@echo "  $(CYAN)bonus-down$(CLEAR_COLOR)	— stop bonus containers"
	@echo "  $(CYAN)bonus-stop$(CLEAR_COLOR)	— pause without removing"
	@echo "  $(CYAN)bonus-start$(CLEAR_COLOR)	— restart bonus containers"
	@echo "  $(CYAN)bonus-ps$(CLEAR_COLOR)		— bonus container status"
	@echo "  $(CYAN)bonus-logs$(CLEAR_COLOR)	— view bonus logs"
	@echo "  $(CYAN)bonus-redis-cli$(CLEAR_COLOR)	— connect to Redis CLI"
	@echo "  $(CYAN)bonus-ftp-cli$(CLEAR_COLOR)	— connect to FTP server"

	@echo "  $(RED)bonus-clean$(CLEAR_COLOR)	— down + remove bonus volumes"
	@echo "  $(RED)bonus-fclean$(CLEAR_COLOR)	— full bonus cleanup (images, volumes, data)"

.PHONY: all dirs down stop start ps status logs db db-root db-show cert clean fclean re help \
	bonus bonus-down bonus-stop bonus-start bonus-ps bonus-logs bonus-redis-cli bonus-ftp-cli bonus-clean bonus-fclean
