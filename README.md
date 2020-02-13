# Step by step Kong Api Gateway

Kong es una aplicación programada en Lua que se ejecuta en Nginx aprovechando el módulo lua-nginx. Esta base permite que Kong sea extensible a través de una arquitectura de scripts Lua (denominados "complementos") que se pueden cargar en ‘caliente’, mientras está en ejecución.

En Mashape LLC, antiguo nombre de la compañía, en la actualidad Kong Inc, se construyó Kong originalmente para asegurar, administrar y extender más de 15.000 API y microservicios para su API Marketplace, con más de miles de millones de solicitudes por mes para más de 200.000 desarrolladores. Hoy en día, Kong se utiliza en implementaciones muy críticas en organizaciones tanto grandes como pequeñas. Durante los últimos años se ha ganado el éxito, dando servicios a empresas como Skyscanner, Harvard University, HealthCare.gov, Yahoo!, The New York Times, Nokia, Intel, GIPHY o Ferrari.


Algunas caracteristicas interesantes:
Construido sobre NGINX
En su mayor parte escrito en LUA
Ampliable a través de muchos complementos / addins
Admite dos tipos de base de datos, que también se pueden usar simultáneamente (Postgres, cassandra)
Agnostico a la plataforma (disponible para debian / Ubuntu, RedHat / Centos, Docker, AWS, Google Cloud y muchos más).

![Alt text](resources/img/kong.png?raw=true " ")

Kong te permite conectar todos tus microservicios y API’s de forma escalable y flexible. Acelerando tus servicios al disminuir la latencia de tus desarrollos. Kong se encarga de facilitarte todo lo necesario para satisfacer la demanda de tus necesidades y gestión de API Gateway.

Kong se adapta a todo tipo de arquitecturas, desde aplicaciones monolíticas, microservicios, mesh o serverless.

![Alt text](resources/img/architecture.png?raw=true " ")


## Levantando el ambiente de prueba

Creamos una red interna para los containers que vamos a utilizar
```
docker network create kong-net
```

Creamos el container de Cassandra 
```
docker run -d --name kong-cassandra-database --network=kong-net -p 9042:9042 cassandra:3
```

Creamos el container de Postgres
```
docker run -d --name kong-postgres-database --network=kong-net -p 5432:5432 -e "POSTGRES_USER=kong" -e "POSTGRES_DB=kong"  postgres:9.6
```

Corremos el kong migrations para generar lo necesario para correr nuestro servicio
```
docker run --rm --network=kong-net -e "KONG_DATABASE=postgres" -e "KONG_PG_HOST=kong-postgres-database" -e "KONG_CASSANDRA_CONTACT_POINTS=kong-postgres-database" kong:latest kong migrations bootstrap 
```  

Creamos el container de Kong con la vinculacion a los containers que creamos con anterioridad
```
docker run -d --name kong --network=kong-net -e "KONG_DATABASE=postgres" -e "KONG_PG_HOST=kong-postgres-database" -e "KONG_CASSANDRA_CONTACT_POINTS=kong-cassandra-database" -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" -e "KONG_PROXY_ERROR_LOG=/dev/stderr" -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" -p 8000:8000 -p 8443:8443 -p 8001:8001 -p 8444:8444 kong:latest
```

El uso y la descripción del puerto son los siguientes:
- 8000: puerto proxy no habilitado para SSL para solicitudes de API
- 8443: puerto proxy habilitado para SSL para solicitudes de API
- 8001: API de administración RESTful para la configuración. Este es el puerto que se utilizará para interactuar y configurar Kong
- 7946 - Puerto utilizado para la agrupación de Kong

Todo el Script se encuentra en
```
run_kong.cmd
```

 