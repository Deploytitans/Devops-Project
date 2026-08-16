#!/usr/bin/env bash
set -Eeuo pipefail

: "${AWS_REGION:?AWS_REGION is required}"
: "${EKS_CLUSTER_NAME:?EKS_CLUSTER_NAME is required}"
: "${ECR_REPOSITORY:?ECR_REPOSITORY is required}"
: "${IMAGE_TAG:?IMAGE_TAG is required}"
: "${WAF_ACL_ARN:?WAF_ACL_ARN is required}"
: "${ACM_CERTIFICATE_ARN:?ACM_CERTIFICATE_ARN is required}"
: "${ALB_CONTROLLER_ROLE_ARN:?ALB_CONTROLLER_ROLE_ARN is required}"
: "${CLUSTER_AUTOSCALER_ROLE_ARN:?CLUSTER_AUTOSCALER_ROLE_ARN is required}"

namespace="astronomy-shop"
chart_version="0.40.9"
rendered_values="$(mktemp)"
rendered_ingress="$(mktemp)"
trap 'rm -f "${rendered_values}" "${rendered_ingress}"' EXIT

aws eks update-kubeconfig --region "${AWS_REGION}" --name "${EKS_CLUSTER_NAME}"
kubectl apply -f deploy/kubernetes/namespace.yaml

helm repo add eks https://aws.github.io/eks-charts --force-update
helm repo add autoscaler https://kubernetes.github.io/autoscaler --force-update
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName="${EKS_CLUSTER_NAME}" \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations.eks\.amazonaws\.com/role-arn="${ALB_CONTROLLER_ROLE_ARN}" \
  --wait --atomic --timeout 10m

helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName="${EKS_CLUSTER_NAME}" \
  --set awsRegion="${AWS_REGION}" \
  --set rbac.serviceAccount.create=true \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set rbac.serviceAccount.annotations.eks\.amazonaws\.com/role-arn="${CLUSTER_AUTOSCALER_ROLE_ARN}" \
  --set extraArgs.balance-similar-node-groups=true \
  --set extraArgs.skip-nodes-with-system-pods=false \
  --wait --atomic --timeout 10m

export IMAGE_REPOSITORY="${ECR_REPOSITORY}"
export IMAGE_TAG
envsubst '${IMAGE_REPOSITORY} ${IMAGE_TAG}' \
  < deploy/helm/values-production.yaml > "${rendered_values}"

helm upgrade --install astronomy-shop open-telemetry/opentelemetry-demo \
  --version "${chart_version}" \
  --namespace "${namespace}" \
  --values "${rendered_values}" \
  --atomic --wait --timeout 20m

export WAF_ACL_ARN ACM_CERTIFICATE_ARN
envsubst '${WAF_ACL_ARN} ${ACM_CERTIFICATE_ARN}' \
  < deploy/kubernetes/ingress.yaml > "${rendered_ingress}"
kubectl apply --namespace "${namespace}" -f "${rendered_ingress}"
kubectl apply --namespace "${namespace}" -f deploy/kubernetes/policies.yaml
kubectl apply --namespace "${namespace}" -f deploy/kubernetes/autoscaling.yaml

bash scripts/verify-deployment.sh "${namespace}"
