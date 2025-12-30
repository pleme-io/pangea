# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'validation'
require_relative 'instance_methods'

module Pangea
  module Resources
    module AWS
      module Types
        # Type-safe attributes for AWS Route53 Hosted Zone resources
        class Route53ZoneAttributes < Dry::Struct
          include Route53ZoneValidation
          include Route53ZoneInstanceMethods

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
        end
      end
    end
  end
end
