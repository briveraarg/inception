
## **¿Qué es Docker?**
Docker es una plataforma de **containerización** que permite empaquetar aplicaciones con todas sus dependencias en unidades aisladas llamadas contenedores. Permite que una aplicación funcione igual en cualquier entorno (máquina local, servidor, nube).

---

## **¿Qué es una imagen?**
Una imagen es una **plantilla inmutable** que contiene todo lo necesario para ejecutar una aplicación: código, librerías, variables de entorno, etc. Es como una "fotografía" congelada de un sistema de archivos.

---

## **¿Qué es un contenedor?**
Un contenedor es una **instancia en ejecución de una imagen**. Si la imagen es la plantilla, el contenedor es la aplicación corriendo. Múltiples contenedores pueden ejecutarse desde la misma imagen.

---

## **¿Qué es docker-compose?**
Docker Compose es una herramienta que permite **orquestar múltiples contenedores** definidos en un archivo YAML. Gestiona redes, volúmenes, dependencias entre servicios, variables de entorno, etc. en una sola declaración.

---

## **Diferencia entre Docker solo vs docker-compose**
- **Docker solo**: Ejecutas un contenedor manual con `docker run`. Tendrías que crear redes, volúmenes y dependencias tú mismo.
- **Docker Compose**: Automatiza todo eso con un archivo YAML. Es ideal para multi-contenedor (como nuestro Inception con MySQL, WordPress y NGINX).

---

## **Docker vs Máquina Virtual**

| Aspecto | Docker | VM |
|---------|--------|-----|
| **Kernel** | Comparte el kernel del host | Tiene su propio kernel |
| **Peso** | Muy ligero (MB) | Pesada (GB) |
| **Tiempo arranque** | Segundos | Minutos |
| **Overhead** | Mínimo | Alto |

Docker es más eficiente porque no virtualiza hardware, solo aísla procesos.

---

## **¿Qué es un daemon?**
Un daemon es un **proceso que corre en background** sin interfaz de usuario. En Docker, el daemon `dockerd` es el servicio que gestiona imágenes, contenedores, redes y volúmenes.

---

## **¿Qué es PID 1?**
Es el **proceso principal dentro del contenedor**. En nuestro caso:
- MariaDB: `mysqld` es PID 1
- WordPress: `php-fpm83` es PID 1  
- NGINX: `nginx` es PID 1

Si PID 1 muere, el contenedor muere. Por eso usamos `exec` en los entrypoints, no `&` ni `while true`.

---

## **¿Qué es un entrypoint?**
Es el **comando que se ejecuta cuando inicia el contenedor**. Puede ser:
- Un script shell (como en Inception: `/usr/local/bin/init.sh`)
- Un binario directo (como `exec nginx`)

El entrypoint reemplaza completamente lo que se pase como comando.


### **ENTRYPOINT vs CMD**

### **CMD - Comando por defecto (reemplazable)**
```dockerfile
FROM alpine:3.20
RUN apk add mysql
CMD ["mysqld"]
```

```bash
# Si ejecutas sin argumentos
docker run inception-mariadb
# → Ejecuta: mysqld ✅

# Si ejecutas CON argumentos
docker run inception-mariadb --help
# → Ejecuta: --help ❌ (reemplaza todo)
# → ERROR: comando --help no existe
```

CMD es **reemplazable** por lo que pases en línea de comandos.


### **ENTRYPOINT - Comando fijo (inmutable)**
```dockerfile
FROM alpine:3.20
RUN apk add mysql
ENTRYPOINT ["mysqld"]
```

```bash
# Si ejecutas sin argumentos
docker run inception-mariadb
# → Ejecuta: mysqld ✅

# Si ejecutas CON argumentos
docker run inception-mariadb --help
# → Ejecuta: mysqld --help ✅ (añade argumentos)
# → MySQL muestra su ayuda
```

