# docker-tinyproxy
http(s) forward proxy in stealth (transparent) mode as docker container

logs errors to stdout

## Run
cli: `docker run -it --rm -p8118:8080 ghcr.io/knrdl/docker-tinyproxy:edge`

docker-compose:
```yaml
version: '3'

services:
  tinyproxy:
    image: ghcr.io/knrdl/docker-tinyproxy:edge
    restart: unless-stopped
    mem_limit: 150m
    ports:
      - 192.168.123.2:8118:8080  # 192.168.123.2 is the ip addr of the host (optional)
    networks:
      - restricted

networks:
  restricted:
    attachable: false
    driver_opts:
      com.docker.network.bridge.name: fwdproxy
```

## Test

`http_proxy=192.168.123.2:8118 https_proxy=192.168.123.2:8118 curl -L -k example.org`

192.168.123.2 is the ip addr of the host running tinyproxy


## Restrict access to local network

The tinyproxy container can access resources on the internet but also *local machines*. This might be a security problem which can be fixed with `iptables`:

1. test rules:
```shell
# prevent access to machines in local network 
sudo iptables -I DOCKER-USER -m iprange --in-interface fwdproxy --dst-range 192.168.123.2-192.168.123.255 -j REJECT
# if 192.168.42.1 is the default gateway it cannot be blocked completely, but at least access to the admin webui can be blocked
sudo iptables -I DOCKER-USER -p tcp --in-interface fwdproxy -d 192.168.42.1 --dport 1:1024  -j REJECT
```
Network interface name "fwdproxy" has been defined in docker compose snippet above.

2. persist rules
```shell
sudo apt install  iptables-persistent
sudo netfilter-persistent save
```

3. cleanup persisted rules

edit `/etc/iptables/rules.v4` and keep:
```
*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
:DOCKER - [0:0]
:DOCKER-ISOLATION-STAGE-1 - [0:0]
:DOCKER-ISOLATION-STAGE-2 - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -d 192.168.123.1/32 -i fwdproxy -p tcp -m tcp --dport 1:1024 -j REJECT --reject-with icmp-port-unreachable
-A DOCKER-USER -i fwdproxy -m iprange --dst-range 192.168.123.2-192.168.123.255 -j REJECT --reject-with icmp-port-unreachable
COMMIT

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:DOCKER - [0:0]
COMMIT
```

edit `/etc/iptables/rules.v6` and keep:
```
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
```

test rules work: `sudo netfilter-persistent reload`

4. reboot

5. test

`sudo iptables -S | grep fwdproxy`
