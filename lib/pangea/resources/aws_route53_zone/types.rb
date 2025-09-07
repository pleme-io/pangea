# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Route53 Hosted Zone resources
        class Route53ZoneAttributes < Dry::Struct
          transform_keys(&:to_sym)
          # Domain name for the hosted zone
          attribute :name, Pangea::Resources::Types::String

          # Comment/description for the hosted zone
          attribute :comment?, Pangea::Resources::Types::String.optional

          # Delegation set ID to use (for reusable delegation sets)
          attribute :delegation_set_id?, Pangea::Resources::Types::String.optional

          # Force destroy the zone even if it contains records
          attribute :force_destroy?, Pangea::Resources::Types::Bool.optional.default(false)

          # VPC configuration for private hosted zones
          attribute :vpc?, Pangea::Resources::Types::Array.of(
            Pangea::Resources::Types::Hash.schema(
              vpc_id: Pangea::Resources::Types::String,
              vpc_region?: Pangea::Resources::Types::String.optional
            )
          ).optional.default(proc { [] }.freeze)

          # Tags to apply to the hosted zone
          attribute :tags?, Pangea::Resources::Types::AwsTags.optional.default(proc { {} }.freeze)

          # Custom validation
          def self.new(attributes = {})
            attrs = super(attributes)
          
          # Validate domain name format
          unless attrs.valid_domain_name?
            raise Dry::Struct::Error, "Invalid domain name format: #{attrs.name}"
          end

          # Validate domain name length
          if attrs.name.length > 253
            raise Dry::Struct::Error, "Domain name cannot exceed 253 characters"
          end

          # Validate VPC configuration for private zones
          if attrs.vpc.any?
            attrs.vpc.each do |vpc_config|
              # Validate VPC ID format
              unless vpc_config[:vpc_id].match?(/\Avpc-[a-f0-9]{8,17}\z/)
                raise Dry::Struct::Error, "Invalid VPC ID format: #{vpc_config[:vpc_id]}"
              end
            end
          end

          # Validate delegation set ID format if provided
          if attrs.delegation_set_id
            unless attrs.delegation_set_id.match?(/\A[A-Z0-9]+\z/)
              raise Dry::Struct::Error, "Invalid delegation set ID format: #{attrs.delegation_set_id}"
            end
          end

          # Set default comment if not provided
          unless attrs.comment
            zone_type = attrs.is_private? ? "Private" : "Public"
            attrs = attrs.copy_with(comment: "#{zone_type} hosted zone for #{attrs.name}")
          end

            attrs
          end

          # Helper methods
          def valid_domain_name?
            # Basic domain name validation
            return false if name.nil? || name.empty?
            
            # Cannot start or end with dot
            return false if name.start_with?('.') || name.end_with?('.')
            
            # Split into labels and validate each
            labels = name.split('.')
            return false if labels.empty?
            
            labels.all? { |label| valid_label?(label) }
          end

          def valid_label?(label)
            # Each label must be 1-63 characters
            return false if label.length < 1 || label.length > 63
            
            # Must start and end with alphanumeric
            return false unless label.match?(/\A[a-zA-Z0-9].*[a-zA-Z0-9]\z/) || label.length == 1
            
            # Can contain hyphens but not start or end with them
            return false if label.start_with?('-') || label.end_with?('-')
            
            # Only alphanumeric and hyphens allowed
            label.match?(/\A[a-zA-Z0-9\-]+\z/)
          end

          def is_private?
            vpc.any?
          end

          def is_public?
            vpc.empty?
          end

          def zone_type
            is_private? ? "private" : "public"
          end

          def vpc_count
            vpc.length
          end

          def domain_parts
            name.split('.')
          end

          def top_level_domain
            domain_parts.last
          end

          def subdomain?
            domain_parts.length > 2
          end

          def root_domain?
            domain_parts.length == 2
          end

          # Check if this is an AWS service domain
          def aws_service_domain?
            name.end_with?('.amazonaws.com') || name.end_with?('.aws.amazon.com')
          end

          # Get the parent domain (if subdomain)
          def parent_domain
            return nil unless subdomain?
            domain_parts[1..-1].join('.')
          end

          # Estimate monthly cost (hosted zones have fixed pricing)
          def estimated_monthly_cost
            base_cost = 0.50  # $0.50 per hosted zone per month
            
            # First 25 hosted zones are $0.50 each
            # 26+ zones are discounted (simplified calculation)
            
            "$#{base_cost}/month + $0.40 per million queries"
          end

          # Check for common configuration issues
          def validate_configuration
            warnings = []
            
            if is_private? && vpc.empty?
              warnings << "Private zone configuration specified but no VPCs provided"
            end
            
            if force_destroy
              warnings << "force_destroy is enabled - zone will be deleted even with records"
            end
            
            if name.include?('_')
              warnings << "Domain name contains underscores - may cause DNS issues"
            end
            
            if name.length > 200
              warnings << "Very long domain name - consider shorter alternatives"
            end
            
            warnings
          end
        end

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