ENTRYPOINT **siempre se ejecuta**, los argumentos se añaden.


## **¿Cuál usar? - Decisión**

### **Usa CMD si:**
- ❌ Quieres que se reemplace fácilmente
- ❌ Quieres múltiples modos de ejecución

### **Usa ENTRYPOINT si:**
- ✅ Quieres un punto de entrada **FIJO**
- ✅ Necesitas que cierto código SE EJECUTE SIEMPRE
- ✅ La app REQUIERE setup antes de arrancar

---

## **En tu Inception - ENTRYPOINT es correcto**

Tu `wordpress/init.sh`:
```bash
#!/bin/sh
set -e

# Lee secretos
DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)

# Espera a MariaDB
until mysql -h mariadb -u ${MYSQL_USER} -p${DB_PASSWORD} ${MYSQL_DATABASE} -e "SELECT 1;" > /dev/null 2>&1; do
    echo "Waiting for MariaDB..."
    sleep 2
done

# Instala WordPress
if [ ! -f "/var/www/html/wp-config.php" ]; then
    wp core download ...
    wp config create ...
    wp core install ...
fi

# Ejecuta php-fpm
exec php-fpm83 -F
```

```dockerfile
ENTRYPOINT ["/usr/local/bin/init.sh"]
```

**¿Por qué ENTRYPOINT?**

✅ **DEBE ejecutarse siempre**:
1. Leer secretos
2. Esperar a MariaDB
3. Instalar WordPress
4. **DESPUÉS** arrancar php-fpm

Si usaras CMD y alguien pasa argumentos, se salta todo el setup → **¡WordPress no funciona!**


### **ENTRYPOINT vs CMD - Tabla comparativa**

| Aspecto | CMD | ENTRYPOINT |
|---------|-----|-----------|
| **¿Se ejecuta?** | Sí, a menos que pases comando | Siempre |
| **¿Se reemplaza con args?** | Sí (todo) | No (se añaden) |
| **Usa para:** | Comando simple | Setup + ejecutable |
| **Ejemplo:** | `CMD ["echo", "hola"]` | `ENTRYPOINT ["/init.sh"]` |


### **Ejemplo real:**

### **Dockerfile con CMD:**
```dockerfile
FROM alpine:3.20
CMD ["echo", "Hola Mundo"]
```

```bash
docker build -t test .
docker run test
# Output: Hola Mundo ✅

docker run test "Adiós Mundo"
# Output: Adiós Mundo ✅
# CMD fue reemplazado
```

### **Dockerfile con ENTRYPOINT:**
```dockerfile
FROM alpine:3.20
ENTRYPOINT ["echo"]
```

```bash
docker build -t test .
docker run test
# Output: (vacío)

docker run test "Hola"
# Output: Hola ✅
# ENTRYPOINT echo + argumentos "Hola"
```

## **ENTRYPOINT + CMD (combinación)**

A veces se usan juntos:

```dockerfile
FROM alpine:3.20
ENTRYPOINT ["mysql"]      # ← Punto de entrada
CMD ["-h", "localhost"]   # ← Argumentos por defecto
```

```bash
docker run mydb
# → mysql -h localhost ✅

docker run mydb -h 192.168.1.5
# → mysql -h 192.168.1.5 ✅ (CMD reemplazado)
```

**Pregunta:** "¿Por qué usas ENTRYPOINT en lugar de CMD?"

**Respuesta correcta:**
> Porque necesito garantizar que ciertos pasos se ejecuten **siempre**:
> 1. Leer credenciales de `/run/secrets/`
> 2. Esperar a que MariaDB esté listo
> 3. Instalar WordPress si no existe
> 4. Ejecutar php-fpm
>
> Si algún usuario o herramienta pasa un comando diferente, estos pasos críticos se saltarían y el contenedor fallaría. ENTRYPOINT fuerza que **SIEMPRE** se ejecute el script de inicialización.

