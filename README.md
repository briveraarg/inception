*Este proyecto fue creado como parte del currículo de 42 por brivera42.*

# Inception

## Descripción

Inception es un proyecto de administración de sistemas que consiste en construir una
infraestructura de servicios web usando Docker. El objetivo es desplegar WordPress
con su base de datos MariaDB y un servidor NGINX con TLS, todo orquestado mediante
Docker Compose en una máquina virtual.

La infraestructura está compuesta por tres contenedores:
- **NGINX** — único punto de entrada, maneja HTTPS con TLSv1.2/1.3
- **WordPress + php-fpm** — motor de la aplicación web
- **MariaDB** — base de datos relacional

## Instrucciones

### Requisitos previos
- Docker y Docker Compose instalados
- Make instalado
- Puerto 443 disponible

### Instalación y ejecución
#### Clonar el repositorio
```
git clone <tu-repo> inception
cd inception
```
#### Crear los archivos de `secrets`
```
echo "dbpass123" > secrets/db_password
echo "dbroot123" > secrets/db_root_password
echo "wpadminpass123" > secrets/wp_admin_password
echo "wpeditorpass123" > secrets/wpuser_password
```
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

#### Levantar el proyecto
```
make
```

### Comandos disponibles

| Comando | Descripción |
|---|---|
| `make` | Construye y levanta todos los contenedores |
| `make down` | Para los contenedores |
| `make clean` | Para y elimina volúmenes |
| `make fclean` | Limpieza total incluyendo imágenes |
| `make re` | Reconstruye todo desde cero |
| `make logs` | Muestra los logs de todos los servicios |
| `make status` | Muestra el estado de los contenedores |

### Verificación
```bash
# Verifica que los contenedores están corriendo
docker ps

# Verifica que WordPress responde
curl -k https://brivera.42.fr

# Verifica la versión de TLS
curl -v -k https://brivera.42.fr 2>&1 | grep "SSL connection"
```

## Descripción del proyecto

### Uso de Docker

Docker permite empaquetar cada servicio con todas sus dependencias en contenedores
aislados. Cada contenedor tiene su propio Dockerfile escrito desde cero usando
Alpine 3.20 como imagen base — elegida por su tamaño mínimo (~5MB) y seguridad.

### Decisiones de diseño principales

**Imagen base: Alpine 3.20**
Se eligió Alpine sobre Debian por su tamaño reducido, menor superficie de ataque
y tiempos de build más rápidos.

**Certificado TLS**
El certificado autofirmado se genera en el Makefile con OpenSSL y se pasa a NGINX
via Docker secrets — así persiste entre reinicios del contenedor.

**WP-CLI**
Se usa WP-CLI para instalar y configurar WordPress desde línea de comandos,
evitando configuración manual via interfaz web.

### Comparativas

#### Máquinas Virtuales vs Docker

| | Máquina Virtual | Docker |
|---|---|---|
| Aislamiento | Sistema operativo completo | Proceso aislado |
| Tamaño | GBs | MBs |
| Arranque | Minutos | Segundos |
| Rendimiento | Overhead de hipervisor | Casi nativo |
| Uso | Entorno completo | Un servicio |

Las VMs virtualizan hardware completo. Docker comparte el kernel del host
y solo aísla procesos — más ligero y eficiente para microservicios.

#### Secrets vs Variables de entorno

| | Secrets | Variables de entorno |
|---|---|---|
| Almacenamiento | Archivo en `/run/secrets/` | Memoria del proceso |
| Visibilidad | Solo el contenedor que lo necesita | `docker inspect` los expone |
| Seguridad | Alta | Media |
| Uso recomendado | Passwords, certificados | Configuración no sensible |

En este proyecto las passwords viajan como secrets y la configuración
general (dominio, usuario, email) como variables de entorno.

#### Docker Network vs Host Network

| | Docker Network | Host Network |
|---|---|---|
| Aislamiento | Red privada entre contenedores | Comparte red del host |
| Seguridad | Alta | Baja |
| Comunicación | Por nombre de contenedor | Por localhost |
| Uso en proyecto | inception bridge network | prohibido por el subject |

Con Docker network los contenedores se comunican por nombre
(`wordpress`, `mariadb`) sin exponer puertos al exterior innecesariamente.

#### Docker Volumes vs Bind Mounts

| | Docker Volumes | Bind Mounts |
|---|---|---|
| Gestión | Docker gestiona la ruta | Ruta del host fija |
| Portabilidad | Alta | Baja |
| Rendimiento | Óptimo | Bueno |
| Uso en proyecto | Volúmenes nombrados en `/home/brivera42/data` | prohibido por el subject |

Los volúmenes nombrados persisten los datos de WordPress y MariaDB
en `/home/brivera42/data` del host incluso si los contenedores se eliminan.

## Resources

### Documentación oficial
- [Docker Documentation](https://docs.docker.com)
- [Docker Compose Reference](https://docs.docker.com/compose)
- [NGINX Documentation](https://nginx.org/en/docs)
- [MariaDB Documentation](https://mariadb.com/kb/en)

### Tutoriales
- [Aprende Docker ahora!](https://youtu.be/4Dko5W96WHg)

### Uso de IA
La IA fue utilizada como herramienta de apoyo en las siguientes áreas:
- Depuración de errores en los scripts de inicialización
- Comprensión de conceptos como PID 1, php-fpm y TLS
- Revisión de configuraciones de NGINX y MariaDB
- Generación de estructura base de la documentación
- AI utilizadas: clude y la misma que ofrece la páguina oficial de docker

Todo el código fue revisado, comprendido y adaptado manualmente.
