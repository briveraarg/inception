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

TLS = varios algoritmos trabajando juntos

1. Intercambio de claves    → RSA o ECDH
2. Cifrado de datos         → AES, ChaCha20
3. Verificación integridad  → SHA-256, SHA-384


#### Vulnerabilidades conocidas de TLS antiguo

| Versión | Vulnerabilidad | Qué hace |
|---|---|---|
| TLSv1.0 | BEAST, POODLE | Descifra cookies de sesión |
| TLSv1.1 | BEAST | Ataque man-in-the-middle |
| TLSv1.2 | CRIME, BREACH | Compresión maliciosa — ya corregido |
| TLSv1.3 | Ninguna conocida | Diseño más seguro desde cero |

---

### ¿Qué es OpenSSL?

Es una librería y herramienta de línea de comandos que implementa TLS y criptografía.

```bash
# Genera certificados
openssl req -x509 ...

# Verifica certificados
openssl verify ...

# Cifra archivos
openssl enc ...

# Inspecciona conexiones TLS
openssl s_client -connect google.com:443
```

En el proyecto se usa para generar el certificado autofirmado dentro del contenedor NGINX.


### ¿Qué es NGINX?

Es un servidor web de alto rendimiento. Nació en 2004 para resolver el problema de manejar muchas conexiones simultáneas.

Puede hacer varias cosas:

1. Servidor web — sirve archivos HTML, CSS, imágenes -> `Usuario → NGINX → archivo.html`
2. Reverse proxy — reenvía peticiones a otro servidor -> `Usuario → NGINX → WordPress/php-fpm`
3. Terminador TLS — maneja el cifrado HTTPS -> `Usuario (HTTPS) → NGINX → WordPress (HTTP interno)`

En el proyecto hace las tres cosas a la vez.

## ¿Por qué NGINX y no Apache?

| | NGINX | Apache |
|---|---|---|
| Arquitectura | Asíncrono | Un proceso por conexión |
| Memoria | Muy eficiente | Más pesado |
| Rendimiento | Muy alto | Bueno |
| Configuración | Simple | Más compleja |

NGINX es el estándar actual para proyectos modernos con Docker.


### Ver visualmente desde el host la pag de wp

```
docker exec -it wordpress sh
```

- `exec` → ejecuta un comando en un contenedor que ya está corriendo
- `-it` → modo interactivo con terminal
- `wordpress` → nombre del contenedor
- `sh` → el shell que abre (Alpine usa sh, no bash)

WordPress guarda su URL en la base de datos en una tabla llamada `wp_options`. Tiene dos valores clave:

| opción | valor original | valor nuevo |
|---|---|---|
| `siteurl` | `https://brivera.42.fr` | `https://127.0.0.1:8443` |
| `home` | `https://brivera.42.fr` | `https://127.0.0.1:8443` |


```
docker exec -it wordpress sh

wp option update siteurl 'https://127.0.0.1:8443' --allow-root --path=/var/www/html
wp option update home 'https://127.0.0.1:8443' --allow-root --path=/var/www/html

exit
```

Probar en Firefox :  `https://127.0.0.1:8443`


`wp option update` es un comando de WP-CLI que modifica esos valores directamente en MariaDB.

Cuando WordPress recibe una petición, lee esos valores y hace redirect hacia ellos— WordPress redirige a `127.0.0.1:8443`.

`--allow-root` → WP-CLI por seguridad no corre como root, este flag lo fuerza
`--path=/var/www/html` → le dice dónde está instalado WordPress
`exit` → salir

#### Para restableceer 

```
docker exec -it wordpress sh
/var/www/html # wp option update siteurl 'https://brivera.42.fr' --allow-root --path=/var/www/html
/var/www/html # wp option update home 'https://brivera.42.fr' --allow-root --path=/var/www/html
/var/www/html # exit

```
---

#### Mostrar que los tres contenedores corren
```
docker ps
```

#### Mostrar que WordPress responde
```
curl -k https://brivera.42.fr
```

#### Mostrar que TLS funciona y es v1.2/v1.3
```
curl -v -k https://brivera.42.fr 2>&1 | grep "SSL connection"
#SSL connection using TLSv1.3
```

#### Entrar a MariaDB y mostrar la DB
```
docker exec -it mariadb sh
mysql -u wpuser -p
SHOW DATABASES;
SELECT User, Host FROM mysql.user;
exit
exit
```

#### Mostrar los volúmenes
```
docker volume ls
```
#### Mostrar la red
```
docker network ls
```

#### Ver que el admin existe

```
docker exec -it wordpress sh
wp user list --allow-root --path=/var/www/html

+----+------------+---------------+
| ID | user_login | roles         |
+----+------------+---------------+
| 1  | brivera42  | administrator |
| 2  | wpeditor   | author        |
+----+------------+---------------+
```


### Certificado en la carpeta secrets 
## Qué es ese comando


**`openssl req`** → crea una solicitud de certificado
**`-x509`** → en vez de una solicitud, genera directamente un certificado autofirmado
**`-nodes`** → la clave privada no tendrá contraseña (no encrypted). Si tuviera contraseña NGINX pediría password cada vez que arranca
**`-days 365`** → el certificado dura 365 días
**`-newkey rsa:2048`** → genera una clave nueva RSA de 2048 bits
**`-keyout ~/inception/secrets/server.key`** → guarda la clave privada aquí
**`-out ~/inception/secrets/server.crt`** → guarda el certificado aquí
**`-subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=brivera.42.fr"`** → datos del certificado:
- `C` → país (ES = España)
- `ST` → provincia (Madrid)
- `L` → ciudad (Madrid)
- `O` → organización (42)
- `CN` → dominio (brivera.42.fr) — el más importante

Una sola vez, un solo certificado. 

```bash
openssl req -x509 -nodes \
    -days 365 \
    -newkey rsa:2048 \
    -keyout ~/inception/secrets/server.key \
    -out ~/inception/secrets/server.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=brivera.42.fr"
```

El certificado queda guardado en `secrets/` y NGINX lo lee desde ahí via Docker secrets.
Siempre el mismo certificado, más estable.
