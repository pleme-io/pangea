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
require 'pangea/resources/aws_codepipeline/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CodePipeline with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CodePipeline attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_codepipeline(name, attributes = {})
        # Validate attributes using dry-struct
        pipeline_attrs = Types::CodePipelineAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_codepipeline, name) do
          # Basic configuration
          name pipeline_attrs.name
          role_arn pipeline_attrs.role_arn
          
          # Artifact store configuration
          artifact_store do
            type pipeline_attrs.artifact_store[:type]
            location pipeline_attrs.artifact_store[:location]
            
            if pipeline_attrs.artifact_store[:encryption_key]
              encryption_key do
                id pipeline_attrs.artifact_store[:encryption_key][:id]
                type pipeline_attrs.artifact_store[:encryption_key][:type]
              end
            end
          end
          
          # Stages configuration
          pipeline_attrs.stages.each do |stage_config|
            stage do
              name stage_config[:name]
              
              # Actions within stage
              stage_config[:actions].each do |action_config|
                action do
                  name action_config[:name]
                  
                  # Action type ID
                  action_type_id do
                    category action_config[:action_type_id][:category]
                    owner action_config[:action_type_id][:owner]
                    provider action_config[:action_type_id][:provider]
                    version action_config[:action_type_id][:version]
                  end
                  
                  # Configuration
                  configuration action_config[:configuration] if action_config[:configuration]
                  
                  # Artifacts
                  input_artifacts action_config[:input_artifacts] if action_config[:input_artifacts]
                  output_artifacts action_config[:output_artifacts] if action_config[:output_artifacts]
                  
                  # Optional fields
                  run_order action_config[:run_order] if action_config[:run_order]
                  role_arn action_config[:role_arn] if action_config[:role_arn]
                  region action_config[:region] if action_config[:region]
                  namespace action_config[:namespace] if action_config[:namespace]
                end
              end
            end
          end
          
          # Apply tags
          if pipeline_attrs.tags.any?
            tags do
              pipeline_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_codepipeline',
          name: name,
          resource_attributes: pipeline_attrs.to_h,
          outputs: {
            id: "${aws_codepipeline.#{name}.id}",
            arn: "${aws_codepipeline.#{name}.arn}",
            name: "${aws_codepipeline.#{name}.name}"
          },
          computed: {
            stage_count: pipeline_attrs.stage_count,
            action_count: pipeline_attrs.action_count,
            uses_encryption: pipeline_attrs.uses_encryption?,
            source_providers: pipeline_attrs.source_providers,
            build_providers: pipeline_attrs.build_providers,
            deploy_providers: pipeline_attrs.deploy_providers,
            has_manual_approval: pipeline_attrs.has_manual_approval?,
            cross_region_actions: pipeline_attrs.cross_region_actions,
            artifact_flow_diagram: pipeline_attrs.artifact_flow_diagram
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)