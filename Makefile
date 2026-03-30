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
MAGENTA      = \033[95;1m
CLEAR_COLOR  = \033[0m

NAME    = inception
COMPOSE = docker compose -f srcs/docker-compose.yml
SRCS    = $(shell find srcs -type f)

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
	@echo "$(MAGENTA)[$(NAME)] Regenerating TLS certificate...$(CLEAR_COLOR)"
	@rm -f secrets/server.crt secrets/server.key
	@$(MAKE) secrets/server.crt

down:
	@echo "$(MAGENTA)[$(NAME)] Stopping containers...$(CLEAR_COLOR)"
	@$(COMPOSE) down
	@echo "$(GREEN)[$(NAME)] Containers stopped!$(CLEAR_COLOR)"

stop:
	@echo "$(MAGENTA)[$(NAME)] Pausing containers...$(CLEAR_COLOR)"
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

clean:
	@echo "$(MAGENTA)[$(NAME)] Cleaning volumes and containers...$(CLEAR_COLOR)"
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
	@rm -f secrets/server.crt secrets/server.key
	@rm -f $(NAME)
	@echo "$(GREEN)[$(NAME)] Full cleanup complete!$(CLEAR_COLOR)"

re: fclean all

help:
	@echo "Targets disponibles:"
	@echo "  $(GREEN)all$(CLEAR_COLOR)     — build y start"
	@echo "  $(MAGENTA)down$(CLEAR_COLOR)    — parar y eliminar contenedores"
	@echo "  $(MAGENTA)stop$(CLEAR_COLOR)    — parar sin eliminar"
	@echo "  $(CYAN)start$(CLEAR_COLOR)   — arrancar contenedores parados"
	@echo "  $(CYAN)ps$(CLEAR_COLOR)      — estado de contenedores"
	@echo "  $(CYAN)logs$(CLEAR_COLOR)    — ver logs"
	@echo "  $(CYAN)cert$(CLEAR_COLOR)    — regenerar certificado TLS"
	@echo "  $(MAGENTA)clean$(CLEAR_COLOR)   — down + borrar volúmenes"
	@echo "  $(RED)fclean$(CLEAR_COLOR)  — limpieza total (imágenes, volúmenes, datos)"
	@echo "  re      — fclean + all"

.PHONY: all dirs down stop start ps status logs cert clean fclean re help
