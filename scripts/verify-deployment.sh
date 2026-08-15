#!/usr/bin/env bash
set -Eeuo pipefail

namespace="${1:-astronomy-shop}"

kubectl wait --namespace "${namespace}" \
  --for=condition=Available deployment \
  --selector=app.kubernetes.io/part-of=opentelemetry-demo \
  --timeout=10m

kubectl get pods --namespace "${namespace}" --field-selector=status.phase=Failed -o name | \
  grep -q . && {
    echo "Failed pods were found in ${namespace}." >&2
    kubectl get pods --namespace "${namespace}" --field-selector=status.phase=Failed
    exit 1
  }

ingress_host="$(kubectl get ingress --namespace "${namespace}" \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')"

if [[ -z "${ingress_host}" ]]; then
  echo "The application ingress does not have an ALB hostname." >&2
  exit 1
fi

for attempt in $(seq 1 60); do
  if curl --fail --silent --show-error --max-time 10 "http://${ingress_host}/" >/dev/null; then
    echo "Deployment verified at http://${ingress_host}/"
    exit 0
  fi
  echo "Waiting for ALB health (${attempt}/60)..."
  sleep 10
done

echo "Application health verification timed out." >&2
exit 1
