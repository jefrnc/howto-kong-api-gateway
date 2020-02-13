curl -i -X POST --url http://localhost:8001/services/example-service/plugins/ --data 'name=key-auth'
curl -i -X GET --url http://localhost:8000/  --header 'Host: example.com'