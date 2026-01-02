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
      module FraudDetector
        # AWS Fraud Detector Variable resource
        module Variable
          # Creates an AWS Fraud Detector Variable
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the variable
          # @option attributes [String] :name The name of the variable (required)
          # @option attributes [String] :data_type The data type of the variable (required)
          # @option attributes [String] :data_source The data source of the variable (required)
          # @option attributes [String] :default_value The default value of the variable
          # @option attributes [String] :description A description of the variable
          # @option attributes [String] :variable_type The type of the variable
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Transaction amount variable for fraud detection
          #   aws_frauddetector_variable(:transaction_amount_var, {
          #     name: "transaction_amount",
          #     data_type: "FLOAT",
          #     data_source: "EVENT",
          #     default_value: "0.0",
          #     description: "The monetary amount of the transaction",
          #     variable_type: "CONTINUOUS",
          #     tags: {
          #       VariableCategory: "Financial",
          #       DataSensitivity: "Medium"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created variable
          def aws_frauddetector_variable(name, attributes = {})
            resource(:aws_frauddetector_variable, name) do
              name attributes[:name] if attributes[:name]
              data_type attributes[:data_type] if attributes[:data_type]
              data_source attributes[:data_source] if attributes[:data_source]
              default_value attributes[:default_value] if attributes[:default_value]
              description attributes[:description] if attributes[:description]
              variable_type attributes[:variable_type] if attributes[:variable_type]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_frauddetector_variable',
              name: name,
              resource_attributes: attributes,
              outputs: {
                arn: "${aws_frauddetector_variable.#{name}.arn}",
                name: "${aws_frauddetector_variable.#{name}.name}",
                last_updated_time: "${aws_frauddetector_variable.#{name}.last_updated_time}",
                created_time: "${aws_frauddetector_variable.#{name}.created_time}"
              }
            )
          end
        end
      end
    end
  end
end
