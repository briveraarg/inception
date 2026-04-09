*Este proyecto fue creado como parte del currículo de 42 por brivera42.*

# Guía de Usuario | Inception

## ¿Qué servicios ofrece este proyecto?

La infraestructura despliega tres servicios obligatorios:

| Servicio | Descripción | Puerto |
|---|---|---|
| NGINX | Servidor web con HTTPS | 443 |
| WordPress | Sitio web y panel de administración | interno 9000 |
| MariaDB | Base de datos | interno 3306 |

El único punto de entrada es NGINX en el puerto 443.
WordPress y MariaDB no son accesibles directamente desde el exterior.

### Servicios Bonus (opcional)

Si ejecutas `make bonus`, se agregan dos servicios adicionales:

| Servicio | Descripción | Puerto |
|---|---|---|
| Redis | Caché en memoria para acelerar WordPress | interno 6379 |
| FTP | Servidor de transferencia de archivos | 21 |

Estos servicios se integran con la infraestructura principal y mejoran el rendimiento y la gestión del sitio.

---

## Iniciar y parar el proyecto

### Iniciar
```bash
cd ~/inception
make
```

### Iniciar con servicios bonus (Redis + FTP)
```bash
make bonus
```

### Parar (conserva los datos)
```bash
make down
```

### Parar servicios bonus
```bash
make bonus-down
```

### Parar y eliminar datos
```bash
make clean
```

### Ver estado de los contenedores
```bash
# Servicios principales
make ps

# Servicios bonus
make bonus-ps
```

### Ver logs
```bash
# Servicios principales
make logs

# Servicios bonus
make bonus-logs
```

---

## Acceder al sitio web

Desde la máquina virtual:
```bash
curl -k https://brivera.42.fr
```

El navegador mostrará un aviso de certificado no confiable — es normal
porque el certificado es autofirmado. Acepta la excepción para continuar.

---

### Acceder al panel de administración

La URL del panel de administración de WordPress es:
```
https://brivera.42.fr/wp-admin
```

Las credenciales están en la carpeta `secrets/`.

### Localizar y gestionar credenciales

Todas las credenciales están en la carpeta `secrets/`:
```
secrets/
├── db_password              → password del usuario de la base de datos
├── db_root_password         → password de root de MariaDB
├── wp_admin_password        → password del administrador de WordPress
├── wpuser_password          → password del usuario editor de WordPress
├── redis_password           → password de Redis (bonus)
├── ftp_password             → password del usuario FTP (bonus)
├── server.crt               → certificado TLS
└── server.key               → clave privada TLS
```

⚠️ Esta carpeta está en `.gitignore`

---

## Verificar que los servicios están corriendo

### Ver estado de los contenedores

**Servicios principales:**
```bash
make ps
```

Deberías ver tres contenedores con status `Up`:
```
NAME        STATUS          PORTS
nginx       Up X minutes    0.0.0.0:443->443/tcp
wordpress   Up X minutes    9000/tcp
mariadb     Up X minutes    3306/tcp
```

**Servicios bonus (si están habilitados):**
```bash
make bonus-ps
```

Deberías ver:
```
NAME        STATUS          PORTS
redis       Up X minutes    6379/tcp
ftp         Up X minutes    0.0.0.0:21->21/tcp
wordpress   Up X minutes    9000/tcp
mariadb     Up X minutes    3306/tcp
```

### Ver logs de los servicios
```bash
# Todos los servicios principales
make logs

# Un servicio específico
docker logs nginx
docker logs wordpress
docker logs mariadb

# Logs de bonus
make bonus-logs
docker logs redis
docker logs ftp
```

### Verificar WordPress
```bash
curl -k https://brivera.42.fr
```

### Verificar MariaDB
```bash
docker exec -it mariadb sh
mysql -u wpuser -p
# introduce la password de secrets/db_password
SHOW DATABASES;
exit
```

### Verificar usuarios de WordPress
```bash
docker exec -it wordpress sh
wp user list --allow-root --path=/var/www/html
exit
```

Deberías ver dos usuarios:
```
+----+------------+---------------+
| ID | user_login | roles         |
+----+------------+---------------+
| 1  | brivera42  | administrator |
| 2  | wpeditor   | author        |
+----+------------+---------------+
```

### Verificar Redis (bonus)

Si tienes habilitado el servicio bonus, puedes verificar Redis:

```bash
make bonus-redis-cli
```

En el prompt de Redis puedes ejecutar:
```redis
PING
# Debería mostrar: PONG

INFO stats
# Muestra estadísticas de Redis

GET key
SET key value
# Pruebas básicas de almacenamiento
```

### Verificar FTP (bonus)

Si tienes habilitado el servicio bonus, puedes acceder al FTP:

```bash
make bonus-ftp-cli
```

O usando un cliente FTP desde otro terminal:
```bash
# Con lftp
lftp -u usuario,contraseña ftp://localhost

# Las credenciales están en secrets/ftp_password
```

Desde el cliente FTP puedes:
```
ls                  # Listar archivos
cd wordpress        # Navegar a directorios
get archivo.txt     # Descargar archivos
put archivo.txt     # Subir archivos
quit                # Salir
```
