# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Validation logic for DynamoDB Table attributes
        module DynamoDbTableValidations
          class << self
            def validate!(attrs)
              validate_billing_mode!(attrs)
              validate_stream_config!(attrs)
              validate_attribute_definitions!(attrs)
              validate_projection_settings!(attrs)
              validate_index_limits!(attrs)
              attrs
            end

            private

            def validate_billing_mode!(attrs)
              if attrs.billing_mode == "PROVISIONED"
                validate_provisioned_mode!(attrs)
              elsif attrs.billing_mode == "PAY_PER_REQUEST"
                validate_pay_per_request_mode!(attrs)
              end
            end

            def validate_provisioned_mode!(attrs)
              unless attrs.read_capacity && attrs.write_capacity
                raise Dry::Struct::Error, "PROVISIONED billing mode requires read_capacity and write_capacity"
              end

              attrs.global_secondary_index.each do |gsi|
                unless gsi[:read_capacity] && gsi[:write_capacity]
                  raise Dry::Struct::Error, "GSI '#{gsi[:name]}' requires read_capacity and write_capacity for PROVISIONED billing mode"
                end
              end
            end

            def validate_pay_per_request_mode!(attrs)
              if attrs.read_capacity || attrs.write_capacity
                raise Dry::Struct::Error, "PAY_PER_REQUEST billing mode does not support read_capacity or write_capacity"
              end

              attrs.global_secondary_index.each do |gsi|
                if gsi[:read_capacity] || gsi[:write_capacity]
                  raise Dry::Struct::Error, "GSI '#{gsi[:name]}' does not support capacity settings for PAY_PER_REQUEST billing mode"
                end
              end
            end

            def validate_stream_config!(attrs)
              if attrs.stream_enabled && !attrs.stream_view_type
                raise Dry::Struct::Error, "stream_view_type is required when stream_enabled is true"
              end
            end

            def validate_attribute_definitions!(attrs)
              all_key_attributes = collect_key_attributes(attrs)
              defined_attributes = attrs.attribute.map { |attr| attr[:name] }
              missing_attributes = all_key_attributes.uniq - defined_attributes

              unless missing_attributes.empty?
                raise Dry::Struct::Error, "Missing attribute definitions for: #{missing_attributes.join(', ')}"
              end
            end

            def collect_key_attributes(attrs)
              keys = [attrs.hash_key]
              keys << attrs.range_key if attrs.range_key

              attrs.global_secondary_index.each do |gsi|
                keys << gsi[:hash_key]
                keys << gsi[:range_key] if gsi[:range_key]
              end

              attrs.local_secondary_index.each do |lsi|
                keys << lsi[:range_key]
              end

              keys
            end

            def validate_projection_settings!(attrs)
              validate_gsi_projections!(attrs)
              validate_lsi_projections!(attrs)
            end

            def validate_gsi_projections!(attrs)
              attrs.global_secondary_index.each do |gsi|
                validate_index_projection!(gsi, "GSI")
              end
            end

            def validate_lsi_projections!(attrs)
              attrs.local_secondary_index.each do |lsi|
                validate_index_projection!(lsi, "LSI")
              end
            end

            def validate_index_projection!(index, type)
              projection = index[:projection_type]
              non_key_attrs = index[:non_key_attributes]

              if projection == "INCLUDE" && (!non_key_attrs || non_key_attrs.empty?)
                raise Dry::Struct::Error, "#{type} '#{index[:name]}' with INCLUDE projection_type requires non_key_attributes"
              end

              if projection != "INCLUDE" && non_key_attrs
                raise Dry::Struct::Error, "#{type} '#{index[:name]}' with #{projection} projection_type cannot have non_key_attributes"
              end
            end

            def validate_index_limits!(attrs)
              if attrs.local_secondary_index.size > 10
                raise Dry::Struct::Error, "Maximum of 10 Local Secondary Indexes allowed per table"
              end

              if attrs.global_secondary_index.size > 20
                raise Dry::Struct::Error, "Maximum of 20 Global Secondary Indexes allowed per table"
              end
            end
          end
        end
      end
    end
  end
end
