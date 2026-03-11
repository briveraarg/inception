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

### Ver contenedores corriendo

```
docker ps 
docker ps -all
```
### Ver imágenes descargadas/construidas

```
docker images
```

### Entrar al contenedor de mariadb

```
docker exec -it test-mariadb sh

-> Conéctar con el usuario de wordpress
mysql -u wpuser -p #user
mysql -u root -p #root

-> Escribir PASSWORD del .env

-> Verificar que existe la base de datos
SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| wordpress          |
+--------------------+

-> En modo ROOT, se puede ver la tabla de usuarios del sistema
SELECT User, Host FROM mysql.user;

```

#### ¿Qué es `information_schema`?

Es una base de datos **interna y automática** que crea MariaDB sola. Contiene metadatos — información sobre las otras bases de datos, tablas, usuarios, permisos, etc. Es de solo lectura y no se toca nunca.

La base de datos `wordpress` es la nuestra.

---

#### ¿Qué significa cada usuario?

| Usuario     | Host     | Significado |
|-------------|----------|-------------|
| `PUBLIC`    | (vacío)  | Rol base de MariaDB, lo crea solo |
| `wpuser`    | `%`      | El que creamos — el `%` significa que puede conectarse **desde cualquier IP** (cualquier contenedor) |
| `mariadb.sys` | `localhost` | Usuario interno del sistema, lo crea MariaDB |
| `mysql`     | `localhost` | Usuario interno, lo crea MariaDB  |
| `root`      | `localhost` | El superusuario, solo accesible desde dentro del contenedor |

El `%` en `wpuser` es clave — significa que WordPress desde otro contenedor podrá conectarse.

---

#### ¿Por qué usamos `mysql` si es MariaDB?

Porque MariaDB nació como un fork de MySQL y mantiene compatibilidad total.
Por eso:

- El comando se llama `mysql`
- El puerto es `3306` igual que MySQL
- Los comandos SQL son los mismos
- El directorio de datos es `/var/lib/mysql`

Es simplemente herencia histórica. En el mundo real cuando se dice `mysql` en MariaDB es lo mismo.

---

### A limpiar, a limpiar ... en docker

#### Borrar un contenedor
docker rm test-mariadb

#### Borrar una imagen
docker rmi mariadb

#### Limpieza total - borra TODO lo que no se usa
```
docker system prune -a
```
nota -> Por defecto, este comando no elimina volúmenes
para evitar la pérdida accidental de datos persistentes.
Para incluirlos, deberías añadir el flag `--volumes`.
