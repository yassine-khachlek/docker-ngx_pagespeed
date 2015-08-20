FROM centos:7

MAINTAINER Yassine Khachlek "yassine.khachlek@gmail.com"

RUN yum install -y \
    wget \
    gcc-c++ \
    pcre-devel \
    zlib-devel \
    make \
    unzip \
    openssl-devel \
    openssl \
    && cd /tmp \
    && NPS_VERSION=1.9.32.6 \
    && NGINX_VERSION=1.8.0 \
    && wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip \
    && unzip release-${NPS_VERSION}-beta.zip \
    && cd ngx_pagespeed-release-${NPS_VERSION}-beta/ \
    && wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz \
    && tar -xzvf ${NPS_VERSION}.tar.gz \
    && cd /tmp \
    && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -xvzf nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION}/ \
    #&& useradd -r nginx \
    && ./configure \
    #--user=nginx                          \
    #--group=nginx                         \
    #--prefix=/etc/nginx                   \
    #--sbin-path=/usr/sbin/nginx           \
    #--conf-path=/etc/nginx/nginx.conf     \
    #--pid-path=/var/run/nginx.pid         \
    #--lock-path=/var/run/nginx.lock       \
    #--error-log-path=/var/log/nginx/error.log \
    #--http-log-path=/var/log/nginx/access.log \    
    --add-module=/tmp/ngx_pagespeed-release-${NPS_VERSION}-beta \
    --with-http_gzip_static_module        \
    --with-http_stub_status_module        \
    --with-http_ssl_module                \
    --with-pcre                           \
    --with-file-aio                       \
    --with-http_realip_module             \
    --without-http_scgi_module            \
    --without-http_uwsgi_module           \
    --without-http_fastcgi_module \
    && make \
    && make install \
    && cd /usr/local/nginx/conf/ \
    && openssl genrsa -passout pass:pass_phrase -des3 -out cert.key 2048 \
    && openssl req -new -key cert.key -sha256 -nodes \
	-subj '/C=TN/ST=State or Province Name (full name)/L=Locality Name (eg, city) \
	/O=Organization Name (eg, company) \
	/OU=Organizational Unit Name (eg, section) \
	/CN=Common Name (e.g. cert FQDN or YOUR name) \
	/emailAddress=email_address@FQDN \
	/subjectAltName=DNS.1=FQDN, DNS.2=subdomain.FQDN, DNS.3=subdomain.FQDN' \
	-out cert.csr -passin pass:pass_phrase \
    && cp cert.key cert.key.with_pass_phrase \
    && openssl rsa -passin pass:pass_phrase -in cert.key.with_pass_phrase -out cert.key \
    && openssl x509 -req -days 365 -in cert.csr -signkey cert.key -out cert.crt \
    && rm -frdv /tmp/* \
    && yum clean all

COPY ./nginx.conf /usr/local/nginx/conf/nginx.conf

ENV PATH /usr/local/nginx/sbin/:$PATH

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /usr/local/nginx/logs/access.log
RUN ln -sf /dev/stderr /usr/local/nginx/logs/error.log

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]

