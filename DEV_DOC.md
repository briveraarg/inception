*Este proyecto fue creado como parte del currículo de 42 por brivera42.*

# Guía de Desarrollador | Inception

## Configurar el entorno desde cero

### Requisitos previos

- Sistema operativo con kernel Linux (nativo o virtualizado)
- Docker instalado
- Docker Compose instalado
- Make instalado
- Git instalado

Verificar que están instalados:
```bash
docker --version
docker compose version
make --version
```

### Clonar el repositorio
```bash
git clone <repositorio> inception
cd inception
```

### Crear los archivos de secrets

Estos archivos no están en el repositorio por seguridad.
Hay que crearlos manualmente antes del primer arranque:

```bash
echo "wppass123" > secrets/db_password
echo "rootpass123" > secrets/db_root_password
echo "adminpass123" > secrets/wp_admin_password
echo "editorpass123" > secrets/wpuser_password
```

El certificado TLS se genera automáticamente con `make`.

#### Crear el archivo `.env`
```
nano srcs/.env
```
```
# Dominio
DOMAIN_NAME=brivera.42.fr

# Puerto
HTTPS_PORT=443

# MariaDB
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

# WordPress
WP_ADMIN_USER=brivera42
WP_ADMIN_EMAIL=brivera@student.42madrid.com
WP_USER=wpeditor
WP_USER_EMAIL=editor@42madrid.com
```
**Nota:** El archivo `.env` contiene configuración general (dominio, usuario, email).

### Configurar el dominio

Agrega el dominio al `/etc/hosts` de la VM:
```bash
echo "127.0.0.1 brivera.42.fr" | sudo tee -a /etc/hosts
```

## Construir y lanzar el proyecto

### Primera vez
```bash
cd ~/inception
make
```

El Makefile hace automáticamente:
1. Crea los directorios de datos en `/home/brivera42/data`
2. Genera el certificado TLS si no existe
3. Construye las imágenes Docker
4. Levanta los contenedores en background

### Verificar que todo arrancó bien
```bash
# Estado de los contenedores
make status

# Logs de todos los servicios
make logs

# Verificar WordPress
curl -k https://brivera.42.fr
```

---

## Comandos para gestionar contenedores y volúmenes

### Makefile

| Comando | Descripción |
|---|---|
| `make` | Construye y levanta todo |
| `make down` | Para los contenedores, conserva datos |
| `make stop` | Pausa los contenedores |
| `make start` | Reanuda los contenedores pausados |
| `make clean` | Para y elimina volúmenes |
| `make fclean` | Limpieza total — imágenes, volúmenes, datos |
| `make re` | Reconstruye todo desde cero |
| `make logs` | Muestra logs de todos los servicios |
| `make status` | Muestra estado de los contenedores |
| `make bonus` | Construye y levanta todo + Redis + FTP + Static (bonus) |
| `make bonus-down` | Para los contenedores bonus |
| `make bonus-logs` | Muestra logs de servicios bonus |
| `make bonus-ps` | Muestra estado de contenedores bonus |
| `make bonus-redis-cli` | Conecta a Redis CLI |
| `make bonus-ftp-cli` | Conecta al servidor FTP |

### Docker directo
```bash
# Ver contenedores corriendo
docker ps

# Ver logs de un contenedor
docker logs nginx
docker logs wordpress
docker logs mariadb

# Entrar a un contenedor
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh

# Ver volúmenes
docker volume ls

# Ver redes
docker network ls

# Ver imágenes
docker images
```

### Reconstruir un solo servicio

**Servicios principales:**
```bash
cd srcs
docker compose up --build nginx
docker compose up --build wordpress
docker compose up --build mariadb
```

**Servicios bonus:**
```bash
cd srcs_bonus
docker compose -f docker-compose.bonus.yml up --build redis
docker compose -f docker-compose.bonus.yml up --build ftp
docker compose -f docker-compose.bonus.yml up --build static
docker compose -f docker-compose.bonus.yml up --build wordpress
```

---

## Dónde se almacenan los datos y cómo persisten

### Estructura de datos en el host
```
/home/brivera42/data/
├── mariadb/     ← base de datos de WordPress
└── wordpress/   ← archivos del sitio WordPress
```

Estos directorios están montados como volúmenes Docker en los contenedores:

| Volumen | Ruta en host | Ruta en contenedor |
|---|---|---|
| `db` | `/home/brivera42/data/mariadb` | `/var/lib/mysql` |
| `wordpress` | `/home/brivera42/data/wordpress` | `/var/www/html` |

### ¿Cómo persisten los datos?

Cuando haces `make down` los contenedores se detienen pero los datos
permanecen en `/home/brivera42/data`. Al hacer `make` de nuevo los
contenedores arrancan y encuentran los datos existentes.

