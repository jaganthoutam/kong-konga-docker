This Repository allows to deploy Kong Api Gateway and Konga Kong management GUI as docker containers by using the provided docker-compose files.

Also, it provides a Dockerfile for building a custom Kong image which includes the custom plugins [request-throttling](https://github.com/millenc/kong-plugin-request-throttling) and [header-checker](https://github.com/albertocr/kong-plugin-header-checker) which can be deployed using the same docker-compose files.

## Deploy kong + psql-kong + konga

### For -at least- version 0.12.X to version 0.14.X
docker-compose -f docker-compose-kong-v0.14 up

### For -at least- version 1.3.X
docker-compose -f docker-compose-kong-v1.3.yml up

## Deploy a httpbin simple example service to test the API GW 
docker run -p 80:80 kennethreitz/httpbin

## Konga setup
1. Create a new user
2. Add the connection to Kong by indicating the IP Gateway of the container in the docker network
   obtained by doing `docker inspect {container_id}`

## redis-cli
If you install the request-throttling plugin to kong, you can connect to the redis server to
see the token which are being generated.

`docker run -it --network kong-setup_kong-net --rm redis redis-cli -h kong-setup_redis_1`

## KONG operations and configuration examples

### Add a service
curl -i -X POST   \
  --url http://localhost:8001/services/   \
  --data 'name=httpbin-service-get' \
  --data 'url=http://eu.httpbin.org/get'

### Add a route
curl -i -X POST   \
  --url http://localhost:8001/services/httpbin-service-get/routes \
  --data 'hosts[]=examplehttpbin.com'

### Forward a request to httpbin through kong
curl -i -X GET \
     --url http://localhost:8000/ \
     --header 'Host: examplehttpbin.com'

### Add key-auth plugin to the httpbin example service
curl -i -X POST   \
  --url http://localhost:8001/services/httpbin-service-get/plugins/ \
  --data 'name=key-auth'

### Add key-auth plugin adding one more key name appart from the default one
curl -i -X POST    \
     --url http://localhost:8001/services/httpbin-service-get/plugins/   \
     --data 'name=key-auth' \
     --data 'config.key_names=apikey, credentialtest'

### Create a consumer
curl -i -X POST \
  --url http://localhost:8001/consumers/ \
  --data "username=Jason"

### provisioning credentials for the consumer
curl -i -X POST \
  --url http://localhost:8001/consumers/Jason/key-auth/ \
  --data 'key=key1'

### Forward request through kong by using credentials
curl -i -X GET \
  --url http://localhost:8000 \
  --header "Host: examplehttpbin.com" \
  --header "apikey: key1"

### Forward request through kong by using credentials
curl -i -X GET \
  --url http://localhost:8000 \
  --header "Host: examplehttpbin.com" \
  --header "apikey: key1"
--header "user-agent:secretAgent"

### Add helloworld plugin -if it has been installed- to the httpbin example service
curl -i -X POST   \
  --url http://localhost:8001/services/httpbin-service-get/plugins/ \
  --data 'name=helloworld'

### Add headerchecker plugin to the httpbin example service
curl -i -X POST   \
  --url http://localhost:8001/services/httpbin-service-get/plugins/ \
  --data 'name=headerchecker'

### Add headerchecker plugin to the httpbin example service including more allowed agents appart from the default one
curl -i -X POST   \
     --url http://localhost:8001/services/httpbin-service-get/plugins/ \
     --data 'name=headerchecker' \
     --data 'config.allowed_users=additionalSecretAgent'

### Add route to service with path
 curl -i -X POST   \
  --url http://localhost:8001/services/httpbin-service-get/routes \
   --data 'paths[]=/httpbin/get'

### Request with API Key credentials
curl -i -X GET \
  --url http://localhost:8000 \
  --header "Host: examplehttpbin.com" \
  --header "apikey: key1"

### Add plugin associated to a route
curl -i -X POST \
     --url http://localhost:8001/routes/`{route_id}`/plugins/ \
     --data 'name=headerchecker'

### Add a plugin (headerchecker in this case) associated to a consumer and a route
curl -i -X POST  \
     --url http://localhost:8001/consumers/`{consumer_id}`/plugins \
     --data 'name=headerchecker' \
     --data 'route_id=`{route_id}`' \
     --data 'config.allowed_header_values=secretAgent'

##  Get request to a route with the API Key credentials and the header that has to be checked
curl -i -X GET \
     --url http://localhost:8000/httpbin/post \
     --header "apikey: key1" \
     --header "user-agent: secretAgent"

##  Add headerchecker plugin with complete configuration to a route
curl -i -X POST \
     --url http://localhost:8001/consumers/`{consumer_id}`/plugins \
     --data 'name=headerchecker' \
     --data 'route_id=`{route_id}`' \
     --data 'config.header_to_check=user-agent' \
     --data 'config.allowed_header_values=secretAgent1, secretAgent2'
