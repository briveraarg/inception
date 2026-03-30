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

NAME = inception

all: $(NAME)

$(NAME): srcs/docker-compose.yml srcs/**/* secrets/server.crt
	@mkdir -p $(HOME)/data/wordpress
	@mkdir -p $(HOME)/data/mariadb
	@docker compose -f srcs/docker-compose.yml up --build -d
	@touch $(NAME)

secrets/server.crt:
	@openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout secrets/server.key \
		-out secrets/server.crt \
		-subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=brivera.42.fr"

down:
	@docker compose -f srcs/docker-compose.yml down

stop:
	@docker compose -f srcs/docker-compose.yml stop

start:
	@docker compose -f srcs/docker-compose.yml start

status:
	@docker compose -f srcs/docker-compose.yml ps

logs:
	@docker compose -f srcs/docker-compose.yml logs

clean:
	@docker compose -f srcs/docker-compose.yml down -v
	@rm -rf $(NAME)

fclean:
	@# 1. Parar todo y borrar volúmenes internos de docker
	@docker compose -f srcs/docker-compose.yml down -v --rmi all --remove-orphans
	@# 2. Borrar CUALQUIER volumen que haya quedado vivo (esto borra los posts)
	@if [ -n "$$(docker volume ls -q)" ]; then \
		docker volume rm $$(docker volume ls -q); \
	fi
	@# 3. Borrar las carpetas físicas (el contenido, no la carpeta en sí)
	@sudo rm -rf $(HOME)/data/wordpress/*
	@sudo rm -rf $(HOME)/data/mariadb/*
	@# 4. Limpieza extra de imágenes y redes
	@docker system prune -af
	@rm -f $(NAME)


re: fclean all

.PHONY: all up down stop start status logs clean fclean re 
