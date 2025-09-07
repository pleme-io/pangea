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
require 'pangea/resources/aws_braket_device/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Braket Device configuration with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Braket device attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_braket_device(name, attributes = {})
        # Validate attributes using dry-struct
        device_attrs = Types::BraketDeviceAttributes.new(attributes)
        
        # Note: AWS Braket devices are typically pre-existing and accessed via data sources
        # This resource would primarily be used for custom device configurations or mocks
        
        # Generate terraform data source block for existing devices
        data(:aws_braket_device, name) do
          # Filter by provider
          provider_names [device_attrs.provider_name]
          
          # Filter by device type
          types [device_attrs.device_type]
          
          # Filter by status if provided
          statuses [device_attrs.device_status || 'ONLINE']
          
          # Additional filters based on capabilities
          if device_attrs.device_name
            # In practice, you'd use additional filters or post-processing
            # to match specific device names
          end
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_braket_device',
          name: name,
          resource_attributes: device_attrs.to_h,
          outputs: {
            id: "${data.aws_braket_device.#{name}.id}",
            arn: "${data.aws_braket_device.#{name}.arn}",
            name: "${data.aws_braket_device.#{name}.name}",
            type: "${data.aws_braket_device.#{name}.type}",
            provider_name: "${data.aws_braket_device.#{name}.provider_name}",
            status: "${data.aws_braket_device.#{name}.status}",
            device_capabilities: "${data.aws_braket_device.#{name}.device_capabilities}"
          },
          computed: {
            is_quantum_hardware: device_attrs.is_quantum_hardware?,
            is_simulator: device_attrs.is_simulator?,
            qubit_count: device_attrs.qubit_count,
            supported_gates: device_attrs.supported_gates,
            connectivity_type: device_attrs.connectivity_type,
            cost_per_shot: device_attrs.cost_per_shot,
            cost_unit: device_attrs.cost_unit,
            shots_range: device_attrs.shots_range,
            min_shots: device_attrs.min_shots,
            max_shots: device_attrs.max_shots,
            execution_windows: device_attrs.execution_windows,
            is_available_24_7: device_attrs.is_available_24_7?,
            native_gate_set: device_attrs.native_gate_set,
            supports_openqasm: device_attrs.supports_openqasm?,
            supports_jaqcd: device_attrs.supports_jaqcd?
          }
        )
      end
      
      # Helper function to query available Braket devices
      def aws_braket_device_query(name, filters = {})
        # Generate a data source to query available devices
        data(:aws_braket_devices, name) do
          # Apply filters
          provider_names filters[:providers] if filters[:providers]
          types filters[:types] if filters[:types]
          statuses filters[:statuses] || ['ONLINE']
        end
        
        # Return reference to the query results
        ResourceReference.new(
          type: 'aws_braket_devices',
          name: name,
          resource_attributes: filters,
          outputs: {
            arns: "${data.aws_braket_devices.#{name}.arns}",
            names: "${data.aws_braket_devices.#{name}.names}",
            providers: "${data.aws_braket_devices.#{name}.providers}",
            types: "${data.aws_braket_devices.#{name}.types}",
            statuses: "${data.aws_braket_devices.#{name}.statuses}"
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)