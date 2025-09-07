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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_ssm_document/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Systems Manager Document with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] SSM document attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_ssm_document(name, attributes = {})
        # Validate attributes using dry-struct
        document_attrs = Types::SsmDocumentAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_ssm_document, name) do
          document_name document_attrs.name
          document_type document_attrs.document_type
          content document_attrs.content
          document_format document_attrs.document_format

          # Target type (for Command documents)
          if document_attrs.target_type
            target_type document_attrs.target_type
          end

          # Schema version
          if document_attrs.schema_version
            schema_version document_attrs.schema_version
          end

          # Version name
          if document_attrs.version_name
            version_name document_attrs.version_name
          end

          # Permissions
          if document_attrs.is_shared?
            permissions do
              type document_attrs.permissions[:type]
              account_ids document_attrs.permissions[:account_ids]
              if document_attrs.permissions[:shared_document_version]
                shared_document_version document_attrs.permissions[:shared_document_version]
              end
            end
          end

          # Dependencies (requires)
          document_attrs.requires.each do |requirement|
            requires do
              name requirement[:name]
              version requirement[:version] if requirement[:version]
            end
          end

          # Attachments
          document_attrs.attachments_source.each do |attachment|
            attachments_source do
              key attachment[:key]
              values attachment[:values]
              name attachment[:name] if attachment[:name]
            end
          end

          # Apply tags if present
          if document_attrs.tags.any?
            tags do
              document_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_ssm_document',
          name: name,
          resource_attributes: document_attrs.to_h,
          outputs: {
            name: "${aws_ssm_document.#{name}.name}",
            arn: "${aws_ssm_document.#{name}.arn}",
            created_date: "${aws_ssm_document.#{name}.created_date}",
            default_version: "${aws_ssm_document.#{name}.default_version}",
            description: "${aws_ssm_document.#{name}.description}",
            document_format: "${aws_ssm_document.#{name}.document_format}",
            document_type: "${aws_ssm_document.#{name}.document_type}",
            document_version: "${aws_ssm_document.#{name}.document_version}",
            hash: "${aws_ssm_document.#{name}.hash}",
            hash_type: "${aws_ssm_document.#{name}.hash_type}",
            latest_version: "${aws_ssm_document.#{name}.latest_version}",
            owner: "${aws_ssm_document.#{name}.owner}",
            parameter: "${aws_ssm_document.#{name}.parameter}",
            platform_types: "${aws_ssm_document.#{name}.platform_types}",
            schema_version: "${aws_ssm_document.#{name}.schema_version}",
            status: "${aws_ssm_document.#{name}.status}",
            tags_all: "${aws_ssm_document.#{name}.tags_all}"
          },
          computed_properties: {
            is_command_document: document_attrs.is_command_document?,
            is_automation_document: document_attrs.is_automation_document?,
            is_policy_document: document_attrs.is_policy_document?,
            is_session_document: document_attrs.is_session_document?,
            uses_json_format: document_attrs.uses_json_format?,
            uses_yaml_format: document_attrs.uses_yaml_format?,
            has_target_type: document_attrs.has_target_type?,
            has_schema_version: document_attrs.has_schema_version?,
            has_version_name: document_attrs.has_version_name?,
            is_shared: document_attrs.is_shared?,
            is_private: document_attrs.is_private?,
            has_dependencies: document_attrs.has_dependencies?,
            has_attachments: document_attrs.has_attachments?,
            shared_with_accounts: document_attrs.shared_with_accounts,
            dependency_names: document_attrs.dependency_names,
            document_steps: document_attrs.document_steps,
            estimated_execution_time: document_attrs.estimated_execution_time
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)