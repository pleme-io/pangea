# Pangea Kubernetes Integration

**Pattern:** Pangea manages AWS resources, Kubernetes uses them via annotations.

## cert-manager Route53 Integration

### Pangea IAM Template

```ruby
# cert_manager_route53.rb
template :cert_manager_iam do
  config = {
    region: "us-east-1",
    cluster_name: "orion",
    oidc_issuer: "oidc.eks.us-east-1.amazonaws.com/id/XXXX"
  }

  provider :aws do
    region config[:region]
  end

  # IAM role for cert-manager DNS-01 challenges
  resource :aws_iam_role, :cert_manager do
    name "cert-manager-route53"

    assume_role_policy {
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Principal: {
          Federated: "arn:aws:iam::ACCOUNT:oidc-provider/#{config[:oidc_issuer]}"
        },
        Action: "sts:AssumeRoleWithWebIdentity",
        Condition: {
          StringEquals: {
            "#{config[:oidc_issuer]}:sub": "system:serviceaccount:cert-manager:cert-manager"
          }
        }
      }]
    }.to_json
  end

  resource :aws_iam_policy, :route53_access do
    name "cert-manager-route53-access"

    policy {
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Action: [
          "route53:GetChange",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ],
        Resource: [
          "arn:aws:route53:::hostedzone/*",
          "arn:aws:route53:::change/*"
        ]
      }, {
        Effect: "Allow",
        Action: "route53:ListHostedZonesByName",
        Resource: "*"
      }]
    }.to_json
  end

  resource :aws_iam_role_policy_attachment, :cert_manager do
    role "${aws_iam_role.cert_manager.name}"
    policy_arn "${aws_iam_policy.route53_access.arn}"
  end
end
```

### Kubernetes ClusterIssuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - dns01:
        route53:
          region: us-east-1
          # IAM role created by Pangea
          # Uses IRSA (IAM Roles for Service Accounts)
```

## External DNS Integration

### Pangea IAM Template

```ruby
template :external_dns_iam do
  resource :aws_iam_role, :external_dns do
    name "external-dns-route53"
    # Similar IRSA pattern as cert-manager
  end

  resource :aws_iam_policy, :external_dns do
    name "external-dns-route53-access"

    policy {
      Version: "2012-10-17",
      Statement: [{
        Effect: "Allow",
        Action: [
          "route53:ChangeResourceRecordSets"
        ],
        Resource: "arn:aws:route53:::hostedzone/*"
      }, {
        Effect: "Allow",
        Action: [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        Resource: "*"
      }]
    }.to_json
  end
end
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
spec:
  template:
    metadata:
      annotations:
        # IAM role ARN from Pangea
        eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/external-dns-route53
```

## Pattern Summary

1. **Pangea creates:** IAM roles, policies, trust relationships
2. **Kubernetes uses:** IRSA annotations referencing Pangea-managed roles
3. **Benefit:** Infrastructure as code for both AWS and K8s resources
