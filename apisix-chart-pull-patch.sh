#!/usr/bin/env bash

set -euo pipefail

APISIX_HELM_CHART_BRANCH="${1:-apisix-0.10.0}"

RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'
echo_error() { >&2 echo -e "${RED}$@${NC}"; }
echo_success() { echo -e "${GREEN}$@${NC}"; }
echo_info() { echo -e "${BLUE}$@${NC}"; }
echo_warning() { echo -e "${YELLOW}$@${NC}"; }

if [ ! -d ./chart/charts/apisix ]
then
  echo_error '[ERROR] Ensure that you have cd-ed into the root of this repo before running this script.'
  exit 1
fi

tmp_apisix_chart_dir="/tmp/apisix-helm-chart-$(date +%s)"
rm -rf "$tmp_apisix_chart_dir"

cleanup() {
  rm -rf "$tmp_apisix_chart_dir"
  echo_warning "[CLEANUP] Temporary directory removed: $tmp_apisix_chart_dir."
}

trap 'cleanup' ERR

git clone --branch "$APISIX_HELM_CHART_BRANCH" --depth 1 https://github.com/apache/apisix-helm-chart.git "$tmp_apisix_chart_dir"


# PATCH 1
apisix_version=$(cat "$tmp_apisix_chart_dir/charts/apisix/Chart.yaml" | sed -n 's/^appVersion: \(.*\)$/\1/p')
file="$tmp_apisix_chart_dir/init.lua"
wget "https://raw.githubusercontent.com/apache/apisix/$apisix_version/apisix/discovery/kubernetes/init.lua" -O "$file"
patch "$file" ./patches/init.lua.patch
cp "$file" ./chart/apisix-discovery-kubernetes/init.lua
echo_info '[INFO] apisix: discovery.kubernetes.init patched for auto-updating upstreams in etcd.'


# PATCH 2
file="$tmp_apisix_chart_dir/charts/apisix/templates/daemonset.yaml"
if cat "$file" | grep -q 'serviceAccountName:'
then
  echo_error "[ERROR] DaemonSet of APISIX Helm chart has already included serviceAccountName."
else
  patch='
      ### PATCH START ###
      # Added for APISIX Kubernetes service discovery.
      serviceAccountName: {{ .Values.serviceAccountName }}
      #### PATCH END ####
'
  echo "$patch" | sed -i '/^    spec:/r /dev/stdin' "$file"
fi
echo_info '[INFO] apisix subchart: DaemonSet patched for adding serviceAccountName.'


# PATCH 3
file="$tmp_apisix_chart_dir/charts/apisix/templates/deployment.yaml"
if cat "$file" | grep -q 'serviceAccountName:'
then
  echo_error "[ERROR] Deployment of APISIX Helm chart has already included serviceAccountName."
else
  patch='
      ### PATCH START ###
      # Added for APISIX Kubernetes service discovery.
      serviceAccountName: {{ .Values.serviceAccountName }}
      #### PATCH END ####
'
  echo "$patch" | sed -i '/^    spec:/r /dev/stdin' "$file"
fi
echo_info '[INFO] apisix subchart: Deployment patched for adding serviceAccountName.'


# PATCH 4
file="$tmp_apisix_chart_dir/charts/apisix/templates/configmap.yaml"
if cat "$file" | grep -q 'worker_processes:'
then
  echo_error "[ERROR] nginx_config in ConfigMap of APISIX Helm chart has already included worker_processes."
else
  patch='
      {{- if .Values.apisix.workerProcesses }}
      ### PATCH START ###
      worker_processes: {{ .Values.apisix.workerProcesses }}
      #### PATCH END ####
      {{- end }}
'
  echo "$patch" | sed -i '/^    nginx_config:/r /dev/stdin' "$file"
fi
echo_info '[INFO] apisix subchart: ConfigMap patched for adding worker_processes.'


cp -R "$tmp_apisix_chart_dir/charts/apisix/"* ./chart/charts/apisix

echo_success '[SUCCESS] All patches applied successfully.'

cleanup
