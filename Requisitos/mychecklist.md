
# Checklist

1. Checklist técnica obligatoria (hard requirements)
2. Checklist de defensa (lo que me pueden preguntar)
3. Conceptos que tengo que saber explicar sí o sí
4. Puntos críticos que pueden cortar la evaluación


# 1. CHECKLIST TÉCNICA OBLIGATORIA

## Estructura del repositorio

* [ ] Existe carpeta `srcs/`
* [ ] Existe `docker-compose.yml` dentro de `srcs/`
* [ ] Existe archivo `.env` dentro de `srcs/`
* [ ] Existe `Makefile` en la raíz
* [ ] Existe `README.md` en la raíz (en inglés)
* [ ] Existen `USER_DOC.md` y `DEV_DOC.md` en la raíz
* [ ] Existe carpeta `requirements/` con subcarpetas por servicio
* [ ] Un `Dockerfile` por servicio
* [ ] Ningún Dockerfile está vacío


## Reglas prohibidas (si falla → termina evaluación)

* [ ] NO uso `network: host`
* [ ] NO uso `links:` ni `--link`
* [ ] NO uso `latest`
* [ ] NO uso imágenes prehechas (excepto base Alpine/Debian)
* [ ] NO hay contraseñas en Dockerfiles
* [ ] NO hay credenciales en el repo (fuera de secrets bien configurados)
* [ ] NO uso `tail -f`
* [ ] NO uso `sleep infinity`
* [ ] NO uso `while true`
* [ ] NO dejo procesos en background tipo `nginx & bash`
* [ ] No uso loops infinitos como entrypoint
* [ ] Uso penúltima versión estable de Alpine o Debian


## Docker Compose

* [ ] Hay una `network` definida en docker-compose.yml
* [ ] Todos los servicios están conectados a esa red
* [ ] Cada servicio tiene nombre igual a su imagen
* [ ] Los contenedores tienen `restart: always` o equivalente
* [ ] Solo NGINX expone puerto 443
* [ ] No se expone 80 públicamente


## Volúmenes (OBLIGATORIO)

* [ ] Uso Docker named volumes (NO bind mounts)
* [ ] Hay volumen para WordPress
* [ ] Hay volumen para MariaDB
* [ ] Ambos almacenan datos en `/home/login/data`
* [ ] `docker volume inspect` muestra esa ruta
* [ ] Después de reiniciar VM, los datos persisten


## NGINX

* [ ] Dockerfile propio
* [ ] Usa TLSv1.2 o TLSv1.3
* [ ] Certificado SSL configurado (puede ser self-signed)
* [ ] [http://login.42.fr](http://login.42.fr) NO funciona
* [ ] [https://login.42.fr](https://login.42.fr) funciona
* [ ] Es el único punto de entrada
* [ ] Actúa como reverse proxy hacia WordPress


## WordPress + php-fpm

* [ ] Dockerfile propio
* [ ] NO contiene nginx
* [ ] Usa php-fpm correctamente
* [ ] WordPress ya está instalado (no aparece pantalla de instalación)
* [ ] Hay 2 usuarios en la base
* [ ] Usuario admin NO contiene “admin”
* [ ] Puedo:

  * [ ] Loguearme
  * [ ] Crear comentario
  * [ ] Editar página
  * [ ] Ver cambios reflejados


## MariaDB

* [ ] Dockerfile propio
* [ ] NO contiene nginx
* [ ] Base creada automáticamente
* [ ] Usuario creado automáticamente
* [ ] Contraseñas vía variables de entorno
* [ ] Puedo entrar a la DB desde el contenedor
* [ ] La base no está vacía


## Persistencia

* [ ] Reinicio la máquina virtual
* [ ] Levanto `make`
* [ ] WordPress sigue configurado
* [ ] Los cambios siguen ahí
* [ ] La base sigue intacta


## Modificación en defensa

* [ ] Sé cambiar un puerto en docker-compose
* [ ] Sé reconstruir con `make re`
* [ ] Sé reiniciar sin romper todo
* [ ] Entiendo cómo se conectan los servicios


# 2. CHECKLIST DE DEFENSA (conceptos)


* [ ] ¿Qué es Docker?
* [ ] ¿Qué es una imagen?
* [ ] ¿Qué es un contenedor?
* [ ] ¿Qué es docker-compose?
* [ ] Diferencia entre Docker solo vs docker-compose
* [ ] Docker vs Máquina Virtual
* [ ] ¿Qué es un daemon?
* [ ] ¿Qué es PID 1?
* [ ] ¿Qué es un entrypoint?
* [ ] ¿Qué es un volumen?
* [ ] Named volume vs bind mount
* [ ] Docker network
* [ ] Bridge network
* [ ] Reverse proxy
* [ ] SSL/TLS
* [ ] TLS 1.2 vs 1.3
* [ ] ¿Qué es php-fpm?
* [ ] ¿Cómo se comunican WordPress y MariaDB?
* [ ] ¿Por qué NGINX no está dentro del contenedor WordPress?
* [ ] ¿Por qué no se puede usar admin como usuario?
* [ ] ¿Por qué no se permite latest?
* [ ] ¿Por qué no se permiten loops infinitos?

---

# 3. CONCEPTOS QUE TENGO QUE TENER CLARÍSIMOS

## Docker vs VM

VM:

* Virtualiza hardware
* Tiene kernel propio
* Más pesada

Docker:

* Comparte kernel
* Más liviano
* Más rápido

## Imagen vs Contenedor

Imagen:

* Plantilla inmutable

Contenedor:

* Instancia en ejecución de una imagen

## Docker Compose

* Orquesta múltiples servicios
* Define redes
* Define volúmenes
* Define dependencias

## Volúmenes

* Persisten datos fuera del ciclo de vida del contenedor
* No se borran al eliminar contenedor
* Son gestionados por Docker

## Reverse Proxy

NGINX:

* Recibe tráfico externo
* Redirige tráfico interno a WordPress
* Oculta arquitectura interna

## php-fpm

* FastCGI Process Manager
* Ejecuta código PHP
* Se comunica con NGINX

## Docker Network

* Permite comunicación interna entre contenedores
* Usa nombres de servicio como DNS interno

## Seguridad

* No exponer puertos innecesarios
* No credenciales en Dockerfiles
* No latest (versionado estable)
* No usuario admin predecible

# 4. PUNTOS QUE CORTAN EVALUACIÓN AUTOMÁTICAMENTE

Si falla cualquiera de estos, muere:

* Falta README requerido
* Falta USER_DOC o DEV_DOC
* Aparece pantalla de instalación WordPress
* No funciona https
* Funciona http
* No hay persistencia
* Uso de network: host
* Uso de latest
* Uso de imágenes prehechas
* Volúmenes mal configurados
* Admin contiene "admin"
* No puede modificar configuración en defensa