En Inception, **ENTRYPOINT es la decisión correcta** porque el setup es obligatorio.

---

## **¿Qué es un volumen?**
Un volumen es un **mecanismo de persistencia de datos** en Docker. Los datos dentro de un contenedor se pierden al eliminarlo, pero los volúmenes persisten fuera del ciclo de vida del contenedor.

---

## **Named volume vs bind mount**

| Tipo | Sintaxis | Gestionado por | Persistencia |
|------|---------|---|---|
| **Bind mount** | `/host/path:/container/path` | Sistema de archivos | Manual |
| **Named volume** | `volume_name:/container/path` | Docker | Automática |

En Inception usamos **named volumes con bind mount de backend** (lo mejor de ambos):
```yaml
device: /home/brivera/data/mariadb  # Persiste en /home
```

---

## **Docker network**
Es un sistema de **comunicación interna entre contenedores**. Permite que un contenedor se comunique con otro usando nombres de servicio como DNS:
```
wordpress:9000  → resuelve al contenedor "wordpress"
mariadb:3306    → resuelve al contenedor "mariadb"
```

---

## **Bridge network**
Es el **tipo de network por defecto** en Docker Compose. Crea una red virtual donde:
- Los contenedores pueden comunicarse por nombre
- Están aislados de redes externas (excepto si exponen puertos)
- Es lo que usamos en Inception (`driver: bridge`)

---

## **Reverse proxy**
Es un servidor intermedio que:
1. **Recibe** tráfico del cliente (HTTPS en puerto 443)
2. **Redirige** internamente hacia la aplicación real (WordPress en puerto 9000)
3. **Oculta** la arquitectura interna del cliente

**Ventajas:**
- SSL/TLS centralizado
- Load balancing
- Seguridad (ocultamos IPs internas)
- Flexibilidad (puedo cambiar backend sin cambiar el cliente)

---

## **SSL/TLS**
Protocolo de **cifrado de comunicaciones**:
- **SSL**: Old (deprecated)
- **TLS**: Modern, reemplazo de SSL

Usamos certificados digitales (público + privado) para autenticar y cifrar la comunicación entre cliente y servidor.

---

## **TLS 1.2 vs TLS 1.3**

| Versión | Año | Handshake | Seguridad | Estado |
|---------|-----|-----------|-----------|--------|
| **TLS 1.2** | 2008 | 2 round trips | Muy buena | Estándar |
| **TLS 1.3** | 2018 | 1 round trip | Excelente | Modern |

TLS 1.3 es más rápido y seguro. Nosotros soportamos ambas en NGINX:
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

---

## **¿Qué es php-fpm?**
**FastCGI Process Manager** para PHP. Es un servidor que:
- **Escucha** en un puerto (9000 en nuestro caso)
- **Ejecuta** código PHP
- **Se comunica** con NGINX mediante FastCGI (protocolo)

NGINX **no ejecuta PHP**, solo redirige las peticiones a `php-fpm`.

---

## **¿Cómo se comunican WordPress y MariaDB?**
1. WordPress intenta conectar a `mariadb:3306` (hostname + puerto)
2. Docker Network resuelve `mariadb` → IP del contenedor
3. PHP abre conexión TCP a ese IP:3306
4. MariaDB autentica con credenciales vía secrets (`DB_PASSWORD`)
5. Se ejecutan queries MySQL

Todo ocurre **dentro de la red bridge inception**, sin pasar por internet.

---

## **¿Por qué NGINX no está dentro del contenedor WordPress?**
**Separación de responsabilidades:**
- **WordPress** = lógica de aplicación (PHP)
- **NGINX** = servidor web + TLS + reverse proxy

Si los mezclamos:
- ❌ Difícil de escalar
- ❌ Monolítico
- ❌ Imposible cambiar frontend sin cambiar app
- ❌ Problemas de permisos y procesos

