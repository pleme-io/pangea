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
require 'pangea/components/types'

module Pangea
  module Components
    module SiemSecurityPlatform
      # Security configuration
      class SecurityConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enable_encryption_at_rest, Types::Bool.default(true)
        attribute :kms_key_id, Types::String.optional
        attribute :enable_encryption_in_transit, Types::Bool.default(true)
        attribute :enable_fine_grained_access, Types::Bool.default(true)
        attribute :master_user_arn, Types::String.optional
        attribute :enable_audit_logs, Types::Bool.default(true)
        attribute :enable_slow_logs, Types::Bool.default(true)
      end

      # Scaling configuration
      class ScalingConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :enable_auto_scaling, Types::Bool.default(true)
        attribute :min_instances, Types::Integer.default(3)
        attribute :max_instances, Types::Integer.default(10)
        attribute :target_cpu_utilization, Types::Integer.default(70).constrained(gteq: 10, lteq: 90)
        attribute :scale_up_cooldown, Types::Integer.default(300)
        attribute :scale_down_cooldown, Types::Integer.default(900)
      end
    end
  end
end
