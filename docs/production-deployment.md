# Production deployment on Amazon EKS

This repository uses Amazon EKS because the application consists of many
independently scalable services with mixed HTTP, gRPC, Kafka, Valkey, and
OpenTelemetry traffic. ECS is viable, but EKS lets the existing service model,
health semantics, and OpenTelemetry deployment remain consistent while adding
pod- and node-level autoscaling.

## Architecture

Traffic enters an internet-facing Application Load Balancer, is filtered by
AWS WAF, and reaches only `frontend-proxy`. Application pods run on private
subnets across three Availability Zones. ECR stores immutable, scan-on-push
images. The OpenTelemetry Collector receives application telemetry; Prometheus,
Grafana, and Jaeger provide metrics, dashboards, and traces. Kafka, Valkey, and
PostgreSQL are deployed by the pinned demo chart for this educational project.
For a business-critical deployment, replace them with Amazon MSK,
ElastiCache/MemoryDB, and RDS/Aurora before accepting customer data.

The platform has two autoscaling layers:

1. Horizontal Pod Autoscalers scale stateless services from resource metrics.
2. Cluster Autoscaler changes the EKS managed node group from 2 to 8 nodes when
   pods cannot be scheduled or capacity is no longer required.

## Prerequisites and cost warning

The stack creates billable resources, including three NAT gateways, EKS,
multiple EC2 nodes, ALB, EBS volumes, WAF, GuardDuty, and CloudTrail storage.
Use an AWS sandbox account and review `terraform plan` before applying.

Install AWS CLI v2, Terraform 1.8+, kubectl, and Helm 3. Configure an S3 bucket
for Terraform state before initialization. The state bucket is intentionally
outside this stack so `terraform destroy` cannot delete the state it needs.
Because the EKS API is not exposed to the changing GitHub-hosted runner address
ranges, register an ephemeral GitHub Actions runner in the VPC with the labels
`self-hosted`, `linux`, and `production-vpc`. Only the deploy job uses it; builds
remain isolated on GitHub-hosted runners.

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
terraform init \
  -backend-config="bucket=YOUR_TERRAFORM_STATE_BUCKET" \
  -backend-config="key=astronomy-shop/production.tfstate" \
  -backend-config="region=ap-south-1" \
  -backend-config="use_lockfile=true" \
  -backend-config="encrypt=true"
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

The EKS API endpoint is private-only. Run Terraform, `kubectl`, and the
production deployment job from a host with network access to the VPC, such as
the documented `production-vpc` self-hosted runner or a VPN-connected admin
workstation.

## GitHub environment configuration

Create a protected GitHub environment named `production`. Add required
reviewers and these repository/environment variables from Terraform outputs:

| Variable | Source |
|---|---|
| `AWS_REGION` | `aws_region` |
| `AWS_DEPLOY_ROLE_ARN` | `github_actions_role_arn` |
| `EKS_CLUSTER_NAME` | `cluster_name` |
| `ECR_REPOSITORY_URL` | `ecr_repository_url` |
| `WAF_ACL_ARN` | `waf_web_acl_arn` |
| `ACM_CERTIFICATE_ARN` | An ACM certificate in the deployment region |
| `ALB_CONTROLLER_ROLE_ARN` | `load_balancer_controller_role_arn` |
| `CLUSTER_AUTOSCALER_ROLE_ARN` | `cluster_autoscaler_role_arn` |

No long-lived AWS key is stored in GitHub. GitHub Actions obtains short-lived
credentials through OIDC, and the trust policy is scoped to one repository.
Create an alias/AAAA record for the application hostname pointing to the ALB;
the ingress redirects HTTP to HTTPS and uses the supplied ACM certificate.

## Delivery flow

Pull requests run native unit/build checks, IaC/secret/dependency scanning, and
BuildKit builds for every repository image. A merge to `main` builds SBOM and
provenance attestations, pushes immutable images to ECR, deploys the pinned Helm
chart atomically, applies policies/HPAs, waits for every application deployment,
and checks the public ALB endpoint. A failed Helm rollout automatically returns
to the prior revision because deployment uses `--atomic`.

To inspect or roll back manually:

```bash
aws eks update-kubeconfig --region ap-south-1 --name astronomy-shop-production
helm history astronomy-shop -n astronomy-shop
helm rollback astronomy-shop PREVIOUS_REVISION -n astronomy-shop --wait
kubectl get pods,hpa,ingress -n astronomy-shop
```

## Monitoring and alerting

- Grafana dashboards correlate service metrics with Jaeger traces through the
  OpenTelemetry Collector.
- Prometheus retains 15 days of metrics on encrypted EBS-backed volumes.
- EKS control-plane API, audit, authenticator, controller-manager, and scheduler
  logs are retained in CloudWatch for 90 days.
- VPC Flow Logs record network metadata.
- Resource requests are mandatory for HPA signal quality and safe scheduling.

For unattended production operations, add CloudWatch alarms for ALB 5xx/latency,
unhealthy targets, node pressure, HPA saturation, and collector export failures,
then route them to the on-call system rather than email alone.

## Security controls

- Containers run as non-root where supported; pod security contexts drop Linux
  capabilities, prohibit privilege escalation, and use RuntimeDefault seccomp.
- Pod Security Admission audits the restricted profile and enforces baseline.
- NetworkPolicies isolate the namespace and expose only the proxy port to ALB.
- ECR images are immutable, encrypted, scanned, and expired after 100 releases.
- AWS WAF applies managed common/known-bad rules and per-IP rate limiting.
- CloudTrail records validated multi-region management events for seven years.
- GuardDuty analyzes EKS audit activity and enables EKS runtime monitoring.
- Security Hub aggregates controls; GuardDuty and Security Hub findings are
  delivered through EventBridge to the encrypted SNS topic.
- EKS workers require IMDSv2 with a hop limit of one; workload AWS access uses
  dedicated service-account roles rather than node credentials.

AWS Security Hub and GuardDuty are account/organization-level services. If they
are already delegated to an AWS Organizations administrator, import or remove
those Terraform resources rather than enabling duplicate account resources.

## Teardown

The ALB has deletion protection enabled. Before destroying the lab, set
`deletion_protection.enabled=false` in `values-production.yaml`, deploy once,
then uninstall the release and destroy infrastructure:

```bash
helm uninstall astronomy-shop -n astronomy-shop
terraform -chdir=infra/terraform destroy
```

CloudTrail storage and ECR intentionally use deletion protection semantics.
Archive or explicitly remove retained data only after confirming it is no longer
required by audit or incident-response policy.
