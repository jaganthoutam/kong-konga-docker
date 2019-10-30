FROM kong:1.3.0-ubuntu

MAINTAINER Jagadish Thoutam  <jag@thoutam.com>
LABEL Description="Kong docker image with header-checker and request-throttling plugins"

ENV KONG_LUA_PACKAGE_PATH /kong-plugins/?.lua;;
ENV KONG_PLUGINS bundled,whispir-token-auth

ADD plugins/kong/plugins/ /kong-plugins/kong/

# Remove git and other unneeded dependencies
RUN apt-get purge --auto-remove git -y && apt purge `dpkg --list | grep ^rc | awk '{ print $2; }'`

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

CMD ["kong", "docker-start"]
