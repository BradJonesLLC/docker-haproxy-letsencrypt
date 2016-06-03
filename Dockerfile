# Much of this stolen from haproxy:1.6 dockerfile, with Lua support
FROM debian:jessie

RUN buildDeps='curl gcc libc6-dev libpcre3-dev libssl-dev make libreadline-dev' \
    && set -x \
    && apt-get update && apt-get install --no-install-recommends -y $buildDeps \
    cron \
    wget \
    ca-certificates \
    supervisor \
    curl \
    libssl1.0.0 libpcre3 \
    && wget https://dl.eff.org/certbot-auto \
    && chmod a+x certbot-auto \
    && mv certbot-auto /usr/local/bin/letsencrypt-auto \
    && letsencrypt-auto --os-packages-only \
    && apt-get clean autoclean && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN cd /usr/src \
    && curl -R -O http://www.lua.org/ftp/lua-5.3.0.tar.gz \
    && tar zxf lua-5.3.0.tar.gz \
    && cd lua-5.3.0 \
    && make linux \
    && make INSTALL_TOP=/opt/lua53 install \
    && cd /

ENV HAPROXY_MAJOR 1.6
ENV HAPROXY_VERSION 1.6.5
ENV HAPROXY_MD5 5290f278c04e682e42ab71fed26fc082

# see http://sources.debian.net/src/haproxy/1.5.8-1/debian/rules/ for some helpful navigation of the possible "make" arguments
RUN curl -SL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" -o haproxy.tar.gz \
	&& echo "${HAPROXY_MD5}  haproxy.tar.gz" | md5sum -c \
	&& mkdir -p /usr/src/haproxy \
	&& tar -xzf haproxy.tar.gz -C /usr/src/haproxy --strip-components=1 \
	&& rm haproxy.tar.gz \
	&& make -C /usr/src/haproxy \
		TARGET=linux2628 \
		USE_PCRE=1 PCREDIR= \
		USE_OPENSSL=1 \
		USE_ZLIB=1 \
		USE_LUA=yes LUA_LIB=/opt/lua53/lib/ \
        LUA_INC=/opt/lua53/include/ LDFLAGS=-ldl \
		all \
		install-bin \
	&& mkdir -p /usr/local/etc/haproxy \
	&& cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors \
	&& rm -rf /usr/src/haproxy \
	&& apt-get purge -y --auto-remove $buildDeps

COPY docker-entrypoint.sh /

# See https://github.com/janeczku/haproxy-acme-validation-plugin
COPY haproxy-acme-validation-plugin/acme-http01-webroot.lua /usr/local/etc/haproxy
COPY haproxy-acme-validation-plugin/cert-renewal-haproxy.sh /

COPY crontab.txt /var/crontab.txt
RUN crontab /var/crontab.txt && chmod 600 /etc/crontab

COPY supervisord.conf /etc/supervisor/conf.d
COPY certs.sh /

RUN mkdir /jail

EXPOSE 80 443

VOLUME /etc/letsencrypt

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

ENTRYPOINT ["/usr/bin/supervisord"]
