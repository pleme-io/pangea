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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      class IotDeviceDefenderSecurityProfileAttributes < Dry::Struct
        attribute :security_profile_name, Resources::Types::IotSecurityProfileName
        attribute :security_profile_description, Resources::Types::String.optional
        attribute :behaviors, Resources::Types::Array.of(Types::Hash).default([].freeze)
        attribute :alert_targets, Resources::Types::Hash.optional
        attribute :target_arns, Resources::Types::Array.of(Types::String).default([].freeze)
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)
        
        def target_count
          target_arns.length
        end
        
        def behavior_count
          behaviors.length
        end
        
        def has_ml_behaviors?
          behaviors.any? { |b| b.dig(:criteria, :ml_detection_config) }
        end
        
        def defender_coverage_level
          if behavior_count >= 5 && has_ml_behaviors?
            'comprehensive'
          elsif behavior_count >= 3
            'standard'
          elsif behavior_count >= 1
            'basic'
          else
            'minimal'
          end
        end
      end
    end
  end
end