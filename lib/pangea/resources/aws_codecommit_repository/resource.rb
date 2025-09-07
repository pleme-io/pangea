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
require 'pangea/resources/aws_codecommit_repository/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CodeCommit Repository with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CodeCommit repository attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_codecommit_repository(name, attributes = {})
        # Validate attributes using dry-struct
        repo_attrs = Types::CodeCommitRepositoryAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_codecommit_repository, name) do
          # Set repository name
          repository_name repo_attrs.repository_name
          
          # Set description if provided
          description repo_attrs.description if repo_attrs.description
          
          # Set default branch
          default_branch repo_attrs.default_branch
          
          # Set KMS key if provided
          kms_key_id repo_attrs.kms_key_id if repo_attrs.kms_key_id
          
          # Apply tags
          if repo_attrs.tags.any?
            tags do
              repo_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Create triggers if configured
        repo_attrs.triggers.each_with_index do |trigger_config, index|
          resource(:aws_codecommit_trigger, "#{name}_trigger_#{index}") do
            repository_name ref(:aws_codecommit_repository, name, :repository_name)
            
            triggers do
              name trigger_config[:name]
              destination_arn trigger_config[:destination_arn]
              custom_data trigger_config[:custom_data] if trigger_config[:custom_data]
              branches trigger_config[:branches] if trigger_config[:branches]
              events trigger_config[:events]
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_codecommit_repository',
          name: name,
          resource_attributes: repo_attrs.to_h,
          outputs: {
            repository_id: "${aws_codecommit_repository.#{name}.repository_id}",
            repository_name: "${aws_codecommit_repository.#{name}.repository_name}",
            arn: "${aws_codecommit_repository.#{name}.arn}",
            clone_url_http: "${aws_codecommit_repository.#{name}.clone_url_http}",
            clone_url_ssh: "${aws_codecommit_repository.#{name}.clone_url_ssh}",
            default_branch: "${aws_codecommit_repository.#{name}.default_branch}"
          },
          computed: {
            encrypted: repo_attrs.encrypted?,
            has_triggers: repo_attrs.has_triggers?,
            trigger_count: repo_attrs.trigger_count,
            trigger_names: repo_attrs.trigger_names,
            all_trigger_events: repo_attrs.all_trigger_events
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)