Separados:
- ✅ Cada servicio hace una cosa bien
- ✅ Escalable (puedo tener 5 WordPress detrás de 1 NGINX)
- ✅ Flexible
- ✅ Mantenible

---

## **¿Por qué no se puede usar "admin" como usuario?**
Por **prevención de ataques de fuerza bruta**:

Si el usuario admin siempre es "admin", un atacante solo necesita:
1. Conoce el username (`admin`)
2. Solo tiene que probar contraseñas

Nosotros usamos `brivera42` como admin, así el atacante tiene que adivinar tanto username como password → exponencialmente más difícil.

---

## **¿Por qué no se permite "latest"?**
Porque **rompe reproducibilidad**:

```dockerfile
FROM alpine:latest  # ❌ ¿latest de qué mes?
FROM alpine:3.20    # ✅ Siempre la misma versión
```

Si usas `latest`:
- ❌ Hoy puedes usar 3.20, mañana 3.21 (cambios incompatibles)
- ❌ Tu proyecto no funciona en 2 días
- ❌ No reproducible
- ❌ Imprevisible

Las versiones estables garantizan que el código siga funcionando.

---

## **¿Por qué no se permiten loops infinitos?**
Porque **rompen el control de procesos**:

```bash
# ❌ NO hacer esto como entrypoint:
while true; do
  mysqld
  sleep 1
done

# O esto:
mysqld &
while true; do sleep 1; done
```

**Problemas:**
- El PID 1 es el `while`, no `mysqld`
- Si `mysqld` falla, `while` lo reinicia pero Docker no se entera
- SIGTERM llega al `while`, no a `mysqld` → no se apaga limpiamente
- El contenedor se queda "colgado" en lugar de parar

**Solución:**
```bash
exec mysqld  # mysqld es PID 1
             # Lleva las señales directamente
             # Se apaga limpiamente
```

---

Te voy a dar **explicaciones defensibles** para cada concepto, con ejemplos prácticos de tu proyecto:

---

## **Docker vs VM - Arquitectura**

### **Máquina Virtual:**
```
┌─────────────────────────────────────┐
│ Aplicación                          │
├─────────────────────────────────────┤
│ Sistema Operativo (Ubuntu, etc)     │ ← Kernel propio
├─────────────────────────────────────┤
│ Hypervisor (VirtualBox, ESXi)       │ ← Simula hardware
├─────────────────────────────────────┤
│ Hardware Host                       │
└─────────────────────────────────────┘
```

**Cada VM necesita:**
- ✅ Un kernel Linux/Windows completo
- ✅ Sistema de archivos completo
- ✅ Drivers de hardware virtualizados
- ✅ **Almacenamiento**: 1-10 GB por VM
- ✅ **RAM**: 500 MB - 2 GB mínimo por VM
- ✅ Tiempo de boot: 30-60 segundos

---

### **Docker (Contenedores):**
```
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ App 1        │ │ App 2        │ │ App 3        │
├──────────────┤ ├──────────────┤ ├──────────────┤
│ Librerías    │ │ Librerías    │ │ Librerías    │
├──────────────┤ ├──────────────┤ ├──────────────┤
│     Kernel Linux compartido         │ ← Una sola copia
└────────────────────────────────────┘
│ Hardware Host
└────────────────────────────────────┘
```

**Contenedores:**
- ✅ Comparten el kernel del host
- ✅ Solo incluyen librerías + app (sin kernel)
- ✅ **Almacenamiento**: 50-500 MB por contenedor
- ✅ **RAM**: 10-50 MB mínimo
- ✅ Tiempo de boot: 1-2 segundos

---

### **En tu proyecto Inception:**
```bash
# Listar contenedores actuales
docker ps

# Son 3 contenedores (60-100 MB cada uno):
# - mariadb (con MySQL)
# - wordpress (con PHP)
# - nginx (servidor web)
```

Si los hicieras VMs serían 3×2GB = **6GB solo en SO**, más servicios = **impracticable**.

