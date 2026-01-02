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

require 'dry-types'
require_relative 'schemas'
require_relative 'actions'

module Pangea
  module Resources
    module AWS
      module Types
        # WAF v2 rule schema definition
        module WafV2RuleSchema
          include Dry.Types()

          # Complete rule schema
          RuleSchema = Hash.schema(
            name: String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/),
            priority: Integer.constrained(gteq: 0),
            action: WafV2Actions::ActionSchema,
            statement: Hash,
            visibility_config: WafV2Schemas::VisibilityConfigSchema,
            rule_labels?: Array.of(WafV2Schemas::RuleLabelSchema).optional,
            captcha_config?: WafV2Schemas::ImmunityTimeSchema,
            challenge_config?: WafV2Schemas::ImmunityTimeSchema
          )

          # Array of rules with empty default
          RulesArray = Array.of(RuleSchema).default([].freeze)

          # Custom response bodies map
          CustomResponseBodiesMap = Hash.map(
            String.constrained(format: /\A[a-zA-Z0-9_-]{1,64}\z/),
            WafV2Schemas::CustomResponseBodySchema
          ).default({}.freeze)
        end
      end
    end
  end
end
