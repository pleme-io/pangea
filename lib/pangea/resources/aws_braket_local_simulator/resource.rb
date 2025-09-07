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
require 'pangea/resources/aws_braket_local_simulator/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Braket Local Simulator configuration
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Braket local simulator attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_braket_local_simulator(name, attributes = {})
        # Validate attributes using dry-struct
        simulator_attrs = Types::BraketLocalSimulatorAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_braket_local_simulator, name) do
          # Set simulator name
          simulator_name simulator_attrs.simulator_name
          
          # Set simulator type
          simulator_type simulator_attrs.simulator_type
          
          # Set configuration
          configuration do
            # Set backend configuration
            backend_configuration do
              device_name simulator_attrs.configuration[:backend_configuration][:device_name]
              
              if simulator_attrs.configuration[:backend_configuration][:shots]
                shots simulator_attrs.configuration[:backend_configuration][:shots]
              end
              
              if simulator_attrs.configuration[:backend_configuration][:max_parallel_shots]
                max_parallel_shots simulator_attrs.configuration[:backend_configuration][:max_parallel_shots]
              end
              
              if simulator_attrs.configuration[:backend_configuration][:seed]
                seed simulator_attrs.configuration[:backend_configuration][:seed]
              end
            end
            
            # Set resource configuration if provided
            if simulator_attrs.configuration[:resource_configuration]
              resource_configuration do
                cpu_count simulator_attrs.configuration[:resource_configuration][:cpu_count]
                memory_size_mb simulator_attrs.configuration[:resource_configuration][:memory_size_mb]
                
                if simulator_attrs.configuration[:resource_configuration][:gpu_count]
                  gpu_count simulator_attrs.configuration[:resource_configuration][:gpu_count]
                end
              end
            end
            
            # Set advanced configuration if provided
            if simulator_attrs.configuration[:advanced_configuration]
              advanced_configuration do
                if simulator_attrs.configuration[:advanced_configuration][:enable_parallelization]
                  enable_parallelization simulator_attrs.configuration[:advanced_configuration][:enable_parallelization]
                end
                
                if simulator_attrs.configuration[:advanced_configuration][:optimization_level]
                  optimization_level simulator_attrs.configuration[:advanced_configuration][:optimization_level]
                end
                
                if simulator_attrs.configuration[:advanced_configuration][:precision]
                  precision simulator_attrs.configuration[:advanced_configuration][:precision]
                end
              end
            end
          end
          
          # Set execution environment if provided
          if simulator_attrs.execution_environment
            execution_environment do
              if simulator_attrs.execution_environment[:docker_image]
                docker_image simulator_attrs.execution_environment[:docker_image]
              end
              
              if simulator_attrs.execution_environment[:python_version]
                python_version simulator_attrs.execution_environment[:python_version]
              end
              
              if simulator_attrs.execution_environment[:environment_variables] && !simulator_attrs.execution_environment[:environment_variables].empty?
                environment_variables simulator_attrs.execution_environment[:environment_variables]
              end
            end
          end
          
          # Set tags
          if simulator_attrs.tags && !simulator_attrs.tags.empty?
            tags simulator_attrs.tags
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_braket_local_simulator',
          name: name,
          resource_attributes: simulator_attrs.to_h,
          outputs: {
            id: "${aws_braket_local_simulator.#{name}.id}",
            arn: "${aws_braket_local_simulator.#{name}.arn}",
            simulator_name: "${aws_braket_local_simulator.#{name}.simulator_name}",
            simulator_type: "${aws_braket_local_simulator.#{name}.simulator_type}",
            status: "${aws_braket_local_simulator.#{name}.status}",
            device_arn: "${aws_braket_local_simulator.#{name}.device_arn}",
            created_at: "${aws_braket_local_simulator.#{name}.created_at}"
          },
          computed: {
            is_state_vector: simulator_attrs.is_state_vector?,
            is_density_matrix: simulator_attrs.is_density_matrix?,
            is_tensor_network: simulator_attrs.is_tensor_network?,
            max_qubits: simulator_attrs.max_qubits,
            supports_gpu: simulator_attrs.supports_gpu?,
            memory_requirement_gb: simulator_attrs.memory_requirement_gb,
            estimated_cost_per_hour: simulator_attrs.estimated_cost_per_hour,
            parallelization_enabled: simulator_attrs.parallelization_enabled?,
            optimization_level: simulator_attrs.optimization_level,
            precision_type: simulator_attrs.precision_type,
            has_custom_environment: simulator_attrs.has_custom_environment?,
            simulator_backend: simulator_attrs.simulator_backend
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)