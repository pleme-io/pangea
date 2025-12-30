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
          # CloudFormation Stack Set attributes with validation
          class CloudFormationStackSetAttributes < Dry::Struct
            transform_keys(&:to_sym)

            VALID_CAPABILITIES = %w[
              CAPABILITY_IAM
              CAPABILITY_NAMED_IAM
              CAPABILITY_AUTO_EXPAND
            ].freeze

            VALID_PERMISSION_MODELS = %w[SERVICE_MANAGED SELF_MANAGED].freeze
            VALID_CALL_AS = %w[DELEGATED_ADMIN SELF].freeze

            # Required attributes
            attribute :name, Resources::Types::String

            # Template source (mutually exclusive)
            attribute :template_body, Resources::Types::String.optional.default(nil)
            attribute :template_url, Resources::Types::String.optional.default(nil)

            # Optional attributes
            attribute :parameters, Resources::Types::Hash.default({}.freeze)
            attribute :capabilities, Resources::Types::Array.of(Resources::Types::String).default([].freeze)
            attribute :description, Resources::Types::String.optional.default(nil)
            attribute :execution_role_name, Resources::Types::String.optional.default(nil)
            attribute :administration_role_arn, Resources::Types::String.optional.default(nil)
            attribute :permission_model, Resources::Types::String.optional.default(nil)
            attribute :call_as, Resources::Types::String.optional.default(nil)
            attribute :auto_deployment, Resources::Types::Hash.optional.default(nil)
            attribute :managed_execution, Resources::Types::Hash.optional.default(nil)
            attribute :operation_preferences, Resources::Types::Hash.optional.default(nil)
            attribute :tags, Resources::Types::Hash.default({}.freeze)

            def self.new(attributes)
              attrs = attributes.is_a?(Hash) ? attributes : {}
              validate_template_source!(attrs)
              validate_permission_model!(attrs)
              validate_call_as!(attrs)
              validate_capabilities!(attrs)
              super(attrs)
            end

            def self.validate_template_source!(attrs)
              template_sources = [attrs[:template_body], attrs[:template_url]].compact
              raise Dry::Struct::Error, "Must specify either template_body or template_url" if template_sources.empty?
              raise Dry::Struct::Error, "Can only specify one of: template_body or template_url" if template_sources.length > 1
            end

            def self.validate_permission_model!(attrs)
              return unless attrs[:permission_model]
              return if VALID_PERMISSION_MODELS.include?(attrs[:permission_model])

              raise Dry::Struct::Error, "permission_model must be SERVICE_MANAGED or SELF_MANAGED"
            end

            def self.validate_call_as!(attrs)
              return unless attrs[:call_as]
              return if VALID_CALL_AS.include?(attrs[:call_as])

              raise Dry::Struct::Error, "call_as must be DELEGATED_ADMIN or SELF"
            end

            def self.validate_capabilities!(attrs)
              return unless attrs[:capabilities]

              invalid_caps = attrs[:capabilities] - VALID_CAPABILITIES
              return if invalid_caps.empty?

              raise Dry::Struct::Error, "Invalid capabilities: #{invalid_caps.join(', ')}"
            end

            private_class_method :validate_template_source!, :validate_permission_model!,
                                 :validate_call_as!, :validate_capabilities!

            def organization_managed?
              permission_model == 'SERVICE_MANAGED'
            end

            def has_auto_deployment?
              !auto_deployment.nil?
            end

            def has_managed_execution?
              !managed_execution.nil?
            end

            def template_source
              return :body if template_body
              return :url if template_url

              :none
            end

            def requires_capabilities?
              capabilities.any?
            end

            def to_h
              build_hash.compact
            end

            private

            def build_hash
              {
                name: name,
                template_body: template_body,
                template_url: template_url,
                parameters: parameters.any? ? parameters : nil,
                capabilities: capabilities.any? ? capabilities : nil,
                description: description,
                execution_role_name: execution_role_name,
                administration_role_arn: administration_role_arn,
                permission_model: permission_model,
                call_as: call_as,
                auto_deployment: auto_deployment,
                managed_execution: managed_execution,
                operation_preferences: operation_preferences,
                tags: tags.any? ? tags : nil
              }
            end
          end
        end
      end
    end
  end
end
