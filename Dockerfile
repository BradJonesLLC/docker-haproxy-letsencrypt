FROM haproxy:1.6

RUN apt-get update && apt-get install -yqq --no-install-recommends \
  cron \
  wget \
  ca-certificates \
  && apt-get clean autoclean && apt-get autoremove -y

# See https://github.com/janeczku/haproxy-acme-validation-plugin
COPY haproxy-acme-validation-plugin/acme-http01-webroot.lua /usr/local/etc/haproxy
COPY haproxy-acme-validation-plugin/cert-renewal-haproxy.sh /

RUN wget https://dl.eff.org/certbot-auto \
    && chmod a+x certbot-auto \
    && mv certbot-auto /usr/local/bin/letsencrypt-auto

COPY crontab.txt /var/crontab.txt
RUN crontab /var/crontab.txt && chmod 600 /etc/crontab

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY certs.sh /

RUN mkdir /jail

EXPOSE 80 443

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

ENTRYPOINT ["/usr/bin/supervisord"]
CMD [""]
