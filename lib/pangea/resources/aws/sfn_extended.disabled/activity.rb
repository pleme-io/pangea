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
require 'pangea/resources/base'
require 'pangea/resources/reference'

module Pangea
  module Resources
    module AWS
      module SfnExtended
        # Step Functions activity for custom task processing
        class ActivityAttributes < Dry::Struct
          attribute :name, Types::String
          attribute :tags, Types::Hash.default({}.freeze)
        end

        # Step Functions activity reference
        class ActivityReference < ::Pangea::Resources::ResourceReference
          property :id
          property :name
          property :arn
          property :creation_date

          def activity_arn
            arn
          end

          def activity_name
            name
          end

          # Helper for worker polling
          def poll_url
            # Activities are polled via AWS SDK, not direct HTTP
            nil
          end

          # Determines if this activity can be used in state machines
          def usable_in_state_machine?
            !arn.nil? && !arn.empty?
          end
        end

        module Activity
          # Creates a Step Functions activity for custom task processing
          #
          # @param name [Symbol] The activity name
          # @param attributes [Hash] Activity configuration
          # @return [ActivityReference] Reference to the activity
          def aws_sfn_activity(name, attributes = {})
            activity_attrs = ActivityAttributes.new(attributes)
            
            synthesizer.resource :aws_sfn_activity, name do
              name activity_attrs.name
              tags activity_attrs.tags unless activity_attrs.tags.empty?
            end

            ActivityReference.new(name, :aws_sfn_activity, synthesizer, activity_attrs)
          end
        end
      end
    end
  end
end