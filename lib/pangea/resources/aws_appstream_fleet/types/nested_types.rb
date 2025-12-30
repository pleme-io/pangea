# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Compute capacity configuration
        class ComputeCapacityType < Dry::Struct
          transform_keys(&:to_sym)

          attribute :desired_instances, Resources::Types::Integer.constrained(gteq: 1)

          # Computed based on fleet type
          def min_instances
            desired_instances # AppStream manages scaling
          end

          def max_instances
            desired_instances # AppStream manages scaling
          end
        end

        # VPC configuration
        class VpcConfigType < Dry::Struct
          transform_keys(&:to_sym)

          attribute :subnet_ids, Resources::Types::Array.of(
            Resources::Types::String
          ).constrained(min_size: 1)

          attribute :security_group_ids, Resources::Types::Array.of(
            Resources::Types::String
          ).constrained(min_size: 1).optional

          # Validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate subnet count for high availability
            if attrs[:subnet_ids] && attrs[:subnet_ids].length == 1
              # Warning: Single subnet reduces availability
              # This is allowed but not recommended
            end

            super(attrs)
          end

          def multi_az?
            subnet_ids.length > 1
          end
        end

        # Domain join configuration
        class DomainJoinInfoType < Dry::Struct
          transform_keys(&:to_sym)

          attribute :directory_name, Resources::Types::String.constrained(
            format: /\A[a-zA-Z0-9.-]+\z/
          )

          attribute :organizational_unit_distinguished_name, Resources::Types::String.optional

          # Validation for OU format
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            if attrs[:organizational_unit_distinguished_name]
              ou = attrs[:organizational_unit_distinguished_name]
              unless ou.match?(/\AOU=.+/)
                raise Dry::Struct::Error, "Organizational unit must be in format 'OU=...'"
              end
            end

            super(attrs)
          end
        end
      end
    end
  end
end
