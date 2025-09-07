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
require 'pangea/resources/aws_braket_quantum_task/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Braket Quantum Task with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Braket quantum task attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_braket_quantum_task(name, attributes = {})
        # Validate attributes using dry-struct
        task_attrs = Types::BraketQuantumTaskAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_braket_quantum_task, name) do
          # Set device ARN
          device_arn task_attrs.device_arn
          
          # Set action JSON
          action task_attrs.action
          
          # Set device parameters if provided
          device_parameters task_attrs.device_parameters if task_attrs.device_parameters
          
          # Set output S3 location
          output_s3_bucket task_attrs.output_s3_bucket
          output_s3_key_prefix task_attrs.output_s3_key_prefix
          
          # Set shots count
          shots task_attrs.shots
          
          # Set job token if provided
          job_token task_attrs.job_token if task_attrs.job_token
          
          # Set tags if provided
          if task_attrs.tags && !task_attrs.tags.empty?
            tags task_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_braket_quantum_task',
          name: name,
          resource_attributes: task_attrs.to_h,
          outputs: {
            id: "${aws_braket_quantum_task.#{name}.id}",
            arn: "${aws_braket_quantum_task.#{name}.arn}",
            status: "${aws_braket_quantum_task.#{name}.status}",
            output_s3_uri: "${aws_braket_quantum_task.#{name}.output_s3_uri}",
            created_at: "${aws_braket_quantum_task.#{name}.created_at}",
            ended_at: "${aws_braket_quantum_task.#{name}.ended_at}"
          },
          computed: {
            device_type: task_attrs.device_type,
            is_simulator: task_attrs.is_simulator?,
            is_quantum_hardware: task_attrs.is_quantum_hardware?,
            quantum_circuit: task_attrs.quantum_circuit,
            estimated_cost: task_attrs.estimated_cost,
            output_location: task_attrs.output_location,
            action_summary: task_attrs.action_summary
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)