# Apuntes — Inception

## Tabla de contenidos
1. [Docker Básico](#docker-básico)
2. [MariaDB](#mariadb)
3. [PHP-FPM y NGINX](#php-fpm-y-nginx)
4. [NGINX — Configuración](#nginx--configuración)
5. [TLS y Certificados](#tls-y-certificados)
6. [Docker Compose](#docker-compose)
7. [Volúmenes](#volúmenes)
8. [Limpieza](#limpieza)
9. [Bonus — Redis](#bonus--redis)
10. [Bonus — FTP](#bonus--ftp)
11. [Bonus — Static](#bonus--static)
12. [Validación y Pruebas](#validación-y-pruebas)

---

## Docker Básico

### Construir una imagen Docker
El flag `-t` sirve para ponerle un nombre a la imagen. La ruta indica el contexto de build (dónde buscar el Dockerfile).

```bash
docker build -t mariadb srcs/requirements/mariadb
```

### Crear e iniciar un contenedor
`docker run` — comando principal para crear un nuevo contenedor a partir de una imagen
- `-d` (detached) — ejecuta el contenedor en background
- `--name` — asigna un nombre personalizado
- `--env-file` — carga variables de entorno desde un archivo

```bash
docker run -d \
	--name test-mariadb \
	--env-file srcs/.env \
	mariadb
```

### Ver información de contenedores e imágenes

**Logs del contenedor:**
```bash
docker logs test-mariadb
```

**Contenedores corriendo:**
```bash
docker ps
docker ps -all
```

**Imágenes descargadas/construidas:**
```bash
docker images
```

---

## MariaDB

### Entrar al contenedor de MariaDB

```bash
docker exec -it test-mariadb sh
```

### Acceder a MariaDB

```bash
# Como usuario wpuser (aplicación)
mysql -u wpuser -p

# Como root (administrador)
mysql -u root -p
```

### Comandos básicos de MariaDB

```sql
-- Ver bases de datos
SHOW DATABASES;

-- Ver usuarios y hosts
SELECT User, Host FROM mysql.user;

-- Salir
exit
```

**Salida esperada:**
```
+--------------------+
| Database           |
+--------------------+
| information_schema |
| wordpress          |
+--------------------+
```

### Entiender la estructura de usuarios

| Usuario     | Host     | Significado |
|-------------|----------|-------------|
| `root`      | `localhost` | Superusuario, solo accesible desde dentro del contenedor |
| `wpuser`    | `%`      | Usuario de WordPress — el `%` permite conectarse desde cualquier IP/contenedor |
| `mysql`     | `localhost` | Usuario interno del sistema |
| `mariadb.sys` | `localhost` | Usuario interno de MariaDB |

El `%` en `wpuser` es clave — permite que WordPress desde otro contenedor se conecte.

### ¿Qué es `information_schema`?

Es una base de datos **interna y automática** que crea MariaDB automáticamente. Contiene **metadatos** (información sobre otras bases de datos, tablas, usuarios, permisos, etc.). Es de solo lectura y nunca se modifica manualmente.

La base de datos `wordpress` es la que creamos nosotros.

### ¿Por qué usamos `mysql` si es MariaDB?

MariaDB nació como un fork de MySQL y mantiene compatibilidad total. Por eso:
- El comando se llama `mysql`
- El puerto es `3306` igual que MySQL
- Los comandos SQL son idénticos
- El directorio de datos es `/var/lib/mysql`

Es simplemente herencia histórica.

---

## PHP-FPM y NGINX

### Arquitectura de comunicación

```
Usuario (navegador)
	 ↓
NGINX (puerto 443)              → maneja HTTPS, archivos estáticos
	 ↓
WordPress + php-fpm (9000)      → procesa el PHP
	 ↓
MariaDB (3306)                  → guarda los datos
```

### ¿Por qué van separados?

**NGINX** solo puede:
- Recibir peticiones HTTP/HTTPS
- Servir archivos estáticos (imágenes, CSS, JS)
- Redirigir tráfico

**NGINX no puede ejecutar PHP** — para eso existe **php-fpm**.

### ¿Qué es php-fpm?

**php-fpm** (FastCGI Process Manager) es el motor que:
1. Recibe archivos `.php` de NGINX
2. Los ejecuta
3. Consulta MariaDB si es necesario
4. Devuelve HTML resultante a NGINX
5. NGINX se lo envía al usuario

### Flujo de una petición

```
Usuario pide → https://brivera.42.fr

	↓

NGINX recibe la petición

	↓

¿Es archivo estático? (jpg, css, js, etc.)
	
	→ SÍ  → NGINX lo sirve directamente
	
	→ NO  → es .php → lo manda a php-fpm puerto 9000
	
		   php-fpm ejecuta el PHP
		   
		   → Si necesita datos, consulta MariaDB
		   
		   → Devuelve HTML a NGINX
		   
		   → NGINX lo manda al usuario
```

### ¿Qué es `php-fpm83 -F`?

- `php-fpm83` — ejecutable de php-fpm versión 8.3 (la que instala Alpine 3.20)
- `-F` — significa "foreground" (primer plano, no se convierte en daemon)

**¿Por qué `-F` es importante?**

Sin `-F`, php-fpm arrancaría como background y el contenedor se cerraría porque PID 1 terminaría.

Es lo mismo que en MariaDB:
```bash
exec mysqld --user=mysql  # en MariaDB
exec php-fpm83 -F         # en WordPress
```

### ¿Por qué contenedores separados?

El subject lo exige explícitamente:
> "A Docker container that contains WordPress + php-fpm only, without nginx"

Pero también tiene sentido técnico — es la filosofía Docker:
> "Un contenedor = un proceso = una responsabilidad"

---

## Limpieza

### Borrar un contenedor

```bash
docker rm test-mariadb
```

### Borrar una imagen

```bash
docker rmi mariadb
```

### Limpieza total (borra TODO lo no utilizado)

```bash
docker system prune -a
```

**Nota:** Por defecto no elimina volúmenes para evitar pérdida de datos. Para incluirlos:
```bash
docker system prune -a --volumes
```

### Parar y borrar volúmenes con Docker Compose

```bash
docker compose down -v
```

---

## Docker Compose

### Levantar servicios

**Con recomposición de imágenes:**
```bash
docker compose up --build
```
- Levanta los contenedores en primer plano
- Reconstruye las imágenes antes de levantar
- Muestra todos los logs en vivo
- Te bloquea la terminal

**En background:**
```bash
docker compose up -d
```
- Levanta los contenedores en background
- Te devuelve el prompt inmediatamente
- No muestra logs en vivo
- Usa las imágenes que ya existen (sin reconstruir)

**Combinado (recomendado):**
```bash
docker compose up --build -d
```
- Reconstruye las imágenes y corre en background
- Te devuelve el prompt
- Para ver los logs: `docker logs wordpress`

### ¿Cuándo usar cada uno?

| Situación | Comando |
|---|---|
| Cambiaste un Dockerfile | `up --build` |
| Cambiaste `.env` o `init.sh` | `up --build` |
| Solo levantar sin cambios | `up -d` |
| Ver logs en vivo | `up` (sin -d) |
| Desarrollo normal | `up --build -d` |

---

## TLS y Certificados

### ¿Qué es TLS?

TLS (Transport Layer Security) es el protocolo que hace que una conexión sea **segura y cifrada**.
Convierte `http://` en `https://`.

**Sin TLS:**
```
Mi navegador  →  "password=123"  →  Servidor
                  ↑ cualquiera puede leerlo
```

**Con TLS:**
```
Mi navegador  →  "x7$kL#9mQ..."  →  Servidor
                  ↑ cifrado, nadie puede leerlo
```

### Función del certificado

1. **Certificado** — es como el DNI del servidor, dice "yo soy brivera.42.fr"
2. **Clave privada** — es el secreto que usa para cifrar

Handshake:
```
Navegador →  "¿Sos brivera.42.fr?"
NGINX     →  "Sí, aca está mi certificado"
Navegador →  "Ok, ciframos la conexión"
```

### TLSv1.2 vs TLSv1.3

| | TLSv1.2 | TLSv1.3 |
|---|---|---|
| Año | 2008 | 2018 |
| Seguridad | Buena | Mejor |
| Velocidad | Normal | Más rápido |

El subject pide soportar **solo** TLSv1.2 o TLSv1.3. Versiones antiguas están prohibidas por vulnerabilidades.

### Vulnerabilidades de TLS antiguo

| Versión | Vulnerabilidad | Descripción |
|---|---|---|
| TLSv1.0 | BEAST, POODLE | Descifra cookies de sesión |
| TLSv1.1 | BEAST | Ataque man-in-the-middle |
| TLSv1.2 | CRIME, BREACH | Compresión maliciosa (ya corregido) |
| TLSv1.3 | Ninguna | Diseño más seguro desde cero |

### OpenSSL

OpenSSL es una librería y herramienta de línea de comandos que implementa TLS y criptografía.

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

En el proyecto se usa para generar el certificado autofirmado.

### Comando de generación del certificado

```bash
openssl req -x509 -nodes \
    -days 365 \
    -newkey rsa:2048 \
    -keyout ~/inception/secrets/server.key \
    -out ~/inception/secrets/server.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=brivera.42.fr"
```

**Significado de flags:**
- `-x509` — genera directamente un certificado autofirmado (no una solicitud)
- `-nodes` — la clave privada no tiene contraseña (no encrypted)
- `-days 365` — certificado válido por 365 días
- `-newkey rsa:2048` — genera clave RSA de 2048 bits
- `-keyout` — ruta de la clave privada
- `-out` — ruta del certificado
- `-subj` — datos del certificado:
  - `C` — país (ES = España)
  - `ST` — provincia/estado (Madrid)
  - `L` — ciudad (Madrid)
  - `O` — organización (42)
  - `CN` — dominio (brivera.42.fr) — el más importante

El certificado queda guardado en `secrets/` y NGINX lo lee desde ahí via Docker secrets.

---

## NGINX — Configuración

### ¿Qué es NGINX?

Es un servidor web de alto rendimiento. Nació en 2004 para resolver el problema de manejar muchas conexiones simultáneas.

**Funciones principales:**
1. Servidor web — sirve archivos HTML, CSS, imágenes
2. Reverse proxy — reenvía peticiones a otro servidor
3. Terminador TLS — maneja el cifrado HTTPS

### NGINX vs Apache

| | NGINX | Apache |
|---|---|---|
| Arquitectura | Asíncrono | Un proceso por conexión |
| Memoria | Muy eficiente | Más pesado |
| Rendimiento | Muy alto | Bueno |
| Configuración | Simple | Más compleja |

NGINX es el estándar actual para proyectos modernos con Docker.

### Estructura del archivo `nginx.conf`

**worker_processes auto;**
```
Nginx ajusta automáticamente el número de procesos de trabajo según los 
recursos disponibles.
```

**events { worker_connections 1024; }**
```
Define el número máximo de conexiones simultáneas por proceso de trabajo.
```

**http { ... }**
```
Bloque principal para configuración HTTP.
```

**Dentro del bloque http:**

- **include /etc/nginx/mime.types;**  
  Incluye tipos MIME para servir archivos con el Content-Type correcto.

- **default_type application/octet-stream;**  
  Tipo por defecto para archivos no reconocidos.

**server { ... }**
```
Configura un servidor virtual específico.
```

**Dentro del bloque server:**

- **listen 443 ssl;** — escucha puerto 443 (HTTPS)
- **server_name brivera.42.fr;** — nombre del servidor (dominio)
- **ssl_certificate /etc/nginx/ssl/server.crt;** — ruta del certificado
- **ssl_certificate_key /etc/nginx/ssl/server.key;** — ruta de la clave privada
- **ssl_protocols TLSv1.2 TLSv1.3;** — protocolos TLS permitidos
- **root /var/www/html;** — directorio raíz de archivos
- **index index.php index.html;** — archivos por defecto
- **location / { try_files $uri $uri/ /index.php?$args; }** — rutas

**Manejo de PHP:**
```nginx
location ~ \.php$ {
    fastcgi_pass wordpress:9000;           # Envía a WordPress en puerto 9000
    fastcgi_index index.php;               # Archivo PHP por defecto
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;                # Parámetros FastCGI estándar
}
```

---

## Volúmenes

Docker soporta dos tipos principales: **named volumes** y **bind mounts**.

### Named Volumes

- **Gestión:** Docker gestiona completamente la ubicación
- **Creación:** Automática al crear un contenedor o servicio
- **Portabilidad:** Alta
- **Compartir datos:** Sí, entre múltiples contenedores
- **Respaldo:** Fácil
- **Pre-poblado:** Sí, el contenedor puede agregar datos iniciales

**Ventajas:**
- Mejor rendimiento que escribir en la capa writable del contenedor
- Facilita backup y migración
- Ideal para persistencia de datos

### Bind Mounts

- **Gestión:** Tú decides la ubicación en el host
- **Acceso:** Directo a archivos del host desde el contenedor
- **Portabilidad:** Depende del host
- **Útil para:** Desarrollo, compartir código en tiempo real

**Ventajas:**
- Acceso directo durante desarrollo
- Sync inmediato de cambios

### Comparación

|                      | Named volumes | Bind mounts |
|----------------------|---------------|------------|
| Ubicación en host    | Docker decide | Tú decides |
| Pre-poblado          | Sí            | No |
| Drivers de volumen   | Sí            | No |
| Portabilidad         | Alta          | Depende |
| Acceso desde host    | Limitado      | Directo |

**Resumen:**
- Usa **named volumes** para persistencia, portabilidad y gestión centralizada
- Usa **bind mounts** para desarrollo y acceso directo

### Inspeccionar un volumen

```bash
docker volume inspect srcs_mariadb_data
```

**Campos importantes:**
- `CreatedAt` — fecha de creación
- `Driver` — tipo de controlador (local por defecto)
- `Labels` — metadatos (identificar proyecto)
- `Mountpoint` — ruta real en el host
- `Name` — nombre del volumen
- `Options` — configuración (device, tipo de bind)
- `Scope` — alcance (local o distribuido)

---

## Bonus — Redis

### ¿Qué es Redis?

Redis es una base de datos en memoria que funciona como caché de alta velocidad. Guarda datos en RAM para acceso ultrarrápido, ideal para mejorar el rendimiento de WordPress.

**Características:**
- Almacenamiento key-value
- Muy rápido (en memoria)
- Protegido con contraseña via Docker secrets
- Incluye healthcheck
- Volumen persistente en `/home/brivera42/data/redis`

### Integración con WordPress

El plugin "Redis Object Cache" se instala automáticamente en WordPress bonus y:
- Cachea queries de BD
- Cachea objetos PHP
- Cachea resultados de funciones
- Cachea transientes WordPress

Acelera significativamente el sitio al reducir consultas a la BD.

### Comandos Redis

```bash
make bonus-redis-cli
```

Dentro del CLI de Redis:
```redis
PING                    # Verifica conexión (responde PONG)
SET key value          # Guardar datos
GET key                # Obtener datos
FLUSHALL               # Borrar todo
INFO stats             # Ver estadísticas
DBSIZE                 # Número de claves
KEYS *                 # Listar todas las claves
```

---

## Bonus — FTP

### ¿Qué es FTP?

FTP (File Transfer Protocol) es un protocolo para transferir archivos. En el proyecto usamos **vsftpd** (Very Secure FTP Daemon) que permite gestionar archivos de WordPress remotamente.

**Características:**
- Servidor vsftpd configurado
- Puerto 21 (estándar FTP)
- Credenciales en `/run/secrets/ftp_password`
- Permite subo/descarga de archivos WordPress
- Conectado a la red  inception

### Acceso a FTP

**Opción 1: Desde terminal (recomendado)**
```bash
make bonus-ftp-cli
```

**Opción 2: Cliente FTP estándar**
```bash
ftp localhost 21
```

**Opción 3: Cliente lftp**
```bash
lftp -u usuario,contraseña ftp://localhost
```

### Comandos FTP

```
ls                  # Listar archivos
cd directorio       # Cambiar directorio
pwd                 # Directorio actual
get archivo         # Descargar archivo
put archivo         # Subir archivo
mkdir folder        # Crear carpeta
rm archivo          # Eliminar archivo
quit                # Salir
```

### Ejemplo: subir archivo

```bash
ftp localhost 21
# (login con credenciales)
ftp> cd wordpress
ftp> put /etc/hostname test.txt
ftp> ls
ftp> quit
```

Verificar en WordPress:
```bash
docker exec wordpress ls /var/www/html | grep test
```
curl -k https://brivera.42.fr/test
---

## Bonus — Static

### ¿Qué es el servicio Static?

Es un servidor NGINX dedicado a servir contenido estático (HTML, CSS, imágenes) sin procesamiento PHP. Mejora rendimiento y seguridad separando contenido dinámico de estático.

**Características:**
- Servidor NGINX para contenido estático
- Puerto 80 (HTTP)
- Archivos en `/var/www/html`
- Carpeta `/fotos` para galerías
- Conectado a la red inception

### Acceso a Static

**Desde terminal:**
```bash
curl http://brivera.42.fr:80
```

**Desde navegador:**
```
http://brivera.42.fr:80
```

**Acceder a la galería:**
```
http://brivera.42.fr:80/fotos
```

### Estructura de archivos

```
/var/www/html/
├── index.html       # Página principal
└── fotos/           # Galería de imágenes
    ├── imagen1.jpg
    ├── imagen2.png
    └── ...
```

---

## Validación y Pruebas

### Verificar que los contenedores corren

```bash
docker ps
```

Deberías ver todos los servicios con status `Up`.

### Verificar que WordPress responde

```bash
curl -k https://brivera.42.fr
```

### Verificar TLS (v1.2/v1.3)

```bash
curl -v -k https://brivera.42.fr 2>&1 | grep "SSL connection"
# Salida esperada: SSL connection using TLSv1.3
```

### Verificar MariaDB

```bash
docker exec -it mariadb sh
mysql -u wpuser -p
SHOW DATABASES;
SELECT User, Host FROM mysql.user;
exit
exit
```

### Verificar usuarios WordPress

```bash
docker exec -it wordpress sh
wp user list --allow-root --path=/var/www/html
exit
```

Salida esperada:
```
+----+------------+---------------+
| ID | user_login | roles         |
+----+------------+---------------+
| 1  | brivera42  | administrator |
| 2  | wpeditor   | author        |
+----+------------+---------------+
```

### Ver volúmenes

```bash
docker volume ls
```

### Ver red

```bash
docker network ls
```

**Pregunta esperada:** "¿Cómo se comunican tus contenedores?"

**Respuesta:**
```
"Están conectados a la red srcs_inception, que es un bridge network 
creado por Docker Compose. Esto permite que se comuniquen por nombres:
- wordpress → mariadb:3306 (por DNS interno)
- nginx → wordpress:9000 (por FastCGI)

La red proporciona aislamiento y seguridad."
```

### Cambiar URL de WordPress (si necesitas acceder por otro puerto)

```bash
docker exec -it wordpress sh
wp option update siteurl 'https://127.0.0.1:8443' --allow-root --path=/var/www/html
wp option update home 'https://127.0.0.1:8443' --allow-root --path=/var/www/html
exit
```

Luego acceder en: `https://127.0.0.1:8443`

**Para restaurar:**
```bash
docker exec -it wordpress sh
wp option update siteurl 'https://brivera.42.fr' --allow-root --path=/var/www/html
wp option update home 'https://brivera.42.fr' --allow-root --path=/var/www/html
exit
```

