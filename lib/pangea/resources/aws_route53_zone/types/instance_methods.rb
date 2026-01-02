# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Instance methods for Route53 Zone attributes
        module Route53ZoneInstanceMethods
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
      end
    end
  end
end
