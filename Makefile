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

NAME        = inception
COMPOSE     = docker compose -f srcs/docker-compose.yml
SRCS        = $(shell find srcs -type f)

all: dirs secrets/server.crt
	@echo "[inception] Building and starting containers..."
	@$(COMPOSE) up --build -d

dirs:
	@mkdir -p $(HOME)/data/wordpress
	@mkdir -p $(HOME)/data/mariadb
	@mkdir -p secrets

secrets/server.crt: | dirs
	@openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout secrets/server.key \
		-out    secrets/server.crt \
		-subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=$(USER).42.fr"

cert: dirs
	@rm -f secrets/server.crt secrets/server.key
	@$(MAKE) secrets/server.crt

down:
	@$(COMPOSE) down

stop:
	@$(COMPOSE) stop

start:
	@$(COMPOSE) start

ps:
	@$(COMPOSE) ps

status: ps

logs:
	@$(COMPOSE) logs

clean:
	@$(COMPOSE) down -v

fclean:
	@echo "[inception] Full cleanup..."
	@$(COMPOSE) down -v --rmi all --remove-orphans
	@docker volume ls -q --filter label=com.docker.compose.project=inception \
		| xargs -r docker volume rm
	@docker system prune -af
	@sudo rm -rf $(HOME)/data/wordpress/*
	@sudo rm -rf $(HOME)/data/mariadb/*
	@rm -f secrets/server.crt secrets/server.key

re: fclean all

help:
	@echo "Targets disponibles:"
	@echo "  all     — build y start"
	@echo "  down    — parar y eliminar contenedores"
	@echo "  stop    — parar sin eliminar"
	@echo "  start   — arrancar contenedores parados"
	@echo "  ps      — estado de contenedores"
	@echo "  logs    — ver logs"
	@echo "  cert    — regenerar certificado TLS"
	@echo "  clean   — down + borrar volúmenes"
	@echo "  fclean  — limpieza total (imágenes, volúmenes, datos)"
	@echo "  re      — fclean + all"

.PHONY: all dirs down stop start ps status logs cert clean fclean re help