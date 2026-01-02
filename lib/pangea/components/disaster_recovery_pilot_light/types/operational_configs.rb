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
    module DisasterRecoveryPilotLight
      # Make Types available in this namespace
      Types = Pangea::Resources::Types unless const_defined?(:Types)

      # Activation configuration
      class ActivationConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :activation_method, Types::String.default('semi-automated').enum('manual', 'automated', 'semi-automated')
        attribute :health_check_threshold, Types::Integer.default(3)
        attribute :activation_timeout, Types::Integer.default(900)
        attribute :pre_activation_checks, Types::Array.of(Types::Hash).default([].freeze)
        attribute :post_activation_validation, Types::Array.of(Types::Hash).default([].freeze)
        attribute :notification_channels, Types::Array.of(Types::ResourceReference).default([].freeze)
      end

      # Testing configuration
      class TestingConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :test_schedule, Types::String.default('cron(0 10 ? * SUN *)')
        attribute :test_scenarios, Types::Array.of(Types::String).default(['failover', 'data_recovery'].freeze)
        attribute :automated_testing, Types::Bool.default(true)
        attribute :test_notification_enabled, Types::Bool.default(true)
        attribute :rollback_after_test, Types::Bool.default(true)
        attribute :test_data_subset, Types::Bool.default(true)
      end
    end
  end
end
