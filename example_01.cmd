curl -i -X POST --url http://localhost:8001/services/ --data 'name=example-service' --data 'url=http://mockbin.org'
curl -i -X POST --url http://localhost:8001/services/example-service/routes --data 'hosts[]=example.com'
curl -i -X GET --url http://localhost:8000/ --header 'Host: example.com'