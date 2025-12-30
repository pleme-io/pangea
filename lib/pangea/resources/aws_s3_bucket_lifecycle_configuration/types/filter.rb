# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # S3 lifecycle rule filter tag
        class LifecycleFilterTag < Dry::Struct
          attribute :key, Resources::Types::String
          attribute :value, Resources::Types::String
        end

        # S3 lifecycle rule filter and block
        class LifecycleFilterAnd < Dry::Struct
          attribute :object_size_greater_than, Resources::Types::Integer.optional
          attribute :object_size_less_than, Resources::Types::Integer.optional
          attribute :prefix, Resources::Types::String.optional
          attribute :tags, Resources::Types::Array.of(LifecycleFilterTag).optional
        end

        # S3 lifecycle rule filter
        class LifecycleFilter < Dry::Struct
          attribute? :and_condition, LifecycleFilterAnd.optional
          attribute :object_size_greater_than, Resources::Types::Integer.optional
          attribute :object_size_less_than, Resources::Types::Integer.optional
          attribute :prefix, Resources::Types::String.optional
          attribute? :tag, LifecycleFilterTag.optional

          def self.new(attributes = {})
            attrs = super(attributes)

            # Count non-nil filter conditions
            conditions = [
              attrs.and_condition,
              attrs.object_size_greater_than,
              attrs.object_size_less_than,
              attrs.prefix,
              attrs.tag
            ].compact.count

            # Can only have one top-level filter condition
            if conditions > 1
              raise Dry::Struct::Error, "Can only specify one top-level filter condition"
            end

            attrs
          end
        end
      end
    end
  end
end
