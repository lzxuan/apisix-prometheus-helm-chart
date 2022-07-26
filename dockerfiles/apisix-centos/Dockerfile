ARG APISIX_BASE_IMAGE_TAG="2.14.1-centos"

FROM apache/apisix:$APISIX_BASE_IMAGE_TAG

ARG APISIX_LIBMAXMINDDB_VERSION="1.6.0"
ARG APISIX_GEOIPUPDATE_VERSION="4.9.0"
ARG APISIX_GEOIPUPDATE_ACCOUNT_ID=""
ARG APISIX_GEOIPUPDATE_LICENSE_KEY=""
ARG APISIX_GEOIPUPDATE_EDITION_IDS="GeoLite2-Country"
ARG APISIX_LUAROCKS_VERSION="3.9.1"

RUN yum -y install gcc make unzip \
    # https://github.com/maxmind/libmaxminddb
    && cd /tmp \
    && curl -fSL "https://github.com/maxmind/libmaxminddb/releases/download/${APISIX_LIBMAXMINDDB_VERSION}/libmaxminddb-${APISIX_LIBMAXMINDDB_VERSION}.tar.gz" \
        -o libmaxminddb-${APISIX_LIBMAXMINDDB_VERSION}.tar.gz \
    && tar -xzf libmaxminddb-${APISIX_LIBMAXMINDDB_VERSION}.tar.gz \
    && cd /tmp/libmaxminddb-${APISIX_LIBMAXMINDDB_VERSION} \
    && ./configure \
    && make \
    && make install \
    && rm -rf /tmp/libmaxminddb-${APISIX_LIBMAXMINDDB_VERSION}* \
    # https://github.com/maxmind/geoipupdate
    && cd /tmp \
    && curl -fSL "https://github.com/maxmind/geoipupdate/releases/download/v${APISIX_GEOIPUPDATE_VERSION}/geoipupdate_${APISIX_GEOIPUPDATE_VERSION}_linux_amd64.tar.gz" \
        -o geoipupdate_${APISIX_GEOIPUPDATE_VERSION}_linux_amd64.tar.gz \
    && tar -xzf geoipupdate_${APISIX_GEOIPUPDATE_VERSION}_linux_amd64.tar.gz \
    && mv /tmp/geoipupdate_${APISIX_GEOIPUPDATE_VERSION}_linux_amd64/geoipupdate /usr/local/bin/ \
    && mkdir -p /usr/local/etc \
    && echo -e "AccountID ${APISIX_GEOIPUPDATE_ACCOUNT_ID}\n\
LicenseKey ${APISIX_GEOIPUPDATE_LICENSE_KEY}\n\
EditionIDs ${APISIX_GEOIPUPDATE_EDITION_IDS}\n" > /usr/local/etc/GeoIP.conf \
    && mkdir -p /usr/local/share/GeoIP \
    && chown nobody:nobody /usr/local/share/GeoIP \
    && su -s /bin/sh -c '/usr/local/bin/geoipupdate -v' nobody \
    && rm -rf /tmp/geoipupdate_${APISIX_GEOIPUPDATE_VERSION}* \
    # https://openresty.org/en/using-luarocks.html
    && cd /tmp \
    && curl -fSL "https://luarocks.github.io/luarocks/releases/luarocks-${APISIX_LUAROCKS_VERSION}.tar.gz" \
        -o luarocks-${APISIX_LUAROCKS_VERSION}.tar.gz \
    && tar -xzf luarocks-${APISIX_LUAROCKS_VERSION}.tar.gz \
    && cd /tmp/luarocks-${APISIX_LUAROCKS_VERSION} \
    && ls -al \
    && ./configure --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit/ \
        --lua-suffix=jit \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make \
    && make install \
    && rm -rf /tmp/luarocks-${APISIX_LUAROCKS_VERSION} \
    # https://github.com/leafo/luajit-geoip
    && cd /tmp \
    && /usr/local/openresty/luajit/bin/luarocks install luajit-geoip --tree=/usr/local/apisix/deps \
    # Cleanup
    && yum -y remove gcc make unzip \
    && yum -y autoremove
