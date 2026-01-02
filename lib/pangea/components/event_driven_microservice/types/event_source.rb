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
  module Components
    module EventDrivenMicroservice
      # Make Types available in this namespace
      Types = Pangea::Resources::Types unless const_defined?(:Types)

      # Event source configuration
      class EventSource < Dry::Struct
        transform_keys(&:to_sym)

        attribute :type, Types::String.enum('EventBridge', 'SQS', 'SNS', 'Kinesis', 'DynamoDB')
        attribute :source_arn, Types::String.optional
        attribute :source_ref, Types::ResourceReference.optional
        attribute :event_pattern, Types::Hash.optional
        attribute :batch_size, Types::Integer.default(10)
        attribute :maximum_batching_window, Types::Integer.default(0)
        attribute :starting_position, Types::String.enum('TRIM_HORIZON', 'LATEST').optional
        attribute :parallelization_factor, Types::Integer.default(1)
        attribute :maximum_retry_attempts, Types::Integer.default(3)
        attribute :on_failure_destination_arn, Types::String.optional
      end
    end
  end
end