---

## **Imagen vs Contenedor - Ciclo de Vida**

### **Imagen = Plantilla (inmutable)**
```dockerfile
# Dockerfile → Imagen
FROM alpine:3.20          # Base

RUN apk add mysql         # Añado paquetes
RUN mkdir /var/lib/mysql  # Crear directorios
RUN chmod +x /init.sh     # Permisos

ENTRYPOINT ["/init.sh"]   # Comando al arrancar
```

**Una vez construida** (con `docker build`):
- ✅ No cambia
- ✅ Puedo copiarla a mil máquinas
- ✅ Siempre igual
- ✅ Ocupan espacio en disco (read-only)

```bash
docker images
# REPOSITORY            TAG      IMAGE ID
# inception-mariadb     latest   b5ed735a83d7
# inception-wordpress   latest   6237d7a947af
```

---

### **Contenedor = Instancia en ejecución (mutable)**
```bash
docker run inception-mariadb

# Dentro del contenedor sucede:
# 1. Se copia la imagen como filesystem
# 2. Se crea una "capa de escritura" (layer)
# 3. Se ejecuta ENTRYPOINT
# 4. mysqld comienza a escribir datos
```

**Mientras corre:**
- ✅ Puedo cambiar archivos (layer de escritura)
- ✅ Puedo eliminar archivos
- ✅ Datos se pierden al parar (EXCEPTO volúmenes)

```bash
docker ps
# CONTAINER ID    IMAGE         NAMES      STATUS
# 08a919e816a4    inception-mariadb   mariadb    Up 10 minutes
```

---

### **Analogía:**
- **Imagen**: Plantilla Word (.docx)
- **Contenedor**: Documento abierto editando

---

## **Docker Compose - Orquestación**

### **Sin Docker Compose (manual):**
```bash
# 1. Crear red
docker network create inception

# 2. Crear volúmenes
docker volume create mariadb_data
docker volume create wordpress_data

# 3. Arrancar MariaDB
docker run -d \
  --name mariadb \
  --network inception \
  -v mariadb_data:/var/lib/mysql \
  inception-mariadb

# 4. Arrancar WordPress
docker run -d \
  --name wordpress \
  --network inception \
  -v wordpress_data:/var/www/html \
  --depends-on mariadb \
  inception-wordpress

# 5. Arrancar NGINX
docker run -d \
  --name nginx \
  --network inception \
  -p 443:443 \
  -v wordpress_data:/var/www/html \
  --depends-on wordpress \
  inception-nginx

# ❌ Error si olvidas algo, orden importa, frágil
```

---

### **Con Docker Compose (declarativo):**
```yaml
version: '3.8'
services:
  mariadb:
    build: requirements/mariadb
    networks:
      - inception
    volumes:
      - mariadb_data:/var/lib/mysql

  wordpress:
    build: requirements/wordpress
    networks:
      - inception
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - mariadb

  nginx:
    build: requirements/nginx
    networks:
      - inception
    ports:
      - "443:443"
    depends_on:
      - wordpress

volumes:
  mariadb_data:
  wordpress_data:

networks:
  inception:
```

```bash
# ✅ Listo en una línea
docker compose up -d

# O con Makefile
make
```

---

### **Docker Compose hace:**
1. **Lee el YAML**
2. **Crea la red** inception automáticamente
3. **Crea volúmenes** con el nombre del proyecto
4. **Arranca servicios en orden** (respetando `depends_on`)
5. **Conecta todos** a la red
6. **Gestiona todo** con una sola orden

---

## **Volúmenes - Persistencia**

### **Problema sin volúmenes:**
```bash
docker run inception-mariadb

# Pasan 1000 querys, datos en /var/lib/mysql

docker stop mariadb
docker rm mariadb

# ❌ PERDIDO TODO

docker run inception-mariadb
# ❌ Base de datos vacía
```

