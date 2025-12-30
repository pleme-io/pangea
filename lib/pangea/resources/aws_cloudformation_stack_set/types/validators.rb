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

module Pangea
  module Resources
    module AWS
      module Types
        # Validation logic for CloudFormation Stack Set attributes
        module CloudFormationStackSetValidators
          module_function

          def validate!(attrs)
            validate_template_source!(attrs)
            validate_permission_model!(attrs)
            validate_template_body_format!(attrs)
            validate_operation_preferences!(attrs)
            validate_template_url!(attrs)
          end

          def validate_template_source!(attrs)
            if !attrs.template_body && !attrs.template_url
              raise Dry::Struct::Error, 'Either template_body or template_url must be specified'
            end

            return unless attrs.template_body && attrs.template_url

            raise Dry::Struct::Error, 'Cannot specify both template_body and template_url'
          end

          def validate_permission_model!(attrs)
            case attrs.permission_model
            when 'SELF_MANAGED'
              validate_self_managed!(attrs)
            when 'SERVICE_MANAGED'
              validate_service_managed!(attrs)
            end
          end

          def validate_self_managed!(attrs)
            unless attrs.administration_role_arn
              raise Dry::Struct::Error,
                    'administration_role_arn is required for SELF_MANAGED permission model'
            end

            unless attrs.execution_role_name
              raise Dry::Struct::Error,
                    'execution_role_name is required for SELF_MANAGED permission model'
            end

            return unless attrs.auto_deployment

            raise Dry::Struct::Error,
                  'auto_deployment is not supported for SELF_MANAGED permission model'
          end

          def validate_service_managed!(attrs)
            if attrs.administration_role_arn
              raise Dry::Struct::Error,
                    'administration_role_arn is not supported for SERVICE_MANAGED permission model'
            end

            return unless attrs.execution_role_name

            raise Dry::Struct::Error,
                  'execution_role_name is not supported for SERVICE_MANAGED permission model'
          end

          def validate_template_body_format!(attrs)
            return unless attrs.template_body

            begin
              JSON.parse(attrs.template_body)
            rescue JSON::ParserError
              begin
                YAML.safe_load(attrs.template_body)
              rescue Psych::SyntaxError
                raise Dry::Struct::Error, 'template_body must be valid JSON or YAML'
              end
            end
          end

          def validate_operation_preferences!(attrs)
            return unless attrs.operation_preferences

            prefs = attrs.operation_preferences

            if prefs[:max_concurrent_percentage] && prefs[:max_concurrent_count]
              raise Dry::Struct::Error,
                    'Cannot specify both max_concurrent_percentage and max_concurrent_count'
            end

            return unless prefs[:failure_tolerance_percentage] && prefs[:failure_tolerance_count]

            raise Dry::Struct::Error,
                  'Cannot specify both failure_tolerance_percentage and failure_tolerance_count'
          end

          def validate_template_url!(attrs)
            return unless attrs.template_url && !attrs.template_url.match?(/\Ahttps?:\/\//)

            raise Dry::Struct::Error, 'template_url must be a valid HTTP/HTTPS URL'
          end
        end
      end
    end
  end
end
