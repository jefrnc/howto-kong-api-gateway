FROM openresty/openresty:latest
RUN apt-get update ; exit 0
RUN apt-get --yes upgrade
RUN apt-get install --yes vim
RUN apt-get install --yes curl
RUN apt-get install  --yes libnginx-mod-http-ndk nginx-common libnginx-mod-http-lua
COPY default.conf /etc/nginx/conf.d/default.conf

RUN nginx & 
 
#URUN service nginx restart
EXPOSE 80
#USER 1001