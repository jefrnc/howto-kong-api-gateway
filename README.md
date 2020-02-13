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

 https://docs.konghq.com/install/docker/



## Construccion del primer servicio y ruta

Primero se deberá agregar un Servicio; ese es el nombre que Kong usa para referirse a las API y microservicios ascendentes que administra.

A los fines de prueba  crearemos un Servicio que apunte a la API de Mockbin. 

Antes de que pueda comenzar a realizar solicitudes contra el Servicio, deberá agregarle una Ruta. Las rutas especifican cómo (y si) las solicitudes se envían a sus Servicios una vez que llegan a Kong. Un solo servicio puede tener muchas rutas.

Después de configurar el Servicio y la Ruta, podrá realizar solicitudes a través de Kong usándolos.

Kong expone una API de administración RESTful en el puerto: 8001. La configuración de Kong, incluida la adición de servicios y rutas, se realiza a través de solicitudes en esa API.

Creamos nuevo servicio example-service con el endpoint que vamos a tener http://mockbin.org
```
jefra@DESKTOP-O2Q0294 MINGW64 /c/Repos/Step-by-step-Kong-Api-Gateway (master)
$  curl -i -X POST \
>   --url http://localhost:8001/services/ \
>   --data 'name=example-service' \
>   --data 'url=http://mockbin.org'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   339  100   296  100    43  19733   2866 --:--:-- --:--:-- --:--:-- 22600HTTP/1.1 201 Created
Date: Thu, 13 Feb 2020 15:15:41 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Access-Control-Allow-Origin: *
Server: kong/2.0.1
Content-Length: 296
X-Kong-Admin-Latency: 7

{"host":"mockbin.org","created_at":1581606941,"connect_timeout":60000,"id":"a26912b7-b488-4e75-b94c-328e7d36abc6","protocol":"http","name":"example-service","read_timeout":60000,"port":80,"path":null,"updated_at":1581606941,"retries":5,"write_timeout":60000,"tags":null,"client_certificate":null}
```

Creamos la ruta del servicio example-service con el host que vamos a escuchar
```
jefra@DESKTOP-O2Q0294 MINGW64 /c/Repos/Step-by-step-Kong-Api-Gateway (master)
$ curl -i -X POST \
>   --url http://localhost:8001/services/example-service/routes \
>   --data 'hosts[]=example.com'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   448  100   429  100    19  25235   1117 --:--:-- --:--:-- --:--:-- 28000HTTP/1.1 201 Created
Date: Thu, 13 Feb 2020 15:16:49 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Access-Control-Allow-Origin: *
Server: kong/2.0.1
Content-Length: 429
X-Kong-Admin-Latency: 9

{"id":"bbac5b29-396d-4101-8678-f16404105794","path_handling":"v0","paths":null,"destinations":null,"headers":null,"protocols":["http","https"],"methods":null,"snis":null,"service":{"id":"a26912b7-b488-4e75-b94c-328e7d36abc6"},"name":null,"strip_path":true,"preserve_host":false,"regex_priority":0,"updated_at":1581607009,"sources":null,"hosts":["example.com"],"https_redirect_status_code":426,"tags":null,"created_at":1581607009}
```

Verificamos el funcionamiento 
```
jefra@DESKTOP-O2Q0294 MINGW64 /c/Repos/Step-by-step-Kong-Api-Gateway (master)
$ curl -i -X GET   --url http://localhost:8000/   --header 'Host: example.com'
```

Con esto tenemos seguridad de que ya esta atendiendo nuestra solicitud.


## Utilizar complementos
