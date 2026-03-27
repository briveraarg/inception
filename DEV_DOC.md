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
```bash
cd srcs
docker compose up --build nginx
docker compose up --build wordpress
docker compose up --build mariadb
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
├── Makefile                    ← punto de entrada
├── README.md                   ← documentación general
├── USER_DOC.md                 ← guía de usuario
├── DEV_DOC.md                  ← esta guía
├── secrets/                    ← credenciales (no en Git)
│   ├── db_password
│   ├── db_root_password
│   ├── wp_admin_password
│   ├── wpuser_password
│   ├── server.crt
│   └── server.key
└── srcs/
    ├── .env                    ← variables de entorno (no en Git)
    ├── docker-compose.yml      ← orquestación de servicios
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── 50-server.cnf
        │   └── tools/
        │       └── init.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       └── init.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── init.sh
```