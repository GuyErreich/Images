ARG OPENRESTY_INSTALL_FOLDER='/usr/local/openresty'
ARG ALPINE_VERSION=3.21.3

# Build OpenResty with ngx_http_proxy_connect_module
FROM alpine:${ALPINE_VERSION} AS builder

ARG NGINX_VERSION=1.25.3
ARG OPENRESTY_VERSION=${NGINX_VERSION}.2
ARG MODULE_PATCH=102101
ARG OPENRESTY_INSTALL_FOLDER
ENV OPENRESTY_INSTALL_FOLDER=${OPENRESTY_INSTALL_FOLDER}

# Prevent silent failures in pipes
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

RUN apk add --no-cache \
    build-base \
    pcre-dev \
    zlib-dev \
    openssl-dev \
    linux-headers \
    perl \
    git \
    curl \
    wget

WORKDIR /app

# Download OpenResty source
RUN wget --progress=dot:giga https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz && \
    tar -xvzf openresty-${OPENRESTY_VERSION}.tar.gz

# Clone the proxy_connect module
RUN git clone --depth=1 https://github.com/chobits/ngx_http_proxy_connect_module.git

# Compile OpenResty with the module
WORKDIR /app/openresty-${OPENRESTY_VERSION}

RUN ./configure \
    --prefix=${OPENRESTY_INSTALL_FOLDER} \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-stream \
    --with-threads \
    --with-file-aio \
    --with-http_stub_status_module \
    --with-pcre-jit \
    --with-luajit \
    --add-module=../ngx_http_proxy_connect_module && \
    patch -d build/nginx-${NGINX_VERSION} -p 1 < ../ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_${MODULE_PATCH}.patch && \
    make -j"$(nproc)" && make install

WORKDIR /app

# RUN rm -rf openresty-${OPENRESTY_VERSION} openresty-${OPENRESTY_VERSION}.tar.gz ngx_http_proxy_connect_module

RUN mkdir -p /opt/deps && \
    ldd ${OPENRESTY_INSTALL_FOLDER}/nginx/sbin/nginx | awk '{print $3}' | grep "^/" | xargs -I '{}' cp -v '{}' /opt/deps/

# RUN cp -r ${OPENRESTY_INSTALL_FOLDER}/luajit /opt/luajit

# Final lightweight Alpine image
FROM alpine:${ALPINE_VERSION}

ARG OPENRESTY_INSTALL_FOLDER
ENV OPENRESTY_INSTALL_FOLDER=${OPENRESTY_INSTALL_FOLDER}

# Prevent silent failures in pipes
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

RUN apk add --no-cache \
        ca-certificates \
        pcre \
        openssl \
        zlib \
        curl \
        python3 \
        py3-pip \
        py3-jinja2 \
    rm -rf /lib/apk/db /etc/apk /var/cache/apk/*
    
# Copy required shared libraries
COPY --from=builder ${OPENRESTY_INSTALL_FOLDER} /usr/local/openresty
# COPY --from=builder /opt/luajit /usr/local/openresty/luajit
COPY --from=builder /opt/deps/* /lib/

ENV PATH="/usr/local/openresty/bin:/usr/local/openresty/nginx/sbin:$PATH"
ENV LD_LIBRARY_PATH="/lib:/usr/local/openresty/luajit/lib"

WORKDIR /app

# Copy custom OpenResty configuration
COPY nginx.conf templates/nginx.conf
COPY entrypoint.py entrypoint.py

RUN chmod +x entrypoint.py

EXPOSE 3128

ENTRYPOINT  ["./entrypoint.py", "--template-dir", "templates", "--template-file", "nginx.conf", "--output-file", "/usr/local/openresty/nginx/conf/nginx.conf" ]
