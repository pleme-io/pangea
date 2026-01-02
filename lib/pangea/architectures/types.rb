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
require 'dry-types'

module Pangea
  module Architectures
    # Types module provides type definitions, configuration schemas,
    # validators, and defaults for architecture configurations.
    #
    # This module is split into logical sub-modules:
    # - base_types: Basic type definitions (Environment, Region, etc.)
    # - config_schemas: Hash schema types (AutoScalingConfig, SecurityConfig, etc.)
    # - validators: Validation and coercion helper methods
    # - defaults: Default configuration constants for environments
    module Types
      include Dry.Types()
    end
  end
end

# Load sub-types in order of dependency
# base_types must be loaded first as config_schemas depends on it
require_relative 'types/base_types'
require_relative 'types/config_schemas'
require_relative 'types/validators'
require_relative 'types/defaults'
