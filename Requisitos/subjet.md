# Inception

**Resumen:** Este documento describe un ejercicio de 42 relacionado con Administración de Sistemas.
**Versión:** 5.2


## I. Introducción

Este proyecto tiene como objetivo ampliar conocimientos en administración de sistemas utilizando Docker.
Virtualizar varias imágenes de Docker, creándolas en una máquina virtual personal.


## II. Reglas generales

* Este proyecto debe realizarse en una **Máquina Virtual**.
* Todos los archivos necesarios para la configuración deben estar dentro de una carpeta `srcs`.
* Se requiere un **Makefile** en la raíz del repositorio.
  Debe configurar toda la aplicación (es decir, construir las imágenes Docker usando `docker-compose.yml`).
* Este proyecto requiere aplicar conceptos nuevos. Se recomienda leer documentación sobre Docker y cualquier recurso útil para completar la consigna.


## III. Instrucciones sobre IA

### Contexto

Durante el proceso de aprendizaje, la IA puede ayudar en muchas tareas. Se puede explorar sus capacidades, pero siempre con espíritu crítico. Nunca se puede estar completamente seguro de que la pregunta fue bien formulada o que el contenido generado es correcto.

### Reglas del estudiante

* Explorar las herramientas de IA y entender cómo funcionan.
* Reflexionar antes de escribir un prompt.
* Verificar, revisar y probar todo lo generado por IA.
* Buscar revisión de pares.


## IV. Parte obligatoria

Desplegar una pequeña infraestructura compuesta por distintos servicios, bajo reglas específicas.
Todo el proyecto debe hacerse en una **máquina virtual** usando **docker compose**.

### Requisitos generales

* Cada imagen Docker debe tener el mismo nombre que su servicio.
* Cada servicio debe correr en un contenedor dedicado.
* Las imágenes deben construirse desde la **penúltima versión estable de Alpine o Debian**.
* Escribir propios Dockerfiles (uno por servicio).
* Está prohibido usar imágenes ya hechas (excepto Alpine/Debian base).
* No se puede usar DockerHub para servicios preconfigurados.


### Servicios obligatorios

Se debe configurar:

* Un contenedor con **NGINX** usando solo **TLSv1.2 o TLSv1.3**.
* Un contenedor con **WordPress + php-fpm** (sin nginx).
* Un contenedor con **MariaDB** (sin nginx).
* Un volumen para la base de datos de WordPress.
* Un segundo volumen para los archivos del sitio WordPress.
* Deben ser **Docker named volumes** (no bind mounts).
* Los volúmenes deben guardarse en `/home/login/data` (reemplazar login por tu usuario).
* Una docker-network que conecte los contenedores.
* Los contenedores deben reiniciarse si fallan.


### Restricciones importantes

* Un contenedor NO es una máquina virtual.
* Prohibido usar hacks como:
  * `tail -f`
  * `sleep infinity`
  * `while true`
  * `bash` como proceso infinito
* Prohibido:
  * `network: host`
  * `--link`
  * `links:`
* La línea `network` debe estar presente en docker-compose.yml.
* No usar `latest` como tag.
* No deben existir contraseñas en los Dockerfiles.
* Es obligatorio usar variables de entorno.
* Es obligatorio usar un archivo `.env`.
* Se recomienda usar **Docker secrets**.

* Cualquier credencial en el repositorio → fracaso automático.

### WordPress

* Debe haber dos usuarios en la base de datos.
* Uno debe ser administrador.
* El usuario administrador NO puede llamarse:
  * admin
  * Admin
  * administrator
  * Administrator
  * ni variantes similares.


### Dominio

Debés configurar el dominio:

```
login.42.fr
```

para que apunte a tu IP local.

Ejemplo:
Si tu login es `mcasan`, entonces:

```
mcasan.42.fr

```

