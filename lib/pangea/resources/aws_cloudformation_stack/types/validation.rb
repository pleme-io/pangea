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

require 'json'
require 'yaml'

module Pangea
  module Resources
    module AWS
      module Types
        class CloudFormationStackAttributes
          # Validation methods for CloudFormation stack attributes
          module Validation
            def self.validate_template_source(attrs)
              if !attrs.template_body && !attrs.template_url
                raise Dry::Struct::Error, 'Either template_body or template_url must be specified'
              end

              if attrs.template_body && attrs.template_url
                raise Dry::Struct::Error, 'Cannot specify both template_body and template_url'
              end
            end

            def self.validate_policy_source(attrs)
              if attrs.policy_body && attrs.policy_url
                raise Dry::Struct::Error, 'Cannot specify both policy_body and policy_url'
              end
            end

            def self.validate_template_body(template_body)
              return unless template_body

              begin
                JSON.parse(template_body)
              rescue JSON::ParserError
                begin
                  YAML.safe_load(template_body)
                rescue Psych::SyntaxError
                  raise Dry::Struct::Error, 'template_body must be valid JSON or YAML'
                end
              end
            end

            def self.validate_policy_body(policy_body)
              return unless policy_body

              begin
                JSON.parse(policy_body)
              rescue JSON::ParserError
                raise Dry::Struct::Error, 'policy_body must be valid JSON'
              end
            end

            def self.validate_url(url, field_name)
              return unless url

              unless url.match?(%r{\Ahttps?://})
                raise Dry::Struct::Error, "#{field_name} must be a valid HTTP/HTTPS URL"
              end
            end

            def self.validate_all(attrs)
              validate_template_source(attrs)
              validate_policy_source(attrs)
              validate_template_body(attrs.template_body)
              validate_policy_body(attrs.policy_body)
              validate_url(attrs.template_url, 'template_url')
              validate_url(attrs.policy_url, 'policy_url')
            end
          end
        end
      end
    end
  end
end