---

### **Solución: Volúmenes**
```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/brivera/data/mariadb
```

```bash
# Dentro del contenedor
/var/lib/mysql  →  (montaje hacia)  →  /home/brivera/data/mariadb

# Los datos se escriben en el host
ls /home/brivera/data/mariadb/
# mysql/  wordpress/  ibdata1  ...

docker stop mariadb
docker rm mariadb

docker compose up -d  # Releva el volumen

# ✅ Los datos siguen intactos
mysql> SELECT * FROM wordpress.wp_posts;
# Todos los artículos siguen ahí
```

---

### **¿Por qué Docker gestiona volúmenes?**
Docker **no deja que se borren accidentalmente**:
```bash
docker volume rm mariadb_data

# Error si hay contenedor usando ese volumen
# ✅ Protección contra pérdida de datos
```

---

## **Reverse Proxy (NGINX) - Estrategia de Seguridad**

### **Sin reverse proxy (❌ inseguro):**
```
Cliente HTTPS        WordPress
│                    │
└── (443:8000) ──────> :8000 (PHP-FPM)
                     │
                     Expone aplicación directamente
```

**Problemas:**
- Cliente ve que es WordPress
- Cambiar puerto = cambiar código
- No hay control central
- Difícil agregar autenticación
- SSL en cada app = complicado

---

### **Con reverse proxy (✅ seguro):**
```
┌─────────────────────────────────────┐
│ Cliente HTTPS (443)                 │
└──────────┬──────────────────────────┘
           │
      (TLS/SSL)
           │
┌──────────▼──────────────────────────┐
│ NGINX Reverse Proxy                 │ ← Encriptación central
│ - Recibe HTTPS                      │
│ - Desencripta                       │
│ - Redirige por HTTP interno         │
└──────────┬──────────────────────────┘
           │ (HTTP sin encriptar)
           │ (Intranet, seguro)
┌──────────▼──────────────────────────┐
│ WordPress:9000 (php-fpm)            │ ← Oculto
│ - No expone puerto público          │
│ - No maneja certs SSL               │
│ - Solo HTTP interno                 │
└─────────────────────────────────────┘
```

---

### **En tu docker-compose.yml:**
```yaml
nginx:
  ports:
    - "443:443"           # ← Solo puerto 443
  volumes:
    - wordpress_data:/var/www/html
  
wordpress:
  expose:
    - 9000                # ← NO publica puerto
  volumes:
    - wordpress_data:/var/www/html
```

---

### **Ventajas:**
1. **Seguridad**: Cliente no ve que es WordPress
2. **SSL centralizado**: NGINX maneja certs, WordPress no
3. **Escalabilidad**: Puedo tener 5 WordPress detrás de 1 NGINX
4. **Flexibilidad**: Cambiar backend sin cambiar cliente
5. **Control**: Puedo:
   - Rate limiting
   - Cacheo
   - Compresión
   - Autenticación básica
   - Load balancing

---

## **php-fpm - Comunicación NGINX+PHP**

### **¿Por qué separar NGINX de PHP?**

#### **Opción 1: Todo en uno (❌ acoplado)**
```dockerfile
FROM alpine:3.20

RUN apk add nginx php-fpm

ENTRYPOINT nginx & php-fpm & wait
```

**Problemas:**
- ❌ Difícil de escalar
- ❌ Si PHP se cuelga, NGINX no se entera
- ❌ Permisos complicados
- ❌ Cada cambio requiere rebuild

---

#### **Opción 2: Separados (✅ limpio)**
```dockerfile
# wordpress/Dockerfile
FROM alpine:3.20
RUN apk add php83-fpm
EXPOSE 9000
ENTRYPOINT ["php-fpm83", "-F"]

# nginx/Dockerfile
FROM alpine:3.20
RUN apk add nginx
EXPOSE 443
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```

---

### **¿Cómo hablan entre sí?**