### Estructura del direcctorio
```
$> ls -alR
total XX
drwxrwxr-x 3 wil wil 4096 avril 42 20:42 .
drwxrwxrwt 17 wil wil 4096 avril 42 20:42 ..
-rw-rw-r-- 1 wil wil XXXX avril 42 20:42 Makefile
drwxrwxr-x 3 wil wil 4096 avril 42 20:42 secrets
drwxrwxr-x 3 wil wil 4096 avril 42 20:42 srcs

./secrets:
total XX
drwxrwxr-x 2 wil wil 4096 avril 42 20:42 .
drwxrwxr-x 6 wil wil 4096 avril 42 20:42 ..
-rw-r--r-- 1 wil wil XXXX avril 42 20:42 credentials.txt
-rw-r--r-- 1 wil wil XXXX avril 42 20:42 db_password.txt
-rw-r--r-- 1 wil wil XXXX avril 42 20:42 db_root_password.txt

./srcs:
total XX
drwxrwxr-x 3 wil wil 4096 avril 42 20:42 .
drwxrwxr-x 3 wil wil 4096 avril 42 20:42 ..
-rw-rw-r-- 1 wil wil XXXX avril 42 20:42 docker-compose.yml
-rw-rw-r-- 1 wil wil XXXX avril 42 20:42 .env
drwxrwxr-x 5 wil wil 4096 avril 42 20:42 requirements

./srcs/requirements:
total XX
drwxrwxr-x 5 wil wil 4096 avril 42 20:42 .
drwxrwxr-x 3 wil wil 4096 avril 42 20:42 ..
drwxrwxr-x 4 wil wil 4096 avril 42 20:42 bonus
drwxrwxr-x 4 wil wil 4096 avril 42 20:42 mariadb
drwxrwxr-x 4 wil wil 4096 avril 42 20:42 nginx
drwxrwxr-x 4 wil wil 4096 avril 42 20:42 tools
drwxrwxr-x 4 wil wil 4096 avril 42 20:42 wordpress

./srcs/requirements/mariadb:
total XX
drwxrwxr-x 4 wil wil 4096 avril 42 20:45 .
drwxrwxr-x 5 wil wil 4096 avril 42 20:42 ..
drwxrwxr-x 2 wil wil 4096 avril 42 20:42 conf
-rw-rw-r-- 1 wil wil XXXX avril 42 20:42 Dockerfile
-rw-rw-r-- 1 wil wil XXXX avril 42 20:42 .dockerignore
drwxrwxr-x 2 wil wil 4096 avril 42 20:42 tools
[...]

./srcs/requirements/nginx:
total XX
drwxrwxr-x 4 wil wil 4096 avril 42 20:42 .
drwxrwxr-x 5 wil wil 4096 avril 42 20:42 ..
drwxrwxr-x 2 wil wil 4096 avril 42 20:42 conf
-rw-rw-r-- 1 wil wil XXXX avril 42 20:42 Dockerfile
-rw-rw-r-- 1 wil wil XXXX avril 42 20:42 .dockerignore
drwxrwxr-x 2 wil wil 4096 avril 42 20:42 tools
[...]

$> cat srcs/.env
DOMAIN_NAME=wil.42.fr
# MYSQL SETUP
MYSQL_USER=XXXXXXXXXXXX
[...] $>
```

### NGINX

Debe ser el único punto de entrada.
Solo puede exponer el puerto **443** con TLSv1.2 o TLSv1.3.


## V. Requisitos del README

Debe existir un `README.md` en inglés que incluya:

* Primera línea en cursiva:

  > This project has been created as part of the 42 curriculum by <login>

* Sección Description

* Sección Instructions

* Sección Resources (incluyendo cómo se usó IA)

* Explicación comparativa entre:

  * Virtual Machines vs Docker
  * Secrets vs Environment Variables
  * Docker Network vs Host Network
  * Docker Volumes vs Bind Mounts


## VI. Prerrequisitos para validación

### USER_DOC.md

Saber explicar:

* Qué servicios ofrece el stack
* Cómo iniciar/detener el proyecto
* Cómo acceder al sitio y panel admin
* Cómo gestionar credenciales
* Cómo verificar que los servicios funcionan

### DEV_DOC.md

Saber explicar:

* Cómo configurar desde cero
* Cómo usar Makefile y Docker Compose
* Comandos para gestionar contenedores y volúmenes
* Dónde se almacenan los datos y cómo persisten

## VII. Bonus

Opciones:

* Redis cache para WordPress
* Servidor FTP
* Sitio web estático (no PHP)
* Adminer
* Otro servicio justificable

Se puede abrir más puertos en bonus.


## VIII. Entrega y evaluación

* Se evalúa únicamente lo que está en el repositorio.
* Pueden pedirte pequeñas modificaciones durante la defensa, para verificar que realmente entendés el proyecto.

