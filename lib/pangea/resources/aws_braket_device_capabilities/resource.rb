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
require 'pangea/resources/aws_braket_device_capabilities/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Query AWS Braket Device Capabilities for quantum device information
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Device capabilities query attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_braket_device_capabilities(name, attributes = {})
        # Validate attributes using dry-struct
        capabilities_attrs = Types::BraketDeviceCapabilitiesAttributes.new(attributes)
        
        # Generate terraform data source block via terraform-synthesizer
        data(:aws_braket_device_capabilities, name) do
          # Set device ARN
          device_arn capabilities_attrs.device_arn
          
          # Set filters if provided
          if capabilities_attrs.capability_filters && !capabilities_attrs.capability_filters.empty?
            capabilities_attrs.capability_filters.each do |filter|
              filter do
                name filter[:name]
                values filter[:values]
              end
            end
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_braket_device_capabilities',
          name: name,
          resource_attributes: capabilities_attrs.to_h,
          outputs: {
            id: "${data.aws_braket_device_capabilities.#{name}.id}",
            device_arn: "${data.aws_braket_device_capabilities.#{name}.device_arn}",
            device_name: "${data.aws_braket_device_capabilities.#{name}.device_name}",
            provider_name: "${data.aws_braket_device_capabilities.#{name}.provider_name}",
            device_type: "${data.aws_braket_device_capabilities.#{name}.device_type}",
            device_status: "${data.aws_braket_device_capabilities.#{name}.device_status}",
            device_capabilities: "${data.aws_braket_device_capabilities.#{name}.device_capabilities}",
            supported_operations: "${data.aws_braket_device_capabilities.#{name}.supported_operations}",
            qubit_count: "${data.aws_braket_device_capabilities.#{name}.qubit_count}",
            native_gate_set: "${data.aws_braket_device_capabilities.#{name}.native_gate_set}"
          },
          computed: {
            is_quantum_hardware: capabilities_attrs.is_quantum_hardware?,
            is_simulator: capabilities_attrs.is_simulator?,
            supports_openqasm: capabilities_attrs.supports_openqasm?,
            supports_jaqcd: capabilities_attrs.supports_jaqcd?,
            has_execution_windows: capabilities_attrs.has_execution_windows?,
            max_shots: capabilities_attrs.max_shots,
            min_shots: capabilities_attrs.min_shots,
            provider_type: capabilities_attrs.provider_type,
            connectivity_graph_available: capabilities_attrs.connectivity_graph_available?,
            cost_per_shot_usd: capabilities_attrs.cost_per_shot_usd
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)