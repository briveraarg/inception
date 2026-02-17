
# INCEPTION

# General instructions

* Asegúrate de que todos los archivos necesarios estén dentro de `srcs`.
* Asegúrate de que haya un Makefile en la raíz.
* Antes de empezar, ejecuta el comando de limpieza de Docker.
* Lee docker-compose.yml. No debe haber `network: host` ni `links:`.
* Debe haber `network(s)`.
* No debe haber `--link` en ningún script.
* En los Dockerfiles no debe aparecer `tail -f` ni comandos en segundo plano.
* Los contenedores deben construirse desde la penúltima versión estable de Alpine o Debian.
* Ejecuta el Makefile.


# Mandatory part

Este proyecto implica configurar una pequeña infraestructura compuesta por diferentes servicios usando docker compose.

El estudiante evaluado debe explicar en términos simples:

* Cómo funcionan Docker y docker compose.
* La diferencia entre usar una imagen Docker con docker compose y sin docker compose.
* El beneficio de Docker comparado con máquinas virtuales.
* La pertinencia de la estructura de directorios requerida.

### Qué se espera del estudiante

Que entienda realmente Docker y no solo haya copiado configuraciones.

---

# README check

Debe existir README.md en la raíz.

La primera línea debe ser:

"This project has been created as part of the 42 curriculum by <login...>" (en cursiva).

Debe contener al menos:

* Description
* Instructions
* Resources (incluyendo explicación del uso de IA)

Si falta algo, la evaluación termina.

### Qué se espera del estudiante

Un README claro, profesional y completo.


# Documentation check

Debe haber:

* USER_DOC.md
* DEV_DOC.md

USER_DOC.md: instrucciones básicas para usuario o administrador.
DEV_DOC.md: instrucciones para desarrolladores.

Si falta alguno, termina la evaluación.

### Qué se espera del estudiante

Documentación real y funcional, no archivos vacíos.


# Simple setup

* NGINX accesible solo por puerto 443.
* Debe usar SSL/TLS.
* [https://login.42.fr](https://login.42.fr) debe funcionar.
* [http://login.42.fr](http://login.42.fr) no debe funcionar.
* No debe aparecer la página de instalación de WordPress.

Si algo falla, termina la evaluación.

### Qué se espera del estudiante

Infraestructura funcional, segura y correctamente configurada.


# Docker Basics

* Un Dockerfile por servicio.
* No pueden estar vacíos.
* No se pueden usar imágenes prehechas.
* Deben usar penúltima versión estable de Alpine/Debian.
* Nombre de imagen = nombre del servicio.
* El Makefile debe levantar todo correctamente.

Si algo falla, termina la evaluación.

### Qué se espera del estudiante

Que haya construido realmente su infraestructura.


# Docker Network

* Debe existir docker-network.
* Verificar con `docker network ls`.
* El estudiante debe explicar docker-network.

Si falla, termina evaluación.

### Qué se espera del estudiante

Que entienda cómo se comunican los contenedores.

---

# NGINX with SSL/TLS

* Debe haber Dockerfile.
* No debe funcionar por http (80).
* Debe funcionar por https.
* Debe usar TLSv1.2 o TLSv1.3.
* Puede ser certificado autofirmado.

### Qué se espera del estudiante

Configuración correcta de proxy inverso seguro.

# WordPress with php-fpm

* Debe haber Dockerfile.
* No debe contener nginx.
* Debe tener volumen en /home/login/data.
* Debe poder:

  * agregar comentario
  * loguearse como admin
  * admin no puede contener “admin”
  * editar página y ver cambios reflejados

### Qué se espera del estudiante

Persistencia real y WordPress completamente funcional.


# MariaDB and its volume

* Debe haber Dockerfile.
* No debe contener nginx.
* Debe tener volumen en /home/login/data.
* Debe poder explicar cómo loguearse a la DB.
* La base no debe estar vacía.

### Qué se espera del estudiante

Base de datos correctamente inicializada y persistente.


# Persistence

Reiniciar la máquina virtual.
Levantar docker compose nuevamente.
Todo debe seguir funcionando y los cambios deben mantenerse.

### Qué se espera del estudiante

Persistencia real de datos, no configuración temporal.


# Configuration modification

Durante la defensa, el evaluador pide modificar un servicio (por ejemplo cambiar puerto).

El estudiante debe:

* Modificar configuración.
* Reconstruir.
* Reiniciar.
* Mantener servicio funcionando.

Si no puede, termina evaluación.

### Qué se espera del estudiante

Dominio total del proyecto y capacidad de modificarlo en tiempo real.


# Bonus

Solo se evalúa si la parte obligatoria está perfecta.

* Redis
* FTP
* Sitio estático (no PHP)
* Adminer
* Servicio adicional justificado

+1 punto por cada bonus válido.

### Qué se espera del estudiante

Servicios adicionales bien integrados y correctamente justificados.
