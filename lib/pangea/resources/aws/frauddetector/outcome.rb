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
        # AWS Fraud Detector Outcome resource
        module Outcome
          # Creates an AWS Fraud Detector Outcome
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the outcome
          # @option attributes [String] :name The name of the outcome (required)
          # @option attributes [String] :description A description of the outcome
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Fraud outcome for transaction scoring
          #   aws_frauddetector_outcome(:fraud_detected, {
          #     name: "fraud_detected",
          #     description: "Outcome indicating fraudulent activity detected",
          #     tags: {
          #       OutcomeType: "Fraud",
          #       Action: "Block",
          #       Severity: "High"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created outcome
          def aws_frauddetector_outcome(name, attributes = {})
            resource(:aws_frauddetector_outcome, name) do
              name attributes[:name] if attributes[:name]
              description attributes[:description] if attributes[:description]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_frauddetector_outcome',
              name: name,
              resource_attributes: attributes,
              outputs: {
                arn: "${aws_frauddetector_outcome.#{name}.arn}",
                name: "${aws_frauddetector_outcome.#{name}.name}",
                last_updated_time: "${aws_frauddetector_outcome.#{name}.last_updated_time}",
                created_time: "${aws_frauddetector_outcome.#{name}.created_time}"
              }
            )
          end
        end
      end
    end
  end
end
