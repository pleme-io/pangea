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


require_relative 'entity_type'
require_relative 'event_type'
require_relative 'variable'
require_relative 'outcome'

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
          include EntityType
          include EventType
          include Variable
          include Outcome

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
            resource(:aws_frauddetector_detector, name) do
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
        end
      end
    end
  end
end
