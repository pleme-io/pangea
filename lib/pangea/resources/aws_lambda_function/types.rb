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
require_relative 'types/validators'
require_relative 'types/helpers'

module Pangea
  module Resources
    module AWS
      module Types
        # Lambda function attributes with validation
        class LambdaFunctionAttributes < Dry::Struct
          include LambdaHelpers
          transform_keys(&:to_sym)

          attribute :function_name, Pangea::Resources::Types::String.constrained(min_size: 1, max_size: 64, format: /\A[a-zA-Z0-9_-]+\z/)
          attribute :role, Pangea::Resources::Types::String
          attribute :handler, Pangea::Resources::Types::String
          attribute :runtime, Pangea::Resources::Types::LambdaRuntime
          attribute :filename, Pangea::Resources::Types::String.optional
          attribute :s3_bucket, Pangea::Resources::Types::String.optional
          attribute :s3_key, Pangea::Resources::Types::String.optional
          attribute :s3_object_version, Pangea::Resources::Types::String.optional
          attribute :image_uri, Pangea::Resources::Types::String.optional
          attribute :description, Pangea::Resources::Types::String.optional.default(nil)
          attribute :timeout, Pangea::Resources::Types::LambdaTimeout.default(3)
          attribute :memory_size, Pangea::Resources::Types::LambdaMemory.default(128)
          attribute :publish, Pangea::Resources::Types::Bool.default(false)
          attribute :reserved_concurrent_executions, Pangea::Resources::Types::LambdaReservedConcurrency.optional
          attribute :layers, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::String).default([].freeze)
          attribute :architectures, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::LambdaArchitecture).default(['x86_64'].freeze)
          attribute :package_type, Pangea::Resources::Types::LambdaPackageType.default('Zip')
          attribute :environment, Pangea::Resources::Types::Hash.schema(variables?: Pangea::Resources::Types::LambdaEnvironmentVariables.optional).optional
          attribute :vpc_config, Pangea::Resources::Types::LambdaVpcConfig.optional
          attribute :dead_letter_config, Pangea::Resources::Types::LambdaDeadLetterConfig.optional
          attribute :file_system_config, Pangea::Resources::Types::Array.of(Pangea::Resources::Types::LambdaFileSystemConfig).default([].freeze)
          attribute :tracing_config, Pangea::Resources::Types::Hash.schema(mode: Pangea::Resources::Types::LambdaTracingMode).optional
          attribute :kms_key_arn, Pangea::Resources::Types::String.optional
          attribute :image_config, Pangea::Resources::Types::LambdaImageConfig.optional
          attribute :code_signing_config_arn, Pangea::Resources::Types::String.optional
          attribute :ephemeral_storage, Pangea::Resources::Types::LambdaEphemeralStorage.optional
          attribute :snap_start, Pangea::Resources::Types::LambdaSnapStart.optional
          attribute :logging_config, Pangea::Resources::Types::Hash.schema(
            log_format?: Pangea::Resources::Types::String.constrained(included_in: %w[JSON Text]).optional,
            log_group?: Pangea::Resources::Types::String.optional,
            system_log_level?: Pangea::Resources::Types::String.constrained(included_in: %w[DEBUG INFO WARN]).optional,
            application_log_level?: Pangea::Resources::Types::String.constrained(included_in: %w[TRACE DEBUG INFO WARN ERROR FATAL]).optional
          ).optional
          attribute :tags, Pangea::Resources::Types::AwsTags

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            LambdaValidators.validate_package_type(attrs)
            LambdaValidators.validate_handler_format(attrs[:handler], attrs[:runtime]) if attrs[:handler] && attrs[:runtime]
            LambdaValidators.validate_snap_start(attrs)
            LambdaValidators.validate_architectures(attrs)
            super(attrs)
          end
        end
      end
    end
  end
end
