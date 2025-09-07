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
        # AWS Fraud Detector resources for fraud detection and prevention
        # These resources manage fraud detection models, rules, and detection workflows
        # to identify potentially fraudulent activities in real-time.
        #
        # @see https://docs.aws.amazon.com/frauddetector/
        module Detector
          # Creates an AWS Fraud Detector
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the detector
          # @option attributes [String] :detector_id The ID of the detector (required)
          # @option attributes [String] :description A description of the detector
          # @option attributes [String] :event_type_name The name of the event type (required)
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Basic fraud detection for online transactions
          #   aws_frauddetector_detector(:transaction_fraud_detector, {
          #     detector_id: "online_transaction_fraud_detector",
          #     description: "Detects fraudulent online payment transactions",
          #     event_type_name: ref(:aws_frauddetector_event_type, :payment_event, :name),
          #     tags: {
          #       UseCase: "PaymentFraud",
          #       BusinessUnit: "Payments",
          #       RiskLevel: "High"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created detector
          def aws_frauddetector_detector(name, attributes = {})
            resource = resource(:aws_frauddetector_detector, name) do
              detector_id attributes[:detector_id] if attributes[:detector_id]
              description attributes[:description] if attributes[:description]
              event_type_name attributes[:event_type_name] if attributes[:event_type_name]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_frauddetector_detector',
              name: name,
              resource_attributes: attributes,
              outputs: {
                arn: "${aws_frauddetector_detector.#{name}.arn}",
                detector_id: "${aws_frauddetector_detector.#{name}.detector_id}",
                detector_version_status: "${aws_frauddetector_detector.#{name}.detector_version_status}",
                last_updated_time: "${aws_frauddetector_detector.#{name}.last_updated_time}",
                created_time: "${aws_frauddetector_detector.#{name}.created_time}"
              }
            )
          end

          # Creates an AWS Fraud Detector Entity Type
          #
          # @param name [Symbol] The unique name for this resource instance
          # @param attributes [Hash] The configuration options for the entity type
          # @option attributes [String] :name The name of the entity type (required)
          # @option attributes [String] :description A description of the entity type
          # @option attributes [Hash<String, String>] :tags A map of tags to assign to the resource
          #
          # @example Customer entity type for fraud detection
          #   aws_frauddetector_entity_type(:customer_entity, {
          #     name: "customer",
          #     description: "Represents customers in fraud detection models",
          #     tags: {
          #       EntityCategory: "Customer",
          #       DataType: "PersonalIdentifier"
          #     }
          #   })
          #
          # @return [ResourceReference] Reference to the created entity type
          def aws_frauddetector_entity_type(name, attributes = {})
            resource = resource(:aws_frauddetector_entity_type, name) do
              name attributes[:name] if attributes[:name]
              description attributes[:description] if attributes[:description]
              tags attributes[:tags] if attributes[:tags]
            end

            ResourceReference.new(
              type: 'aws_frauddetector_entity_type',
              name: name,
              resource_attributes: attributes,
              outputs: {
                arn: "${aws_frauddetector_entity_type.#{name}.arn}",
                name: "${aws_frauddetector_entity_type.#{name}.name}",
                last_updated_time: "${aws_frauddetector_entity_type.#{name}.last_updated_time}",
                created_time: "${aws_frauddetector_entity_type.#{name}.created_time}"
              }
            )
          end

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
            resource = resource(:aws_frauddetector_event_type, name) do
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
            resource = resource(:aws_frauddetector_variable, name) do
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
            resource = resource(:aws_frauddetector_outcome, name) do
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