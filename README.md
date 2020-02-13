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
curl -i -X POST \
   --url http://localhost:8001/services/ \
   --data 'name=example-service' \
   --data 'url=http://mockbin.org'
```
```
{"host":"mockbin.org","created_at":1581606941,"connect_timeout":60000,"id":"a26912b7-b488-4e75-b94c-328e7d36abc6","protocol":"http","name":"example-service","read_timeout":60000,"port":80,"path":null,"updated_at":1581606941,"retries":5,"write_timeout":60000,"tags":null,"client_certificate":null}
```

Creamos la ruta del servicio example-service con el host que vamos a escuchar
```
curl -i -X POST \
   --url http://localhost:8001/services/example-service/routes \
   --data 'hosts[]=example.com'
```

```
{"id":"bbac5b29-396d-4101-8678-f16404105794","path_handling":"v0","paths":null,"destinations":null,"headers":null,"protocols":["http","https"],"methods":null,"snis":null,"service":{"id":"a26912b7-b488-4e75-b94c-328e7d36abc6"},"name":null,"strip_path":true,"preserve_host":false,"regex_priority":0,"updated_at":1581607009,"sources":null,"hosts":["example.com"],"https_redirect_status_code":426,"tags":null,"created_at":1581607009}
```

Verificamos el funcionamiento 
```
$ curl -i -X GET   --url http://localhost:8000/   --header 'Host: example.com'
```

Con esto tenemos seguridad de que ya esta atendiendo nuestra solicitud.


## Utilizar complementos

Una de las ventajas mas copadas de Kong, es que podemos utilizar complementos en caliente.
Vamos a seguir la guia oficial que utiliza el plugin de key-auth, el cual espera que uno le especifique el apikey para solicitar el servicio, en caso que no enviarsela o ser la correcta vamoso a tener un error 401.  Con esto sacamos responsabilidad a los microservicios que podemos tener construido en nuestra arquitectura y Kong se encargara de admininistrar este aspecto.
 
```
curl -i -X POST \
   --url http://localhost:8001/services/example-service/plugins/ \
   --data 'name=key-auth'
```

```
{"created_at":1581608309,"config":{"key_names":["apikey"],"run_on_preflight":true,"anonymous":null,"hide_credentials":false,"key_in_body":false},"id":"2d898b1a-02f4-4268-a838-d7d93f2ebe17","service":{"id":"a26912b7-b488-4e75-b94c-328e7d36abc6"},"enabled":true,"protocols":["grpc","grpcs","http","https"],"name":"key-auth","consumer":null,"route":null,"tags":null}
```

Nota: Este complemento también acepta un parámetro config.key_names, que por defecto es ['apikey']. Es una lista de encabezados y nombres de parámetros (ambos son compatibles) que se supone que contienen la apikey durante una solicitud.


```
curl -i -X GET \
>   --url http://localhost:8000/ \
>   --header 'Host: example.com'
```

```
{"message":"No API key found in request"}
```

Como no especificó el encabezado o parámetro de apikey requerido, la respuesta debe ser 401 No autorizado.

## Consumer/Clientes de nuestros servicios

Los consumidores están asociados a personas que usan su Servicio, y se pueden usar para el seguimiento, la administración de acceso y más.

Nota: Esta sección asume que ha habilitado el complemento key-auth. Si no lo ha hecho, puede habilitar el complemento u omitir los pasos dos y tres

Creamos el cliente
```
curl -i -X POST \
   --url http://localhost:8001/consumers/ \
   --data "username=Jose"
```

```
{"custom_id":null,"created_at":1581609082,"id":"40f470b8-bd1d-466d-a32d-60c62b5bb5d8","tags":null,"username":"Jose"}
```

En mi caso particular creo el api por sistema
```
$ od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}'
0b0939da-2069-bfa9-48c2-336ca67256dd
```

Y le asocio este valor al usuario
```
curl -i -X POST \
   --url http://localhost:8001/consumers/Jose/key-auth/ \
   --data 'key=0b0939da-2069-bfa9-48c2-336ca67256dd'
```

```
{"created_at":1581609321,"consumer":{"id":"40f470b8-bd1d-466d-a32d-60c62b5bb5d8"},"id":"f1975bf1-060b-42a5-a9dc-e8708fe13567","tags":null,"ttl":null,"key":"0b0939da-2069-bfa9-48c2-336ca67256dd"}
```

Ahora verificamos el acceso a la api
```
$ curl -i -X GET   --url http://localhost:8000   --header "Host: example.com"   --header "apikey: 0b0939da-2069-bfa9-48c2-336ca67256dd"
```