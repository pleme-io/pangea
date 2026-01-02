# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Common Route53 hosted zone configurations
        module Route53ZoneConfigs
          # Public hosted zone for a domain
          def self.public_zone(domain_name, comment: nil)
            {
              name: domain_name,
              comment: comment || "Public hosted zone for #{domain_name}",
              force_destroy: false
            }
          end

          # Private hosted zone for internal services
          def self.private_zone(domain_name, vpc_id, vpc_region: nil, comment: nil)
            {
              name: domain_name,
              comment: comment || "Private hosted zone for #{domain_name}",
              vpc: [
                {
                  vpc_id: vpc_id,
                  vpc_region: vpc_region
                }.compact
              ],
              force_destroy: false
            }
          end

          # Multi-VPC private zone (for cross-VPC DNS resolution)
          def self.multi_vpc_private_zone(domain_name, vpc_configs, comment: nil)
            {
              name: domain_name,
              comment: comment || "Multi-VPC private hosted zone for #{domain_name}",
              vpc: vpc_configs,
              force_destroy: false
            }
          end

          # Development zone with force destroy enabled
          def self.development_zone(domain_name, is_private: false, vpc_id: nil)
            config = {
              name: domain_name,
              comment: "Development hosted zone for #{domain_name}",
              force_destroy: true  # Allow easy cleanup in development
            }

            if is_private && vpc_id
              config[:vpc] = [{ vpc_id: vpc_id }]
            end

            config
          end

          # Corporate internal zone
          def self.corporate_internal_zone(internal_domain, vpc_configs)
            {
              name: internal_domain,
              comment: "Corporate internal DNS zone for #{internal_domain}",
              vpc: vpc_configs,
              force_destroy: false
            }
          end
        end
      end
    end
  end
end
