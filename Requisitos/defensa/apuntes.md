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

Pregunta: "¿Cómo se comunican tus contenedores?"

Respuesta: "Están conectados a la red srcs_inception, 
que es un bridge network creado por Docker Compose. 
Esto permite que se comuniquen por names:
- wordpress → mariadb:3306 (por DNS interno)
- nginx → wordpress:9000 (por FastCGI)

La red proporciona aislamiento y seguridad."


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

## Volumnes 
Docker soporta dos tipos principales de volúmenes para persistencia de datos: **named volumes** y **bind mounts**.

---

### Named volumes

- Son gestionados completamente por Docker.
- Se crean explícitamente (`docker volume create`) o automáticamente al crear un contenedor o servicio.
- Docker decide la ubicación en el host.
- Permiten compartir datos entre múltiples contenedores.
- Son ideales para persistencia, backup, migración y alto rendimiento.
- Se pueden gestionar con comandos Docker y funcionan en Linux y Windows.
- Los nuevos volúmenes pueden ser pre-poblados por el contenedor.
- No aumentan el tamaño del contenedor y ofrecen mejor rendimiento que escribir en la capa writable del contenedor.

---

### Bind mounts

- Montan un archivo o directorio específico del host dentro del contenedor.
- Tú decides la ubicación en el host.
- Permiten acceso directo a archivos del host desde el contenedor.
- Son útiles para desarrollo, donde necesitas compartir código o configuraciones en tiempo real.
- Pueden tener problemas de portabilidad si el host y el contenedor tienen diferencias en permisos o estructura.
- No soportan drivers de volumen ni backup/migración tan fácilmente como los named volumes.

---

#### Comparación rápida

|                      | Named volumes           | Bind mounts                |
|----------------------|------------------------|----------------------------|
| Ubicación en host    | Docker decide          | Tú decides                 |
| Pre-poblado          | Sí                     | No                         |
| Drivers de volumen   | Sí                     | No                         |
| Portabilidad         | Alta                   | Depende del host           |
| Acceso desde host    | Limitado               | Directo                    |

---

**Resumen:**  
- Usa **named volumes** para persistencia, portabilidad y gestión centralizada.
- Usa **bind mounts** para desarrollo y acceso directo a archivos del host.

A los fines del proyecto 

```
docker volume inspect srcs_mariadb_data 

[
    {
        "CreatedAt": "2026-04-06T18:49:55+02:00",
        "Driver": "local",
        "Labels": {
            "com.docker.compose.config-hash": "c6375909f8c856eddf302b7e1d7d5e4ff9c18db06064d751d99c190a397269b2",
            "com.docker.compose.project": "srcs",
            "com.docker.compose.version": "5.1.0",
            "com.docker.compose.volume": "mariadb_data"
        },
        "Mountpoint": "/var/lib/docker/volumes/srcs_mariadb_data/_data",
        "Name": "srcs_mariadb_data",
        "Options": {
            "device": "/home/brivera/data/mariadb",
            "o": "bind",
            "type": "none"
        },
        "Scope": "local"
    }
]
```


### 1. `CreatedAt`
- **¿Qué es?**  
  Es la fecha y hora en que se creó este volumen.
- **¿Para qué sirve?**  
  Te ayuda a saber cuándo se generó el volumen, útil para auditoría o limpieza.

### 2. `Driver`
- **¿Qué es?**  
  Indica el tipo de controlador que gestiona el volumen. En este caso, es `"local"`, que es el driver por defecto de Docker.
- **¿Para qué sirve?**  
  El driver define cómo y dónde se almacenan los datos del volumen. El driver local almacena los datos en el sistema de archivos del host.

### 3. `Labels`
- **¿Qué es?**  
  Son metadatos adicionales que Docker y Docker Compose usan para identificar y gestionar el volumen.
- **¿Para qué sirve?**  
  Por ejemplo, aquí ves información sobre el proyecto de Compose, la versión y el nombre del volumen dentro del proyecto.

### 4. `Mountpoint`
- **¿Qué es?**  
  Es la ruta en el sistema de archivos del host donde realmente se almacenan los datos del volumen.
- **¿Para qué sirve?**  
  Si quieres ver los archivos directamente en el host, esta es la carpeta donde están.  
  En este caso: `/var/lib/docker/volumes/srcs_mariadb_data/_data`  
  **Pero:** Como usas opciones de bind, realmente los datos están en otra ruta (ver siguiente punto).

