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
        # AWS Fraud Detector Event Type resource
        module EventType
          # Creates an AWS Fraud Detector Event Type
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the event type
          # @option attributes [String] :name The name of the event type (required)
          # @option attributes [String] :description A description of the event type
          # @option attributes [Array<String>] :entity_types List of entity type names (required)
          # @option attributes [Array<String>] :event_variables List of event variable names (required)
          # @option attributes [Array<String>] :labels List of label names (required)
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Payment transaction event type
          #   aws_frauddetector_event_type(:payment_transaction_event, {
          #     name: "payment_transaction",
          #     description: "Online payment transaction events for fraud detection",
          #     entity_types: [
          #       ref(:aws_frauddetector_entity_type, :customer_entity, :name)
          #     ],
          #     event_variables: [
          #       ref(:aws_frauddetector_variable, :transaction_amount, :name),
          #       ref(:aws_frauddetector_variable, :payment_method, :name),
          #       ref(:aws_frauddetector_variable, :ip_address, :name)
          #     ],
          #     labels: [
          #       ref(:aws_frauddetector_outcome, :fraud_outcome, :name),
          #       ref(:aws_frauddetector_outcome, :legitimate_outcome, :name)
          #     ],
          #     tags: {
          #       EventCategory: "Payment",
          #       RiskType: "Transaction",
          #       Industry: "Ecommerce"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created event type
          def aws_frauddetector_event_type(name, attributes = {})
            resource(:aws_frauddetector_event_type, name) do
              name attributes[:name] if attributes[:name]
              description attributes[:description] if attributes[:description]
              entity_types attributes[:entity_types] if attributes[:entity_types]
              event_variables attributes[:event_variables] if attributes[:event_variables]
              labels attributes[:labels] if attributes[:labels]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_frauddetector_event_type',
              name: name,
              resource_attributes: attributes,
              outputs: {
                arn: "${aws_frauddetector_event_type.#{name}.arn}",
                name: "${aws_frauddetector_event_type.#{name}.name}",
                last_updated_time: "${aws_frauddetector_event_type.#{name}.last_updated_time}",
                created_time: "${aws_frauddetector_event_type.#{name}.created_time}"
              }
            )
          end
        end
      end
    end
  end
end
