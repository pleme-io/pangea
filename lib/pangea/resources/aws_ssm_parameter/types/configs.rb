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
        # Common SSM Parameter configurations
        module SsmParameterConfigs
          # Simple string parameter
          def self.string_parameter(name, value, description: nil)
            {
              name: name,
              type: "String",
              value: value,
              description: description,
              tier: "Standard"
            }.compact
          end

          # Secure string parameter with KMS encryption
          def self.secure_parameter(name, value, key_id: nil, description: nil)
            {
              name: name,
              type: "SecureString",
              value: value,
              key_id: key_id,
              description: description,
              tier: "Standard"
            }.compact
          end

          # String list parameter
          def self.string_list_parameter(name, values, description: nil)
            {
              name: name,
              type: "StringList",
              value: values.is_a?(Array) ? values.join(',') : values,
              description: description,
              tier: "Standard"
            }.compact
          end

          # Configuration parameter with validation pattern
          def self.config_parameter(name, value, pattern, description: nil)
            {
              name: name,
              type: "String",
              value: value,
              allowed_pattern: pattern,
              description: description,
              tier: "Standard"
            }.compact
          end

          # Advanced tier parameter for large values
          def self.advanced_parameter(name, value, description: nil)
            {
              name: name,
              type: "String",
              value: value,
              description: description,
              tier: "Advanced"
            }.compact
          end

          # Database connection parameter
          def self.database_config_parameter(name, connection_string, key_id: nil)
            {
              name: name,
              type: "SecureString",
              value: connection_string,
              key_id: key_id,
              description: "Database connection configuration",
              tier: "Standard"
            }.compact
          end

          # Application configuration parameter
          def self.app_config_parameter(name, config_json, description: nil)
            {
              name: name,
              type: "String",
              value: config_json,
              description: description,
              data_type: "text",
              tier: config_json.bytesize > 4096 ? "Advanced" : "Standard"
            }.compact
          end

          # AMI ID parameter
          def self.ami_parameter(name, ami_id, description: nil)
            {
              name: name,
              type: "String",
              value: ami_id,
              description: description,
              data_type: "aws:ec2:image",
              allowed_pattern: "^ami-[a-z0-9]{8,17}$"
            }.compact
          end
        end
      end
    end
  end
end
