# Pangea Resource Patterns

Detailed examples for common AWS resource patterns in Pangea Ruby DSL.

## Cloudflare Zero Trust Tunnel Configuration

**Pattern:** Array-based nested attributes require explicit parentheses

When configuring resources with nested array attributes (like `ingress` in `cloudflare_zero_trust_tunnel_cloudflared_config`), use explicit function call syntax with parentheses to ensure Pangea generates an array instead of nested blocks:

```ruby
# CORRECT: Array syntax with parentheses
resource :cloudflare_zero_trust_tunnel_cloudflared_config, :tunnel_config do
  account_id 'account-id'
  tunnel_id 'tunnel-id'

  config do
    # Use parentheses to pass array
    ingress([
      {
        hostname: '*.staging.example.com',
        service: 'http://192.168.50.100:80'
      },
      {
        hostname: 'staging.example.com',
        service: 'http://192.168.50.100:80'
      },
      {
        service: 'http_status:404'  # Catch-all (required)
      }
    ])
  end
end
```

```ruby
# INCORRECT: Block syntax generates single object instead of array
config do
  ingress_rule do
    hostname '*.staging.example.com'
    service 'http://192.168.50.100:80'
  end
  # This becomes: { ingress_rule: { hostname: ..., service: ... } }
  # API expects: { ingress: [{ hostname: ..., service: ... }] }
end
```

**Generated Terraform JSON (correct):**
```json
{
  "config": {
    "ingress": [
      {"hostname": "*.staging.example.com", "service": "http://192.168.50.100:80"},
      {"hostname": "staging.example.com", "service": "http://192.168.50.100:80"},
      {"service": "http_status:404"}
    ]
  }
}
```

**Key Points:**
- Cloudflare Tunnel `ingress` must be an array of rules
- Rules are evaluated in order - first match wins
- Catch-all rule (no hostname) must be last
- Routes traffic from Cloudflare edge to internal services (e.g., Istio Gateway)

## Route53 DNS Pattern

**Pattern:** Two templates - zones + records

```ruby
# {product}_dns.rb

template :route53_zones do
  config = {
    region: "us-east-1",
    primary_domain: "{product}.com"
  }

  provider :aws do
    region config[:region]
  end

  resource :aws_route53_zone, :primary do
    name config[:primary_domain]
    tags { ManagedBy "pangea" }
  end
end

template :dns_records do
  config = {
    zone_id: "Z01234567ABCDEFGHIJK",
    domain: "{product}.com",
    cloudfront_id: "E1234567890ABC",
    alb_dns: "lb-123.us-east-1.elb.amazonaws.com",
    alb_zone_id: "Z35SXDOTRQ7X7K"  # US East 1 constant
  }

  provider :aws do
    region "us-east-1"
  end

  # Root domain -> CloudFront
  resource :aws_route53_record, :root do
    zone_id config[:zone_id]
    name config[:domain]
    type "A"

    send(:alias) do
      name "#{config[:cloudfront_id]}.cloudfront.net"
      zone_id "Z2FDTNDATAQYW2"  # CloudFront constant
      evaluate_target_health false
    end
  end

  # API subdomain -> ALB
  resource :aws_route53_record, :api do
    zone_id config[:zone_id]
    name "api.#{config[:domain]}"
    type "A"

    send(:alias) do
      name config[:alb_dns]
      zone_id config[:alb_zone_id]
      evaluate_target_health true
    end
  end
end
```

## Cross-Template Dependencies

**Pattern:** Use remote state data sources

```ruby
template :security_layer do
  # Reference foundation_network template's outputs
  data :terraform_remote_state, :foundation do
    backend "s3"
    config do
      bucket "{bucket-name}"
      key "pangea/production/foundation_network/terraform.tfstate"
      region "us-east-1"
    end
  end

  # Use VPC ID from foundation
  resource :aws_security_group, :app do
    vpc_id "${data.terraform_remote_state.foundation.outputs.vpc_id}"
  end
end
```

## Route53 Hosted Zone

```ruby
resource :aws_route53_zone, :primary do
  name "{domain}.com"
  comment "Primary hosted zone for {product}"

  tags do
    Name "{product}-com-zone"
    Environment "production"
    ManagedBy "pangea"
  end
end
```

## CloudFront Alias Record

```ruby
resource :aws_route53_record, :root do
  zone_id "{zone-id}"
  name "{domain}.com"
  type "A"

  send(:alias) do
    name "{distribution-id}.cloudfront.net"
    zone_id "Z2FDTNDATAQYW2"  # CloudFront constant
    evaluate_target_health false
  end
end
```

## ALB Alias Record

```ruby
resource :aws_route53_record, :api do
  zone_id "{zone-id}"
  name "api.{domain}.com"
  type "A"

  send(:alias) do
    name "{alb-dns-name}"
    zone_id "{alb-zone-id}"  # Region-specific
    evaluate_target_health true
  end
end
```

## AWS Zone ID Constants

| Resource | Zone ID |
|----------|---------|
| CloudFront | `Z2FDTNDATAQYW2` |
| US East 1 ALB | `Z35SXDOTRQ7X7K` |
