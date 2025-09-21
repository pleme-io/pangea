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
      class IotSecurityProfileAttributes < Dry::Struct
        attribute :security_profile_name, Resources::Types::IotSecurityProfileName
        attribute :security_profile_description, Resources::Types::String.optional
        attribute :behaviors, Resources::Types::Array.of(Types::Hash).default([].freeze)
        attribute :alert_targets, Resources::Types::Hash.optional
        attributeadditional_metrics_to_retain_v2 :, Resources::Types::Array.of(Types::Hash).optional
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)
        
        def behavior_count
          behaviors.length
        end
        
        def has_alert_targets?
          !alert_targets.nil? && alert_targets.any?
        end
        
        def metric_count
          additional_metrics_to_retain_v2&.length || 0
        end
        
        def security_coverage_score
          # Calculate coverage based on behaviors and metrics
          base_score = [behavior_count * 10, 100].min
          alert_bonus = has_alert_targets? ? 20 : 0
          metric_bonus = [metric_count * 5, 30].min
          
          [base_score + alert_bonus + metric_bonus, 100].min
        end
      end
    end
  end
end