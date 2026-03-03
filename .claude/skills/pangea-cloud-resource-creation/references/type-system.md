# Type System Design

Add provider-specific types to `lib/pangea/resources/types.rb`.

## Central Type Definition Template

```ruby
# lib/pangea/resources/types.rb
module Pangea
  module Resources
    module Types
      # ============================================================================
      # Provider Name Types (e.g., Hetzner Cloud, Cloudflare, AWS)
      # ============================================================================

      # Enum types for constrained values
      ProviderLocation = String.enum('location1', 'location2', 'location3')

      # Integer constraints
      ProviderPort = Integer.constrained(gteq: 1, lteq: 65535)

      # String patterns
      ProviderDomain = String.constrained(
        format: /\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)*[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/i
      )

      # Complex validation with custom constructors
      ProviderCertificate = String.constructor { |value|
        unless value.strip.start_with?('-----BEGIN CERTIFICATE-----')
          raise Dry::Types::ConstraintError, "Must be PEM format"
        end
        value
      }

      # Hash schemas for nested structures
      ProviderNestedConfig = Hash.schema(
        required_field: String,
        optional_field?: Integer.optional,
        nested?: Hash.schema(
          inner: String
        ).optional
      )

      # Default values
      ProviderLabels = Hash.map(String, String).default({}.freeze)
    end
  end
end
```

## Type Categories

| Category | Use Case | Example |
|----------|----------|---------|
| **Enums** | Constrained string values | Locations, server types, protocols, algorithms |
| **Constraints** | Numeric ranges | Ports, sizes, TTLs, timeouts |
| **Patterns** | String formats | Domains, IPs, CIDRs, certificates |
| **Schemas** | Nested structures | Rules, policies, configurations |
| **Defaults** | Default empty collections | Tags, labels, empty arrays/hashes |

## Tracker JSON Template

```json
{
  "metadata": {
    "provider": "provider-name",
    "version": "1.x.x",
    "total_resources": 25,
    "implemented": 0,
    "completion_percentage": 0.0,
    "last_updated": "2025-11-08"
  },
  "resources": {
    "resource_name": {
      "terraform_type": "provider_resource",
      "description": "Short description",
      "components": {
        "types": false,
        "resource": false,
        "spec": false
      },
      "batch": 1,
      "priority": "high"
    }
  },
  "batches": {
    "1": {
      "name": "Core Infrastructure",
      "resources": ["resource1", "resource2"],
      "completed": false
    }
  }
}
```

## Batch Organization Example (Hetzner Cloud)

| Batch | Name | Resources |
|-------|------|-----------|
| 1 | Core Infrastructure | SSH keys, networks, firewalls, servers |
| 2 | Networking | Server networks, floating IPs, routes |
| 3 | Storage | Volumes, volume attachments |
| 4 | Load Balancing | Load balancers, services, targets |
| 5 | Advanced | Certificates, placement groups, RDNS |
| 6 | Optional | Snapshots, DNS zones, DNS records |
