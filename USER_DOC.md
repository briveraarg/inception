*Este proyecto fue creado como parte del currículo de 42 por brivera42.*

# Guía de Usuario | Inception

## ¿Qué servicios ofrece este proyecto?

La infraestructura despliega tres servicios:

| Servicio | Descripción | Puerto |
|---|---|---|
| NGINX | Servidor web con HTTPS | 443 |
| WordPress | Sitio web y panel de administración | interno 9000 |
| MariaDB | Base de datos | interno 3306 |

El único punto de entrada es NGINX en el puerto 443.
WordPress y MariaDB no son accesibles directamente desde el exterior.

---

## Iniciar y parar el proyecto

### Iniciar
```bash
cd ~/inception
make
```

### Parar (conserva los datos)
```bash
make down
```

### Parar y eliminar datos
```bash
make clean
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
├── db_password          → password del usuario de la base de datos
├── db_root_password     → password de root de MariaDB
├── wp_admin_password    → password del administrador de WordPress
├── wpuser_password      → password del usuario editor de WordPress
├── server.crt           → certificado TLS
└── server.key           → clave privada TLS
```

⚠️ Esta carpeta está en `.gitignore` 

---

## Verificar que los servicios están corriendo

### Ver estado de los contenedores
```bash
make status
```

Deberías ver tres contenedores con status `Up`:
```
NAME        STATUS          PORTS
nginx       Up X minutes    0.0.0.0:443->443/tcp
wordpress   Up X minutes    9000/tcp
mariadb     Up X minutes    3306/tcp
```

### Ver logs de los servicios
```bash
# Todos los servicios
make logs

# Un servicio específico
docker logs nginx
docker logs wordpress
docker logs mariadb
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