**NGINX conf:**
```nginx
location ~ \.php$ {
    fastcgi_pass wordpress:9000;  # ← Habla con php-fpm
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```

**Flujo:**
```
Cliente → HTTPS → NGINX (443)
                    │
                    ├─ Recibe: GET /index.php
                    ├─ Ve que es .php
                    │
                    └─ FastCGI → wordpress:9000
                           │
                           ├─ php-fpm ejecuta index.php
                           ├─ Genera HTML
                           │
                           └─ Responde HTTP
                               │
                               ← Devuelve a cliente
```

---

### **FastCGI = Protocolo intermedio:**
- No es HTTP
- Es binario (más rápido)
- Permite pasar variables
- Permite mantener procesos en background

```bash
# Ver php-fpm escuchando en el contenedor
docker exec wordpress netstat -tlnp | grep 9000
# tcp  0  0 0.0.0.0:9000  0.0.0.0:*  LISTEN  1/php-fpm
```

---

## **Docker Network - DNS Interno**

### **Sin network (❌ no funciona):**
```bash
docker run -d --name mariadb inception-mariadb
docker run -d --name wordpress inception-wordpress

# Del WordPress:
mysql -h mariadb -u user -p password

# ❌ Error: mariadb: Name or service not known
# No hay DNS, no sé qué IP es "mariadb"
```

---

### **Con network (✅ funciona):**
```yaml
networks:
  inception:
    driver: bridge

services:
  mariadb:
    networks:
      - inception

  wordpress:
    networks:
      - inception
```

```bash
# Docker crea DNS interno
# mariadb  → 172.20.0.2
# wordpress → 172.20.0.3

# Del WordPress:
mysql -h mariadb -u user -p password

# ✅ Funciona, Docker resuelve mariadb → 172.20.0.2
```

---

### **¿Cómo funciona internamente?**

```bash
# Dentro del contenedor WordPress
cat /etc/resolv.conf
# nameserver 127.0.0.11:53  ← Docker embedded DNS

# El daemon dockerd sabe dónde está cada servicio
# y redirige las queries correctamente
```

---

### **Ventajas:**
- ✅ Nombres en lugar de IPs
- ✅ Si para/reinicia un contenedor, cambia IP pero nombre igual
- ✅ Aislado (desde afuera no puedo acceder)
- ✅ Automático (Docker lo crea)

---

## **TLS 1.2 vs TLS 1.3 - Protocolo de Encriptación**

### **En tu certificado:**
```bash
docker exec nginx openssl x509 -in /etc/nginx/ssl/server.crt -text -noout

# Verás:
# Subject: C=ES, ST=Madrid, L=Madrid, O=42, CN=brivera.42.fr
# Public-Key: (2048 bit)
```

### **¿Qué significa TLS 1.2 y 1.3?**

#### **TLS 1.2 (2008):**
```
Client                              Server (NGINX)
   │                                   │
   ├─ ClientHello ──────────────────→  │
   │                                   │
   │  ← ServerHello, cert ─────────────┤
   │                                   │
   ├─ ClientKeyExchange ──────────────→  │
   │                                   │
   │  ← ChangeCipherSpec, Finished ───┤
   │                                   │
   └─ 2 round trips, 2-3 segundos ────→  En clientes lejanos

Seguridad: Muy buena (128/256 bits)
```

#### **TLS 1.3 (2018):**
```
Client                              Server (NGINX)
   │                                   │
   ├─ ClientHello + Keys ─────────────→  │
   │                                   │
   │  ← ServerHello, cert, Finished ──┤
   │                                   │
   └─ 1 round trip, <100ms ───────────→  Más rápido

Seguridad: Excelente (128/256 bits)
```

---

### **En tu nginx.conf:**
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

**Por qué ambas:**
- ✅ **TLS 1.3**: Nuevos clientes (Chrome 70+, Firefox 60+)
- ✅ **TLS 1.2**: Clientes antiguos (para compatibilidad)
- ❌ **NO TLS 1.0/1.1**: Ya están roto, deprecated

