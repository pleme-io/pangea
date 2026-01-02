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
        # WAF v2 Web ACL visibility configuration
        class WafV2VisibilityConfig < Dry::Struct
          transform_keys(&:to_sym)

          attribute :cloudwatch_metrics_enabled, Resources::Types::Bool
          attribute :metric_name, String.constrained(format: /\A[a-zA-Z0-9_-]{1,128}\z/)
          attribute :sampled_requests_enabled, Resources::Types::Bool
        end
      end
    end
  end
end
