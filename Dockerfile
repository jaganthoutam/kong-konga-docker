FROM kong:1.3.0-ubuntu	

MAINTAINER Qince Yang, qince.yang@accenture.com

ENV KONG_LUA_PACKAGE_PATH /kong-plugins/?.lua;;
ENV KONG_PLUGINS bundled,whispir_token_auth

ADD plugins/kong/plugins/ /kong-plugins/kong/

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 7946

CMD ["kong", "start"]
