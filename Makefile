NAME = inception

all: up

up:
	@mkdir -p $(HOME)/data/wordpress
	@mkdir -p $(HOME)/data/mariadb
	@docker compose -f srcs/docker-compose.yml up --build -d

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

fclean: clean
	@docker system prune -af
	@rm -rf $(HOME)/data/wordpress
	@rm -rf $(HOME)/data/mariadb

re: fclean all

.PHONY: all up down stop start status logs clean fclean re
