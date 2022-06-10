ARG APISIX_DASHBOARD_BASE_IMAGE_TAG="2.13-alpine"

FROM apache/apisix-dashboard:$APISIX_DASHBOARD_BASE_IMAGE_TAG

COPY extra-plugins.json /tmp/extra-plugins.json

RUN apk add --no-cache --virtual .builddeps jq \
    && jq -s '.[0] * .[1]' /usr/local/apisix-dashboard/conf/schema.json /tmp/extra-plugins.json > /tmp/schema.json \
    && mv /tmp/schema.json /usr/local/apisix-dashboard/conf/schema.json \
    && apk del --no-cache .builddeps \
    && sed -i 's/redirect:{type:l.other,hidden:!0}/redirect:{type:l.other},maxminddb:{type:l.other,hidden:!0}/' /usr/local/apisix-dashboard/html/p__Plugin__*.*.async.js
