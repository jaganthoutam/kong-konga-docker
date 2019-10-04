FROM kong:1.3.0-ubuntu

MAINTAINER Alberto C. <ac@mail.com>
LABEL Description="Kong docker image with header-checker and request-throttling plugins"

# Install Git to clone the plugins GitHub repos
RUN apt-get update && apt-get install git -y

# Create directory for custom plugins and clone them
RUN mkdir -p /plugins && \
    git clone https://github.com/millenc/kong-plugin-request-throttling.git && \
    mv kong-plugin-request-throttling/kong /plugins/ && \
    mv  /plugins/kong/plugins/request-throttling /plugins/kong/plugins/requestthrottling && \
    rm -r kong-plugin-request-throttling && \
    git clone https://github.com/albertocr/kong-plugin-header-checker.git /plugins/kong/plugins/headerchecker

# Remove git and other unneeded dependencies
RUN apt-get purge --auto-remove git -y && apt purge `dpkg --list | grep ^rc | awk '{ print $2; }'`

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

CMD ["kong", "docker-start"]
