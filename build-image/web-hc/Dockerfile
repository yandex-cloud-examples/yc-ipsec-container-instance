ARG ALPINE_VER

FROM alpine:${ALPINE_VER:-3.21.3}

RUN set +x \
    && apk add --no-cache nginx \
    && mkdir -p /var/log/nginx \
    && ln -s /dev/stdout /var/log/nginx/access.log \
    && ln -s /dev/stderr /var/log/nginx/error.log \
    && :

COPY ./files/nginx.conf /etc/nginx/nginx.conf

EXPOSE 8000

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
