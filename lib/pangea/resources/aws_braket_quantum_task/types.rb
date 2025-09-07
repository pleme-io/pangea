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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Braket Quantum Task resources
      class BraketQuantumTaskAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Device ARN (required)
        attribute :device_arn, Resources::Types::String

        # Action JSON specification (required)
        attribute :action, Resources::Types::String

        # Device parameters (optional)
        attribute? :device_parameters, Resources::Types::String.optional

        # Output S3 bucket (required)
        attribute :output_s3_bucket, Resources::Types::String

        # Output S3 key prefix (required)
        attribute :output_s3_key_prefix, Resources::Types::String

        # Shots - number of times to run the quantum circuit (optional)
        attribute? :shots, Resources::Types::Integer.default(1000)

        # Job token for grouping tasks (optional)
        attribute? :job_token, Resources::Types::String.optional

        # Tags (optional)
        attribute? :tags, Resources::Types::Hash.schema(
          Resources::Types::String => Resources::Types::String
        ).optional

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate shots is positive
          if attrs.shots && attrs.shots <= 0
            raise Dry::Struct::Error, "shots must be positive, got #{attrs.shots}"
          end

          # Validate shots is within reasonable limits for quantum devices
          if attrs.shots && attrs.shots > 100000
            raise Dry::Struct::Error, "shots cannot exceed 100000 for quantum devices, got #{attrs.shots}"
          end

          # Validate action is valid JSON
          begin
            JSON.parse(attrs.action)
          rescue JSON::ParserError => e
            raise Dry::Struct::Error, "action must be valid JSON: #{e.message}"
          end

          # Validate device_parameters is valid JSON if provided
          if attrs.device_parameters
            begin
              JSON.parse(attrs.device_parameters)
            rescue JSON::ParserError => e
              raise Dry::Struct::Error, "device_parameters must be valid JSON: #{e.message}"
            end
          end

          # Validate S3 bucket name format
          unless attrs.output_s3_bucket.match?(/\A[a-z0-9][a-z0-9\-\.]*[a-z0-9]\z/)
            raise Dry::Struct::Error, "output_s3_bucket must be a valid S3 bucket name"
          end

          # Validate S3 key prefix doesn't start with /
          if attrs.output_s3_key_prefix.start_with?('/')
            raise Dry::Struct::Error, "output_s3_key_prefix should not start with '/'"
          end

          attrs
        end

        # Helper methods
        def device_type
          case device_arn
          when /simulator/i
            :simulator
          when /qpu/i
            :quantum_processing_unit
          when /sv1/i
            :state_vector_simulator
          when /dm1/i
            :density_matrix_simulator
          when /tn1/i
            :tensor_network_simulator
          else
            :unknown
          end
        end

        def is_simulator?
          device_type != :quantum_processing_unit
        end

        def is_quantum_hardware?
          device_type == :quantum_processing_unit
        end

        def quantum_circuit
          @quantum_circuit ||= begin
            action_data = JSON.parse(action)
            action_data['braketSchemaHeader']['name'] if action_data['braketSchemaHeader']
          rescue
            nil
          end
        end

        def estimated_cost
          # Rough cost estimation based on device type and shots
          base_cost = case device_type
          when :quantum_processing_unit
            0.30 # $0.30 per task for QPU
          when :state_vector_simulator
            0.075 # $0.075 per minute for SV1
          when :density_matrix_simulator
            0.075 # $0.075 per minute for DM1
          when :tensor_network_simulator
            0.275 # $0.275 per minute for TN1
          else
            0.00 # Free for local simulators
          end

          # Adjust for shots
          shot_multiplier = (shots / 1000.0).ceil
          base_cost * shot_multiplier
        end

        def output_location
          "s3://#{output_s3_bucket}/#{output_s3_key_prefix}"
        end

        def action_summary
          action_data = JSON.parse(action)
          {
            type: action_data['braketSchemaHeader']&.fetch('name', 'unknown'),
            version: action_data['braketSchemaHeader']&.fetch('version', 'unknown'),
            qubit_count: action_data['instructions']&.map { |i| i['target']&.max || 0 }&.max&.+(1) || 0
          }
        rescue
          { type: 'unknown', version: 'unknown', qubit_count: 0 }
        end
      end
    end
      end
    end
  end
end