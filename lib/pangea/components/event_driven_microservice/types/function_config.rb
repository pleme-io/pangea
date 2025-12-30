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
    module EventDrivenMicroservice
      # Make Types available in this namespace
      Types = Pangea::Resources::Types unless const_defined?(:Types)

      # Lambda function configuration
      class FunctionConfig < Dry::Struct
        transform_keys(&:to_sym)

        attribute :runtime, Types::String.default("python3.9")
        attribute :handler, Types::String
        attribute :timeout, Types::Integer.default(60)
        attribute :memory_size, Types::Integer.default(512)
        attribute :environment_variables, Types::Hash.default({}.freeze)
        attribute :layers, Types::Array.of(Types::String).default([].freeze)
        attribute :reserved_concurrent_executions, Types::Integer.optional
        attribute :dead_letter_config_arn, Types::String.optional
      end
    end
  end
end
