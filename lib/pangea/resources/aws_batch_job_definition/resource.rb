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
require_relative 'types'
require_relative 'synthesis/synthesizer'

module Pangea
  module Resources
    module AWS
      # AWS Batch Job Definition implementation
      # Provides type-safe function for creating job definitions
      def aws_batch_job_definition(name, attributes = {})
        validated_attrs = Types::Types::BatchJobDefinitionAttributes.new(attributes)

        ref = ResourceReference.new(
          type: 'aws_batch_job_definition',
          name: name,
          resource_attributes: validated_attrs.to_h,
          outputs: {
            id: "${aws_batch_job_definition.#{name}.id}",
            arn: "${aws_batch_job_definition.#{name}.arn}",
            name: "${aws_batch_job_definition.#{name}.name}",
            revision: "${aws_batch_job_definition.#{name}.revision}",
            tags_all: "${aws_batch_job_definition.#{name}.tags_all}"
          }
        )

        container_props = validated_attrs.container_properties
        node_props = validated_attrs.node_properties

        resource :aws_batch_job_definition, name do
          job_definition_name validated_attrs.job_definition_name
          type validated_attrs.type

          if container_props
            container_properties do
              BatchJobDefinitionSynthesizer.synthesize_container(self, container_props)
            end
          end

          if node_props
            node_properties do
              BatchJobDefinitionSynthesizer.synthesize_nodes(self, node_props)
            end
          end

          if validated_attrs.retry_strategy
            retry_strategy do
              attempts validated_attrs.retry_strategy[:attempts] if validated_attrs.retry_strategy[:attempts]
            end
          end

          if validated_attrs.timeout
            timeout do
              attempt_duration_seconds validated_attrs.timeout[:attempt_duration_seconds]
            end
          end

          platform_capabilities validated_attrs.platform_capabilities if validated_attrs.platform_capabilities
          propagate_tags validated_attrs.propagate_tags if validated_attrs.propagate_tags
          tags validated_attrs.tags if validated_attrs.tags
        end

        ref
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)