### 5. `Name`
- **¿Qué es?**  
  Es el nombre del volumen, en este caso `srcs_mariadb_data`.
- **¿Para qué sirve?**  
  Así puedes referenciar este volumen en comandos o en tu archivo Compose.

### 6. `Options`
- **¿Qué es?**  
  Son opciones avanzadas que definen cómo se comporta el volumen.
- **¿Para qué sirve?**  
  Aquí tienes:
  - `"device": "/home/brivera/data/mariadb"`: Indica la carpeta real del host donde se guardan los datos.
  - `"o": "bind"`: Le dice a Docker que use un "bind mount", es decir, que enlace una carpeta específica del host.
  - `"type": "none"`: Especifica el tipo de sistema de archivos (en este caso, ninguno especial).
  
  **Esto significa:** Aunque Docker lo gestiona como un volumen nombrado, los datos realmente están en `/home/brivera/data/mariadb` en tu máquina.

### 7. `Scope`
- **¿Qué es?**  
  Indica el alcance del volumen. `"local"` significa que solo está disponible en el host donde se creó.
- **¿Para qué sirve?**  
  Si tuvieras un clúster de Docker, algunos volúmenes podrían ser compartidos entre varios hosts, pero este solo existe localmente.


- Docker gestiona el volumen como "named volume".
- Los datos realmente se guardan en `/home/brivera/data/mariadb` gracias a las opciones de bind mount.
- Esto permite cumplir con los requisitos de gestión de Docker y de ubicación física de los datos.

---

