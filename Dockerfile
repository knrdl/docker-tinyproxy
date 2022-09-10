FROM alpine

EXPOSE 8080/tcp

RUN apk update && \
    apk add tinyproxy

COPY tinyproxy.conf /tinyproxy.conf

USER tinyproxy

CMD tinyproxy -d -c /tinyproxy.conf