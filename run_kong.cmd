#create an internal network for the containers
docker network create kong-net
#create a container for cassandra db
docker run -d --name kong-cassandra-database --network=kong-net -p 9042:9042 cassandra:3
#create a postgre sql container
docker run -d --name kong-postgres-database --network=kong-net -p 5432:5432 -e "POSTGRES_USER=kong" -e "POSTGRES_DB=kong"  postgres:9.6

#create a migration
docker run --rm --network=kong-net -e "KONG_DATABASE=postgres" -e "KONG_PG_HOST=kong-postgres-database" -e "KONG_CASSANDRA_CONTACT_POINTS=kong-postgres-database" kong:latest kong migrations bootstrap   
#create a kong container connected to the postgres and cassandra databases
docker run -d --name kong --network=kong-net -e "KONG_DATABASE=postgres" -e "KONG_PG_HOST=kong-postgres-database" -e "KONG_CASSANDRA_CONTACT_POINTS=kong-cassandra-database" -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" -e "KONG_PROXY_ERROR_LOG=/dev/stderr" -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" -p 8000:8000 -p 8443:8443 -p 8001:8001 -p 8444:8444 kong:latest


echo "The port usage and description is the following:"
echo "* 8000 – non-SSL enabled proxy port for API requests"
echo "* 8443 – SSL enabled proxy port for API requests"
echo "* 8001 – RESTful admin API for configuration. This is the port that will be used to interact and configure Kong"
echo "* 7946 – Port used for Kong clustering"