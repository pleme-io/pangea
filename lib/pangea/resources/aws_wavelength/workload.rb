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
      # Create a Wavelength workload
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Workload attributes
      # @option attributes [String] :workload_name (required) The workload name
      # @option attributes [String] :workload_type (required) The workload type (e.g., "COMPUTE", "STORAGE")
      # @option attributes [String] :wavelength_zone (required) The Wavelength zone
      # @option attributes [Hash] :configuration Workload configuration
      # @option attributes [String] :description Workload description
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_wavelength_workload(name, attributes = {})
        required_attrs = %i[workload_name workload_type wavelength_zone]
        optional_attrs = {
          configuration: {},
          description: nil,
          tags: {}
        }

        workload_attrs = optional_attrs.merge(attributes)

        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless workload_attrs.key?(attr)
        end

        resource(:aws_wavelength_workload, name) do
          workload_name workload_attrs[:workload_name]
          workload_type workload_attrs[:workload_type]
          wavelength_zone workload_attrs[:wavelength_zone]
          description workload_attrs[:description] if workload_attrs[:description]

          if workload_attrs[:configuration].any?
            configuration workload_attrs[:configuration]
          end

          if workload_attrs[:tags].any?
            tags workload_attrs[:tags]
          end
        end

        ResourceReference.new(
          type: 'aws_wavelength_workload',
          name: name,
          resource_attributes: workload_attrs,
          outputs: {
            id: "${aws_wavelength_workload.#{name}.id}",
            arn: "${aws_wavelength_workload.#{name}.arn}",
            status: "${aws_wavelength_workload.#{name}.status}",
            creation_time: "${aws_wavelength_workload.#{name}.creation_time}"
          }
        )
      end
    end
  end
end
