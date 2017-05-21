# Much of this stolen from haproxy:1.6 dockerfile, with Lua support
FROM debian:jessie

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie.backports.list

ENV SUPERVISOR_VERSION 3.3.0

RUN buildDeps='curl gcc libc6-dev libpcre3-dev libssl-dev make libreadline-dev' \
    && set -x \
    && apt-get update && apt-get install --no-install-recommends -yqq $buildDeps \
    cron \
    wget \
    ca-certificates \
    curl \
    patch \
    python-setuptools \
    dnsmasq \
    libssl1.0.0 libpcre3 \
    python-ndg-httpsclient \
    && apt-get install --no-install-recommends -yqq certbot -t jessie-backports \
    && wget https://github.com/Supervisor/supervisor/archive/${SUPERVISOR_VERSION}.tar.gz \
    && tar -xvf ${SUPERVISOR_VERSION}.tar.gz \
    && cd supervisor-${SUPERVISOR_VERSION} && python setup.py install \
    && apt-get clean autoclean && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

ENV LUA_VERSION 5.3.0
ENV LUA_VERSION_SHORT 53

RUN cd /usr/src \
    && curl -R -O http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz \
    && tar zxf lua-${LUA_VERSION}.tar.gz \
    && rm lua-${LUA_VERSION}.tar.gz \
    && cd lua-${LUA_VERSION} \
    && make linux \
    && make INSTALL_TOP=/opt/lua${LUA_VERSION_SHORT} install

ENV HAPROXY_MAJOR 1.7
ENV HAPROXY_VERSION 1.7.2
ENV HAPROXY_MD5 7330b36f3764ebe409e9305803dc30e2


RUN cd / && curl -SL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" -o haproxy.tar.gz \
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
	&& rm -rf /usr/src/haproxy

COPY docker-entrypoint.sh /

# See https://github.com/janeczku/haproxy-acme-validation-plugin
COPY haproxy-acme-validation-plugin/acme-http01-webroot.lua /usr/local/etc/haproxy
COPY haproxy-acme-validation-plugin/cert-renewal-haproxy.sh /

COPY crontab.txt /var/crontab.txt
RUN crontab /var/crontab.txt && chmod 600 /etc/crontab

COPY supervisord.conf /etc/supervisord.conf
COPY certs.sh /
COPY bootstrap.sh /

RUN mkdir /jail

EXPOSE 80 443

VOLUME /etc/letsencrypt

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

ENTRYPOINT ["/bootstrap.sh"]