---

### **Diferencias clave:**

| Aspecto | TLS 1.2 | TLS 1.3 |
|---------|---------|---------|
| **Handshake** | 2 round trips | 1 round trip |
| **Latencia** | 2-3 RTT | 0 RTT (resumption) |
| **Ciphers** | Muchas opciones | Solo modernas |
| **Forward secrecy** | Sí (DH) | Siempre |
| **Deprecado** | No | No (futuro) |

---

## **Seguridad en Inception - Principios**

### **1. No exponer puertos innecesarios:**
```yaml
nginx:
  ports:
    - "443:443"    # ✅ Solo HTTPS

wordpress:
  # NO tiene ports
  # NGINX accede por red interna

mariadb:
  # NO tiene ports
  # Solo WordPress accede
```

```bash
# Verificar qué puertos se exponen
docker ps --format "table {{.Names}}\t{{.Ports}}"

# NAMES       PORTS
# nginx       0.0.0.0:443->443/tcp  ← Único puerto público
# wordpress   (no hay puertos)
# mariadb     (no hay puertos)
```

---

### **2. Credenciales en variables, no en código:**

#### **❌ MAL:**
```dockerfile
ENV DB_PASSWORD=admin123  # ← Visible en docker inspect
RUN mysqld --password='admin123'
```

---

#### **✅ BIEN:**
```yaml
secrets:
  db_password:
    file: ../secrets/db_password

services:
  mariadb:
    secrets:
      - db_password
```

```bash
# Dentro del contenedor
cat /run/secrets/db_password
# admin123

# Pero está como archivo, no como ENV visible
docker inspect mariadb | grep -i password
# (no aparece)
```

---

### **3. No usar "latest" (reproducibilidad):**

#### **❌ Frágil:**
```dockerfile
FROM alpine:latest

# Hoy: alpine 3.20
# Mañana: alpine 3.21 (cambios incompatibles)
# 6 meses: alpine 4.0 (rompe todo)
```

---

#### **✅ Robusto:**
```dockerfile
FROM alpine:3.20

# Siempre 3.20
# En 5 años sigue siendo 3.20
# Reproducible
```

---

### **4. No usuario "admin" predecible:**

#### **❌ Débil:**
```bash
# Atacante conoce username: "admin"
# Solo tiene que descifrar contraseña
# Ataque de fuerza bruta más rápido
```

---

#### **✅ Fuerte:**
```bash
WP_ADMIN_USER=brivera42  # ✅ No contiene "admin"
WP_USER=wpeditor         # ✅ Segundo usuario

# Atacante tiene que adivinar:
# 1. Que existen usuarios
# 2. Su nombre exacto
# 3. Su contraseña
# Exponencialmente más seguro
```

---

### **Resumen de Seguridad en tu proyecto:**

```
EXTERIOR                 INTERIOR
(Internet)               (Red bridge: inception)

Cliente HTTPS
    │
    ├─ Puerto 443 (único)
    ▼
NGINX (certificado SSL TLS 1.2/1.3)
    │ HTTP (sin encriptar, intranet)
    ├─────> wordpress:9000 (oculto)
    │
    └─────> mariadb (oculto)

Credenciales: En secrets/ (no en Dockerfile)
Usuario admin: brivera42 (no contiene "admin")
Versiones: Específicas (no latest)
```

---

## **Defensa final: 

✅ **Separación de responsabilidades**: Cada contenedor hace una cosa
✅ **Seguridad**: Mínima exposición, máxima protección
✅ **Reproducibilidad**: Dockerfile versionados, no latest
✅ **Persistencia**: Volúmenes con datos en host
✅ **Comunicación**: Red interna Docker, DNS automático
✅ **SSL/TLS**: Reverse proxy con encriptación moderna