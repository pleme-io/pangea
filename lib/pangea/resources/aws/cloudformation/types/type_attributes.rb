# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module CloudFormation
        module Types
          # CloudFormation Type attributes
          class CloudFormationTypeAttributes < Dry::Struct
            transform_keys(&:to_sym)

            VALID_TYPES = %w[RESOURCE HOOK].freeze
            TYPE_NAME_PATTERN = /^[A-Za-z0-9]{2,64}::[A-Za-z0-9]{2,64}::[A-Za-z0-9]{2,64}$/.freeze

            # Required attributes
            attribute :type, Resources::Types::String
            attribute :type_name, Resources::Types::String

            # Schema and configuration
            attribute :schema, Resources::Types::String.optional.default(nil)
            attribute :schema_handler_package, Resources::Types::String.optional.default(nil)
            attribute :source_url, Resources::Types::String.optional.default(nil)
            attribute :documentation_url, Resources::Types::String.optional.default(nil)
            attribute :execution_role_arn, Resources::Types::String.optional.default(nil)
            attribute :logging_config, Resources::Types::Hash.optional.default(nil)
            attribute :client_request_token, Resources::Types::String.optional.default(nil)

            def self.new(attributes)
              attrs = attributes.is_a?(Hash) ? attributes : {}
              validate_type!(attrs)
              validate_type_name!(attrs)
              super(attrs)
            end

            def self.validate_type!(attrs)
              return if VALID_TYPES.include?(attrs[:type])

              raise Dry::Struct::Error, "type must be RESOURCE or HOOK"
            end

            def self.validate_type_name!(attrs)
              return unless attrs[:type_name]
              return if attrs[:type_name].match?(TYPE_NAME_PATTERN)

              raise Dry::Struct::Error, "type_name must follow format Namespace::Type::Resource"
            end

            private_class_method :validate_type!, :validate_type_name!

            def resource_type?
              type == 'RESOURCE'
            end

            def hook_type?
              type == 'HOOK'
            end

            def has_logging?
              !logging_config.nil?
            end

            def to_h
              build_hash.compact
            end

            private

            def build_hash
              {
                type: type,
                type_name: type_name,
                schema: schema,
                schema_handler_package: schema_handler_package,
                source_url: source_url,
                documentation_url: documentation_url,
                execution_role_arn: execution_role_arn,
                logging_config: logging_config,
                client_request_token: client_request_token
              }
            end
          end
        end
      end
    end
  end
end
