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
require_relative 'types/schemas'
require_relative 'types/actions'
require_relative 'types/rule_schema'
require_relative 'types/validators'
require_relative 'types/computed'

module Pangea
  module Resources
    module AWS
      module Types
        # WAF v2 Rule Group attributes with validation
        class WafV2RuleGroupAttributes < Dry::Struct
          include Dry.Types()
          include WafV2ComputedProperties
          transform_keys(&:to_sym)

          attribute :name, String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/)
          attribute :scope, Resources::Types::WafV2Scope
          attribute :capacity, Resources::Types::WafV2CapacityUnits
          attribute :description, String.constrained(max_size: 256).optional
          attribute :rules, WafV2RuleSchema::RulesArray
          attribute :visibility_config, WafV2Schemas::VisibilityConfigSchema
          attribute :tags, Resources::Types::AwsTags
          attribute :custom_response_bodies, WafV2RuleSchema::CustomResponseBodiesMap

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            WafV2Validators.validate_attributes(attrs)
            super(attrs)
          end
        end
      end
    end
  end
end
