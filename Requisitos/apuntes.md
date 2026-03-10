# Apuntes 

### Construir una imagen Docker usando el Dockerfile 
El `flag -t` sirve para ponerle un nombre a la imagen,
y la ruta indica el contexto de build, es decir,
dónde buscar el Dockerfile y los archivos necesarios.

```
docker build -t mariadb srcs/requirements/mariadb
```

### Crear e iniciar un contenedor a partir de una imagen

`docker run` -> comando principal para crear un nuevo contenedor a partir de una imagen.
`-d` (detached) -> indica que el contenedor se ejecutará en segundo plano (background).
`--name test-mariadb` -> asigna un nombre personalizado al contenedor. En lugar de usar un ID aleatorio.
`--env-file srcs/.env` -> levanta las variables de entorno desde un archivo externo ubicado en la ruta srcs/.env.

```
docker run -d
  --name test-mariadb
  --env-file srcs/.env
  mariadb
```

### Revisar logs

```
docker logs test-mariadb
```

# Limpia el contenedor anterior

```
docker rm test-mariadb
```

# Entra al contenedor
docker exec -it test-mariadb sh

# Conéctate con el usuario de wordpress
mysql -u wpuser -p
# escribe tu MYSQL_PASSWORD del .env

# Verifica que existe la base de datos
SHOW DATABASES;
```

Deberías ver:
```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| wordpress          |
+--------------------+
 