Solo se pierden los datos cuando haces `make clean` o `make fclean`
que eliminan los volúmenes y el directorio de datos.

### Verificar los datos en el host
```bash
# Ver archivos de WordPress
ls /home/brivera42/data/wordpress

# Ver archivos de MariaDB
ls /home/brivera42/data/mariadb
```

---
## Estructura del proyecto

```
inception/
├── Makefile                    ← punto de entrada (build, deploy, logs)
├── README.md                   ← esta documentación
├── USER_DOC.md                 ← guía de usuario final
├── DEV_DOC.md                  ← guía técnica para desarrolladores
│
├── secrets/                    ← credenciales (NO en Git)
│   ├── db_password
│   ├── db_root_password
│   ├── wp_admin_password
│   ├── wpuser_password
│   ├── server.crt              ← certificado TLS (generado por Makefile)
│   └── server.key              ← clave privada TLS (generado por Makefile)
│
└── srcs/
    ├── .env                    ← variables de entorno (NO en Git)
    ├── docker-compose.yml      ← orquestación de servicios
    │
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile      ← imagen Alpine + MariaDB
        │   ├── conf/
        │   │   └── 50-server.cnf    ← configuración de MariaDB
        │   └── tools/
        │       └── init.sh     ← script de inicialización
        │
        ├── nginx/
        │   ├── Dockerfile      ← imagen Alpine + NGINX
        │   ├── conf/
        │   │   └── nginx.conf.template  ← config como template
        │   └── tools/
        │       └── init.sh     ← script de inicialización
        │
        └── wordpress/
            ├── Dockerfile      ← imagen Alpine + PHP + WP-CLI
            ├── conf/
            │   └── www.conf    ← configuración de php-fpm
            └── tools/
                └── init.sh     ← instalación de WordPress headless

srcs_bonus/
└── docker-compose.bonus.yml    ← orquestación de servicios bonus
    └── requirements_bonus/
        ├── redis/
        │   ├── Dockerfile      ← imagen Alpine + Redis
        │   └── tools/
        │       ├── init.sh     ← inicialización con contraseña
        │       └── healthcheck.sh  ← verificación de salud
        │
        ├── ftp/
        │   ├── Dockerfile      ← imagen Alpine + vsftpd
        │   ├── conf/
        │   │   └── vsftpd.conf ← configuración de FTP
        │   └── tools/
        │       └── entrypoint.sh    ← gestión de usuarios y arranque
        │
        ├── static/
        │   ├── Dockerfile      ← imagen Alpine + Nginx para contenido estático
        │   └── html/
        │       ├── index.html   ← página principal
        │       └── fotos/       ← galería de imágenes
        │
        └── wordpress/
            ├── Dockerfile      ← WordPress + Redis Object Cache plugin
            ├── conf/
            │   └── www.conf    ← configuración de php-fpm
            └── tools/
                └── init.sh     ← instalación + plugin Redis
```

### Explicación de directorios

**`srcs/`** — Implementación obligatoria
- `docker-compose.yml` — Orquestación de NGINX, WordPress y MariaDB
- `requirements/` — Código fuente de cada contenedor

**`srcs_bonus/`** — Servicios opcionales bonus
- `docker-compose.bonus.yml` — Añade Redis y WordPress mejorado
- `requirements_bonus/` — Nuevas imágenes para servicios bonus

**`secrets/`** — Credenciales seguras
- Se crea manualmente antes del primer arranque
- Gestión vía Docker Secrets (no en variables de entorno)

**`Makefile`** — Automatización
- Genera certificados TLS
- Construye volúmenes en `/home/brivera42/data/`
- Orquesta el ciclo de vida (build → up → logs → down → clean)

### Persistencia de datos

Los datos se almacenan en volúmenes Docker que el Makefile crea automáticamente:

```
/home/brivera42/data/
├── mariadb/     ← base de datos (volumen db)
├── wordpress/   ← archivos del sitio (volumen wordpress)
├── redis/       ← caché Redis bonus (volumen redis)
└── static/      ← contenido estático bonus (opcional)
```

Estos volúmenes **persisten** entre reinicios:
- `make down` — Contenedores paran pero datos quedan en volúmenes
- `make clean` — Contenedores + volúmenes se eliminan
- `make fclean` — Eliminación total (contenedores, volúmenes, imágenes)

### Verificación
```bash
# Verifica que los contenedores están corriendo
docker ps

# Verifica que WordPress responde
curl -k https://brivera.42.fr

# Verifica la versión de TLS
curl -v -k https://brivera.42.fr 2>&1 | grep "SSL connection"
```

## Resumen de Implementación

### ✅ Parte Obligatoria

