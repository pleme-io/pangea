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
  module Resources
    module AWS
      module Types
        # WAF v2 Default action configuration
        class WafV2DefaultAction < Dry::Struct
          transform_keys(&:to_sym)

          attribute :allow, Hash.schema(
            custom_request_handling?: Hash.schema(
              insert_headers: Array.of(Hash.schema(name: String, value: String))
            ).optional
          ).optional

          attribute :block, Hash.schema(
            custom_response?: Hash.schema(
              response_code: Integer.constrained(gteq: 200, lteq: 599),
              custom_response_body_key?: String.optional,
              response_headers?: Array.of(Hash.schema(name: String, value: String)).optional
            ).optional
          ).optional

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            action_types = %i[allow block]
            provided_actions = action_types.select { |type| attrs.key?(type) }

            raise Dry::Struct::Error, 'WAF v2 default action must specify either allow or block' if provided_actions.empty?

            raise Dry::Struct::Error, 'WAF v2 default action must specify either allow or block, not both' if provided_actions.size > 1

            super(attrs)
          end
        end
      end
    end
  end
end