Fuentes:
- [https://docs.docker.com/reference/cli/docker/volume/inspect/](https://docs.docker.com/reference/cli/docker/volume/inspect/)
- [https://docs.docker.com/reference/cli/docker/volume/create/](https://docs.docker.com/reference/cli/docker/volume/create/)
- [https://docs.docker.com/reference/compose-file/volumes/](https://docs.docker.com/reference/compose-file/volumes/)


-----------------

# Te lo resumo

### ¿Cómo funcionan Docker y Docker Compose?

- **Docker** permite crear, ejecutar y gestionar contenedores. Un contenedor es una instancia de una imagen Docker, que encapsula una aplicación y sus dependencias.
- **Docker Compose** es una herramienta para definir y ejecutar aplicaciones multicontenedor. Permite describir los servicios, redes y volúmenes de una aplicación en un solo archivo YAML, facilitando la gestión y orquestación de varios contenedores simultáneamente.

### Diferencia entre usar una imagen Docker con Docker Compose y sin Docker Compose

- **Sin Docker Compose:** Usas comandos como `docker run` para iniciar manualmente cada contenedor. Debes gestionar redes, variables, volúmenes y dependencias entre contenedores de forma individual, lo que puede ser complejo y propenso a errores.
- **Con Docker Compose:** Defines todos los servicios y su configuración en un archivo YAML. Con un solo comando (`docker compose up`), se crean y conectan todos los contenedores según lo especificado. Compose puede referenciar un Dockerfile para construir imágenes personalizadas y facilita la gestión de redes, volúmenes y dependencias.

> Un Dockerfile proporciona instrucciones para construir una imagen, mientras que un archivo Compose define los contenedores en ejecución y puede referenciar Dockerfiles para construir imágenes de servicios específicos.

### Beneficio de Docker comparado con máquinas virtuales

- **Contenedores Docker** son más ligeros y rápidos que las máquinas virtuales porque comparten el kernel del sistema operativo y solo encapsulan la aplicación y sus dependencias.
- **Máquinas virtuales** requieren un sistema operativo completo por instancia, lo que consume más recursos y tiempo de arranque.
- Docker permite mayor eficiencia, portabilidad y escalabilidad en el desarrollo y despliegue de aplicaciones.

### Pertinencia de la estructura de directorios requerida

- La estructura de directorios es relevante porque facilita la organización del código, los Dockerfiles y los archivos Compose.
- Incluir el archivo Compose en el repositorio permite que cualquier persona que clone el proyecto pueda levantar el entorno completo con un solo comando, asegurando consistencia y facilidad de colaboración.

### Resumen de beneficios de Docker Compose

- Define aplicaciones multicontenedor en un solo archivo YAML.
- Facilita la colaboración y la replicación de entornos.
- Permite cambios rápidos y reutilización de contenedores.
- Portabilidad entre entornos (desarrollo, testing, producción).

Sources:
- [https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-docker-compose/](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-docker-compose/)
- [https://docs.docker.com/guides/docker-compose/common-questions/](https://docs.docker.com/guides/docker-compose/common-questions/)
- [https://docs.docker.com/compose/](https://docs.docker.com/compose/)
- [https://docs.docker.com/guides/docker-compose/why/](https://docs.docker.com/guides/docker-compose/why/)
- [https://docs.docker.com/compose/intro/features-uses/](https://docs.docker.com/compose/intro/features-uses/)

## Ejemplo Dockerfile para MariaDB:

- **FROM alpine:3.20**  
  Indica que la imagen base será Alpine Linux versión 3.20. Alpine es una distribución ligera y segura, recomendada por Docker para imágenes pequeñas y eficientes.

- **RUN apk update && apk add --no-cache mariadb mariadb-client**  
  Ejecuta comandos dentro de la imagen para actualizar el índice de paquetes y luego instala MariaDB y su cliente usando el gestor de paquetes de Alpine (apk). El flag `--no-cache` evita almacenar archivos temporales, manteniendo la imagen pequeña.

- **COPY conf/50-server.cnf /etc/my.cnf.d/mariadb-server.cnf**  
  Copia el archivo de configuración personalizado de MariaDB desde tu proyecto al contenedor, permitiendo modificar la configuración del servidor.

- **COPY tools/init.sh /usr/local/bin/init.sh**  
  Copia un script de inicialización al contenedor, que normalmente se usa para preparar el entorno antes de iniciar MariaDB.

- **RUN chmod +x /usr/local/bin/init.sh**  
  Da permisos de ejecución al script `init.sh` para que pueda ejecutarse como entrada del contenedor.

- **EXPOSE 3306**  
  Expone el puerto 3306, que es el puerto estándar de MariaDB, para que pueda ser accedido desde fuera del contenedor.

- **ENTRYPOINT ["/usr/local/bin/init.sh"]**  
  Define el script de inicialización como el proceso principal que se ejecuta cuando el contenedor arranca.

Cada línea es una instrucción de Dockerfile que define cómo se construye la imagen y cómo se comporta el contenedor al ejecutarse.

Sources:
- [https://docs.docker.com/docker-hub/image-library/trusted-content/](https://docs.docker.com/docker-hub/image-library/trusted-content/)
- [https://docs.docker.com/build/building/best-practices/](https://docs.docker.com/build/building/best-practices/)

---

### Archivo de configuración: `50-server.cnf`

Este archivo define la configuración del servidor MariaDB y del cliente:

- **[mysqld]**  
  - `user = mysql`: El proceso del servidor se ejecuta como el usuario `mysql`.
  - `bind-address = 0.0.0.0`: El servidor escucha en todas las interfaces de red, permitiendo conexiones externas.
  - `port = 3306`: Puerto estándar de MariaDB/MySQL.
  - `datadir = /var/lib/mysql`: Directorio donde se almacenan los datos de la base de datos.
  - `socket = /run/mysqld/mysqld.sock`: Ubicación del socket UNIX para conexiones locales.

- **[client]**  
  - `port = 3306`: Puerto para conexiones del cliente.
  - `socket = /run/mysqld/mysqld.sock`: Ubicación del socket para el cliente.

Este archivo se copia al contenedor usando la instrucción `COPY` en el Dockerfile, permitiendo personalizar la configuración del servidor MariaDB.

---

### Script de inicialización: `init.sh`

Este script se usa como `ENTRYPOINT` en el Dockerfile, es decir, se ejecuta cuando el contenedor arranca. Su función es preparar el entorno y crear la base de datos y usuarios si es la primera vez que se inicia el contenedor.

**Pasos principales:**

1. **Preparar directorios y permisos:**
   - Crea el directorio `/run/mysqld` y asigna permisos al usuario `mysql`.

2. **Leer secretos:**
   - Lee las contraseñas desde archivos en `/run/secrets/`, lo que es una práctica recomendada para manejar credenciales de forma segura en Docker Compose.

3. **Inicializar la base de datos (solo si es la primera vez):**
   - Si el directorio `/var/lib/mysql/mysql` no existe, ejecuta `mysql_install_db` para inicializar el sistema de archivos de la base de datos.
Este script SQL configura una base de datos MySQL en un entorno como Docker, realizando varias acciones de seguridad y creación de usuarios:
`FLUSH PRIVILEGES`
    Recarga las tablas de privilegios desde la base de datos `mysql`, haciendo efectivos los cambios inmediatamente. 
`DELETE FROM mysql.user WHERE User='';`
    Elimina cuentas de usuario anónimas (sin nombre), mejorando la seguridad. 
`DROP DATABASE IF EXISTS test;` 
    Elimina la base de datos de prueba predeterminada `test`, que puede ser un riesgo de seguridad.
`CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};`
    Crea una nueva base de datos (con un nombre definido por la variable de entorno `MYSQL_DATABASE`) si no existe. 
`CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';`
    Crea un usuario (nombre definido por `MYSQL_USER`) que puede conectarse desde cualquier host (`%`) con una contraseña específica (`DB_PASSWORD`).
`GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';`
    Otorga todos los privilegios sobre la base de datos recién creada al nuevo usuario. 
`ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';`
    Cambia la contraseña del usuario `root` para conexiones locales. 
`FLUSH PRIVILEGES;`
    Vuelve a ejecutar `FLUSH PRIVILEGES` para asegurar que todos los cambios anteriores (crear usuario, otorgar privilegios, cambiar contraseña de root) se apliquen de inmediato.


Este enfoque es similar al que se describe en la documentación de Docker para bases de datos, donde se copian scripts de inicialización al contenedor y se ejecutan automáticamente al arrancar por primera vez ([ver ejemplo en la guía de bases de datos](https://docs.docker.com/guides/databases/)).

---

**Resumen:**  
- El archivo de configuración personaliza el comportamiento de MariaDB.
- El script de inicialización prepara el entorno, crea la base de datos y usuarios, y asegura que las credenciales se gestionen de forma segura.
- Ambos archivos se integran en el contenedor mediante el Dockerfile, siguiendo buenas prácticas recomendadas en la documentación de Docker.

Sources:
- [https://docs.docker.com/guides/databases/](https://docs.docker.com/guides/databases/)
- [https://docs.docker.com/reference/dockerfile/](https://docs.docker.com/reference/dockerfile/)

---

## ¿Qué es Nginx?

Nginx es un servidor web y proxy inverso muy utilizado para servir aplicaciones web, gestionar tráfico HTTP/HTTPS, y actuar como balanceador de carga. En Docker, Nginx se usa frecuentemente para servir contenido estático, manejar certificados SSL, y como frontend para aplicaciones multicontenedor.


### Explicación del archivo `nginx.conf`

Este archivo configura Nginx para servir el sitio web con HTTPS y PHP. 

- **worker_processes auto;**
  - Nginx ajusta automáticamente el número de procesos de trabajo según los recursos disponibles.

- **events { worker_connections 1024; }**
  - Define el número máximo de conexiones simultáneas por proceso de trabajo.

- **http { ... }**
  - Bloque principal para configuración HTTP.

  - **include /etc/nginx/mime.types;**
    - Incluye tipos MIME para servir archivos con el tipo correcto.
	- Cuando NGINX sirve un archivo, necesita saber qué tipo es para enviarlo con el Content-Type correcto al navegador. 

  - **default_type application/octet-stream;**
    - Tipo por defecto para archivos no reconocidos.

  - **server { ... }**
    - Configura un servidor virtual.

    - **listen 443 ssl;**
      - Escucha en el puerto 443 (HTTPS) usando SSL.

    - **server_name brivera.42.fr;**
      - Nombre del servidor (dominio).

    - **ssl_certificate /etc/nginx/ssl/server.crt;**
      - Ruta al certificado SSL.

    - **ssl_certificate_key /etc/nginx/ssl/server.key;**
      - Ruta a la clave privada SSL.

    - **ssl_protocols TLSv1.2 TLSv1.3;**
      - Protocolos TLS permitidos.

    - **root /var/www/html;**
      - Directorio raíz donde se encuentran los archivos del sitio.

    - **index index.php index.html;**
      - Archivos que se buscan por defecto al acceder a una carpeta.

    - **location / { try_files $uri $uri/ /index.php?$args; }**
      - Intenta servir el archivo solicitado, si no existe, redirige a `index.php` con los argumentos.

    - **location ~ \.php$ { ... }**
      - Configura el manejo de archivos PHP:
        - **fastcgi_pass wordpress:9000;**  
          Envía las peticiones PHP al contenedor de WordPress en el puerto 9000.
        - **fastcgi_index index.php;**  
          Archivo PHP por defecto.
        - **fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;**  
          Define la ruta del script PHP.
        - **include fastcgi_params;**  
          Incluye parámetros FastCGI estándar.

---

Este archivo configura Nginx para servir contenido estático y dinámico (PHP), usando HTTPS y conectándose a un backend de WordPress para procesar archivos PHP.
