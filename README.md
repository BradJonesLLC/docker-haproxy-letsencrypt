# Dockerized HAProxy with Let's Encrypt

This container provides a HAProxy 1.6 application with Let's Encrypt certificates
generated at startup, as well as renewed (if necessary) once a week.

## Usage

```
docker run \
    -e CERTS=my.domain,my.other.domain \
    -e EMAIL=my.email@my.domain \
    -v /etc/letsencrypt:/etc/letsencrypt \
    -p 80:90 -p 443:443 \
    bradjonesllc/docker-haproxy-letsencrypt
```

You will almost certainly want to create an image `FROM` this image or
mount your `haproxy.cfg` at `/usr/local/etc/haproxy/haproxy.cfg`.

### License and Copyright

&copy; Brad Jones LLC, Licensed under GPL-2. Some components MIT license.