**NGINX**
- Servidor web HTTP/HTTPS
- Escucha en puerto 443 (TLS 1.2/1.3)
- Certificado autofirmado renovable
- Configuración optimizada de proxy a php-fpm
- Compresión gzip habilitada

**WordPress + php-fpm**
- PHP 8.3 con extensiones necesarias
- WP-CLI para instalación automatizada
- Instalación headless via script
- Gestión de usuarios automática
- Volumen persistente para datos

**MariaDB**
- Base de datos relacional
- Usuario dedicado `wpuser` con contraseña segura
- Base de datos `wordpress` preconfigurada
- Volumen persistente con datos

**Docker Compose**
- Orquestación de 3 servicios
- Red bridge privada (`inception`)
- Comunicación interna por nombres
- Variables de entorno centralizadas

**Secrets**
- Gestión segura de contraseñas
- Acceso restringido a contenedores
- 4 secrets para credenciales BD/WP
- 2 secrets para certificado TLS

**Makefile**
- Automatización completa del ciclo de vida
- Generación de certificados
- Build, deploy, logs, limpieza
- Acceso fácil a servicios (db, db-root)

### ✅ Bonus Implementado

**Redis**
- Caché en memoria (puerto 6379)
- Healthcheck automático
- Contraseña segura via secret
- Volumen persistente para datos
- Conectado a red `inception`

**FTP**
- Servidor vsftpd para transferencia de archivos
- Acceso en puerto 21
- Credenciales almacenadas en `secrets/ftp_password`
- Permite gestionar archivos de WordPress remotamente
- Volumen para persistencia de datos compartido
- Conectado a red `inception`

**Static**
- Servidor web nginx para contenido estático
- Acceso en puerto 80 (HTTP)
- Sirve archivos HTML, CSS, imágenes sin procesamiento PHP
- Ideal para galerías de fotos y contenido estático
- Volumen con archivos en `/var/www/html`
- Carpeta `/fotos` para almacenar imágenes
- Conectado a red `inception`

**WordPress con Redis Object Cache**
- Plugin "Redis Object Cache" v2.7.0
- Instalación y activación automática
- Cachea:
  - Queries de BD
  - Objetos PHP
  - Resultados de funciones
  - Transientes WordPress
- Acelera significativamente el sitio

### Tecnologías Utilizadas

| Componente | Tecnología | Versión |
|---|---|---|
| Base | Alpine Linux | 3.20 |
| Servidor Web | NGINX | latest |
| Servidor Estático | NGINX | latest |
| FastCGI | PHP-FPM | 8.3 |
| Base Datos | MariaDB | latest |
| CMS | WordPress | latest |
| Caché | Redis | latest |
| Plugin Caché | Redis Object Cache | 2.7.0 |
| FTP | vsftpd | latest |
| CLI DB | MariaDB Client | latest |
| CLI CMS | WP-CLI | latest |
| Orquestación | Docker Compose | latest |

### Scripts de Inicialización

Cada servicio tiene un script personalizado que:
- Valida dependencias (espera a que otros servicios estén listos)
- Configura el servicio
- Instala datos iniciales si es necesario
- Arranca el servicio en foreground (PID 1)

### Seguridad Implementada

- **TLS**: Certificado autofirmado con OpenSSL, renovable
- **Secrets**: Contraseñas en `/run/secrets/` (no en env vars)
- **Red**: Comunicación interna solo entre contenedores
- **Usuarios**: Usuarios no-root en contenedores
- **Permisos**: wwwdata para WordPress, nobody para php-fpm
- **Volúmenes**: Permisos restrictivos en directorios

### Persistencia de Datos

**Volúmenes Docker** (no bind mounts):
```
docker://<volumen>  →  /home/brivera42/data/<servicio>/
```

Ventajas:
- Portabilidad alta
- Mejor rendimiento que bind mounts
- Gestión automática por Docker
- Sobreviven reinicios de contenedores
- Se eliminan solo con `make clean`/`make fclean`

### Decisiones Arquitectónicas

1. **Alpine 3.20** sobre Debian: Tamaño mínimo, seguridad, build rápido
2. **Volúmenes nombrados** en lugar de bind mounts: Portabilidad y rendimiento
3. **Docker Secrets** para credenciales: Seguridad, no visibles en `docker inspect`
4. **WP-CLI** para instalación: Automatización headless sin GUI
5. **Redis Object Cache** plugin: Aceleración automática sin configuración manual
6. **Network bridge** privada: Comunicación interna segura, sin exposición innecesaria de puertos
7. **Servidor Static separado**: Servir contenido estático eficientemente sin cargar PHP
   - NGINX en contenedor dedicado para archivos estáticos (HTML, CSS, imágenes)
   - Mejora rendimiento y seguridad separando lógica dinámica de estática
