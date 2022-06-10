# apisix-prometheus-helm-chart

A Helm chart for [Apache APISIX](https://github.com/apache/apisix-helm-chart/tree/master/charts/apisix) with [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack).

## Usage

1. Build custom `apisix` docker image.
   * Add [libmaxminddb](https://github.com/maxmind/libmaxminddb).
   * Add [geoipupdate](https://github.com/maxmind/geoipupdate).
   * Add [luajit-geoip](https://github.com/leafo/luajit-geoip).
   ```
   make docker-build-apisix APISIX_GEOIPUPDATE_ACCOUNT_ID='' APISIX_GEOIPUPDATE_LICENSE_KEY=''
   ```

2. Build custom `apisix-dashboard` docker image.
   * Modify schema.json for `maxminddb` & `ip-country-restriction` plugins.
   * Show `redirect` plugin in Global Plugin List.
   * Hide `maxminddb` plugin.
   ```
   make docker-build-apisix-dashboard
   ```

3. Pull and patch `apisix` helm chart.
   * Add `serviceAccountName` for Kubernetes service discovery.
   * Patch apisix/discovery/kubernetes/init.lua for auto-updating upstreams in etcd.
   ```
   ./apisix-chart-pull-patch.sh
   ```

4. Configure helm values (if any) and run helm install.
   ```
   helm install apisix ./chart
   ```
