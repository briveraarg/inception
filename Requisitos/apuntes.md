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
---

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


#### ¿Qué significa cada usuario?

| Usuario     | Host     | Significado |
|-------------|----------|-------------|
| `PUBLIC`    | (vacío)  | Rol base de MariaDB, lo crea solo |
| `wpuser`    | `%`      | El que creamos — el `%` significa que puede conectarse **desde cualquier IP** (cualquier contenedor) |
| `mariadb.sys` | `localhost` | Usuario interno del sistema, lo crea MariaDB |
| `mysql`     | `localhost` | Usuario interno, lo crea MariaDB  |
| `root`      | `localhost` | El superusuario, solo accesible desde dentro del contenedor |

El `%` en `wpuser` es clave — significa que WordPress desde otro contenedor podrá conectarse.


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
```
docker rm test-mariadb
```
#### Borrar una imagen

```
docker rmi mariadb
```

#### Limpieza total - borra TODO lo que no se usa

```
docker system prune -a
```
nota -> Por defecto, este comando no elimina volúmenes
para evitar la pérdida accidental de datos persistentes.
Para incluirlos, deberías añadir el flag `--volumes`.


#### Para todo y borra volúmenes 
```
docker compose down -v
```

# Levantar
```
docker compose up --build
```

## ¿Qué es php-fpm y por qué va separado de NGINX?

```
Usuario
	 ↓
NGINX (puerto 443)          → maneja HTTPS, archivos estáticos
	 ↓
WordPress + php-fpm (9000)  → procesa el PHP
	 ↓
MariaDB (3306)              → guarda los datos
```

- **NGINX** no puede ejecutar PHP solo
- **php-fpm** es el motor que procesa los archivos `.php`
- Hablan entre sí por el puerto `9000`

---

#### ¿Qué es php-fpm83 -F?
-> php-fpm83 → es el ejecutable de php-fpm versión 8.3 (la que instala Alpine 3.20)
-> -F → significa foreground, es decir, que corre en primer plano y no se convierte en daemon
Sin -F php-fpm arrancaría, se iría al fondo como daemon y el contenedor se cerraría porque PID 1 terminaría. Es exactamente lo mismo que hicimos con:

```
exec mysqld --user=mysql  # en MariaDB
exec php-fpm83 -F         # en WordPress
```

#### Primero veamos qué hace cada uno:

**NGINX** es un servidor web. Que puede/sabe:
	- Recibir peticiones HTTP/HTTPS
	- Servir archivos estáticos (imágenes, CSS, JS)
	- Redirigir tráfico

Pero **NGINX no sabe ejecutar PHP**.
Cuando llega una petición a un archivo `.php`, NGINX  dice "Dios,yo no sé qué hacer con esto".

**php-fpm** (FastCGI Process Manager) es el motor que:
	- Recibe el archivo `.php` de NGINX
	- Lo ejecuta
	- Devuelve el HTML resultante a NGINX
	- NGINX se lo manda al usuario

Usuario pide → https://brivera.42.fr

```
NGINX recibe la petición
		↓
¿Es archivo estático? (jpg, css, js)
		→ SÍ  → NGINX lo sirve directamente
		→ NO  → es .php → lo manda a php-fpm puerto 9000
														↓
											php-fpm ejecuta el PHP
														↓
											consulta MariaDB si necesita datos
														↓
											devuelve HTML a NGINX
														↓
											NGINX lo manda al usuario
```

#### ¿Por qué van en contenedores separados?
Por un lado porque el subject lo exige explícitamente:

`"A Docker container that contains WordPress + php-fpm only, without nginx"`

Pero también tiene sentido técnico — es la filosofía Docker:
`Un contenedor = un proceso = una responsabilidad`

Contenedor| Responsabilidad |
-----------|-----------------|
NGINX      | Manejar HTTPS y servir archivos |
WordPress + php-fpm | Ejecutar el código PHP|
MariaDB.   |Guardar los datos|

### levantar docker

 ```
 docker compose up -d
 ```
 flag `-d` -> detached
	- Levanta los contenedores en background
	- Te devuelve el prompt inmediatamente
	- No muestra logs en vivo
	- Usa las imágenes que ya existen — no reconstruye


```
docker compose up --build
```
flag `--build`
- Levanta los contenedores en primer plano
- Reconstruye las imágenes** antes de levantar
- Muestra todos los logs en vivo
- Te bloquea la terminal


### Se pueden combinar

```
docker compose up --build -d
```

- Reconstruye las imágenes y corre en background
- Te devuelve el prompt
- Para ver los logs después usas `docker logs wordpress`

---

#### ¿Cuándo usar cada uno?

| Situación | Comando |
|---|---|
| Cambiaste un Dockerfile | `--build` |
| Cambiaste el `.env` o `init.sh` | `--build` |
| Solo levantar sin cambios | `up -d` |
| Ver logs en vivo | sin `-d` |
| Desarrollo normal | `up --build -d` |


## ¿Qué es TLS?

TLS (Transport Layer Security) es el protocolo que hace que una conexión sea **segura y cifrada**.
Es lo que convierte `http://` en `https://`.


Sin TLS:
```
Mi navegador  →  "password=123"  →  Servidor
								 ↑ cualquiera puede leerlo
```

Con TLS:
```
Mi navegador  →  "x7$kL#9mQ..."  →  Servidor
								 ↑ cifrado, nadie puede leerlo
```

### ¿Cómo funciona?

Necesita dos cosas:
	1. Certificado — es como el DNI del servidor, dice "yo soy brivera.42.fr"
	2. Clave privada — es el secreto que usa para cifrar

```
Navegador ->  "¿Sos brivera.42.fr?"
NGINX			->  "Sí, aca está mi certificado"
Navegador	->	"Ok, ciframos la conexión"
```

---

### TLSv1.2 vs TLSv1.3

| | TLSv1.2 | TLSv1.3 |
|---|---|---|
| Año | 2008 | 2018 |
| Seguridad | Buena | Mejor |
| Velocidad | Normal | Más rápido |

El subject pide soportar **solo** TLSv1.2 o TLSv1.3 — versiones anteriores están prohibidas porque tienen vulnerabilidades.

Como es un proyecto local, el certificado vamos a hacer un **autofirmado** con `openssl`. No es de una autoridad oficial, pero funciona para el proyecto.

El navegador mostrará un aviso de "certificado no confiable" — es normal, para este proyecto se acepta.
