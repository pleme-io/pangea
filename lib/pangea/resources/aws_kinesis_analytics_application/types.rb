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

require_relative 'types/configs'
require_relative 'types/sql_configs'
require_relative 'types/validation'
require_relative 'types/computed'

module Pangea
  module Resources
    module AWS
      module Types
        # Kinesis Analytics Application resource attributes with validation
        class KinesisAnalyticsApplicationAttributes < Dry::Struct
          include Computed

          transform_keys(&:to_sym)

          RUNTIME_ENVIRONMENTS = %w[SQL-1_0 FLINK-1_6 FLINK-1_8 FLINK-1_11 FLINK-1_13 FLINK-1_15 FLINK-1_18].freeze

          # Core attributes
          attribute :name, String
          attribute :description, String.optional
          attribute :service_execution_role, String
          attribute :runtime_environment, String.enum(*RUNTIME_ENVIRONMENTS)
          attribute :start_application, Bool.default(false)
          attribute :tags, Resources::Types::AwsTags

          # Application configuration with nested types from sub-modules
          attribute :application_configuration, Hash.schema(
            application_code_configuration?: Configs::ApplicationCodeConfiguration.optional,
            flink_application_configuration?: Configs::FlinkApplicationConfiguration.optional,
            sql_application_configuration?: SqlConfigs::SqlApplicationConfiguration.optional,
            environment_properties?: Configs::EnvironmentProperties.optional,
            vpc_configuration?: Configs::VpcConfiguration.optional
          ).optional

          # Custom validation
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            Validation.validate_attributes(attrs)
            super(attrs)
          end
        end
      end
    end
  end
end
