# docker-tinyproxy
http(s) forward proxy in stealth mode as docker container

logs errors to stdout

run: `docker run -it --rm -p8080:8080 ghcr.io/knrdl/docker-tinyproxy`

test: `http_proxy=localhost:8080 curl example.org`