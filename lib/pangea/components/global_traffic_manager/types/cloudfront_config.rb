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
    module GlobalTrafficManager
      # CloudFront distribution configuration
      class CloudFrontConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enabled, Types::Bool.default(true)
        attribute :price_class, Types::String.default('PriceClass_All')
        attribute :cache_behaviors, Types::Array.of(Types::Hash).default([].freeze)
        attribute :origin_shield_enabled, Types::Bool.default(false)
        attribute :origin_shield_region, Types::String.optional
        attribute :compress, Types::Bool.default(true)
        attribute :viewer_protocol_policy, Types::String.default('redirect-to-https')
        attribute :custom_error_responses, Types::Array.of(Types::Hash).default([].freeze)
      end
    end
  end
end
