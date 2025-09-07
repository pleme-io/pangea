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


require "dry-struct"
require "pangea/types"

module Pangea
  module Resources
    module AwsGameliftGameSessionQueue
      module Types
        # Player latency policy for queue
        class PlayerLatencyPolicy < Dry::Struct
          attribute :maximum_individual_player_latency_milliseconds, Pangea::Types::Integer
          attribute :policy_duration_seconds?, Pangea::Types::Integer
        end

        # Destination for game sessions
        class Destination < Dry::Struct
          attribute :destination_arn, Pangea::Types::String
        end

        # Filter configuration for fleet selection
        class FilterConfiguration < Dry::Struct
          attribute :allowed_locations?, Pangea::Types::Array.of(Pangea::Types::String)
        end

        # Priority configuration for destinations
        class PriorityConfiguration < Dry::Struct
          attribute :location_order?, Pangea::Types::Array.of(Pangea::Types::String)
          attribute :priority_order?, Pangea::Types::Array.of(Pangea::Types::String.enum("COST", "DESTINATION", "LATENCY", "LOCATION"))
        end

        # Main attributes for GameLift game session queue
        class Attributes < Dry::Struct
          # Required attributes
          attribute :name, Pangea::Types::String
          
          # Optional attributes
          attribute :timeout_in_seconds?, Pangea::Types::Integer.constrained(gteq: 10, lteq: 43200)
          attribute :destinations?, Pangea::Types::Array.of(Destination)
          attribute :player_latency_policies?, Pangea::Types::Array.of(PlayerLatencyPolicy)
          attribute :custom_event_data?, Pangea::Types::String.constrained(max_size: 256)
          attribute :notification_target?, Pangea::Types::String
          attribute :filter_configuration?, FilterConfiguration
          attribute :priority_configuration?, PriorityConfiguration
          attribute :tags?, Pangea::Types::Hash.map(Pangea::Types::String, Pangea::Types::String)

          def self.from_dynamic(d)
            d = Pangea::Types::Hash[d]
            new(
              name: d.fetch(:name),
              timeout_in_seconds: d[:timeout_in_seconds],
              destinations: d[:destinations]&.map { |dest| 
                dest.is_a?(Hash) ? Destination.new(dest) : Destination.new(destination_arn: dest)
              },
              player_latency_policies: d[:player_latency_policies]&.map { |p| PlayerLatencyPolicy.from_dynamic(p) },
              custom_event_data: d[:custom_event_data],
              notification_target: d[:notification_target],
              filter_configuration: d[:filter_configuration] ? FilterConfiguration.from_dynamic(d[:filter_configuration]) : nil,
              priority_configuration: d[:priority_configuration] ? PriorityConfiguration.from_dynamic(d[:priority_configuration]) : nil,
              tags: d[:tags]
            )
          end
        end

        # Reference for GameLift game session queue resources
        class Reference < Dry::Struct
          attribute :arn, Pangea::Types::String
          attribute :name, Pangea::Types::String
        end
      end
    end
  end
end