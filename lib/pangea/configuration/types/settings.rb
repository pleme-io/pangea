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

module Pangea
  module ConfigurationTypes
    module Types
      # Terraform Configuration
      class TerraformConfig < Dry::Struct
        attribute? :binary, BinaryPath.default('terraform')
        attribute? :version, Types::String.optional
        attribute? :workspace_prefix, Types::String.optional
        attribute? :plugin_cache_dir, Types::String.optional

        def to_h
          super.compact
        end
      end

      # Modules Configuration
      class ModulesConfig < Dry::Struct
        attribute? :path, PathString.optional
        attribute? :auto_install, Types::Bool.default(true)
        attribute? :registry_url, Types::String.optional

        def to_h
          super.compact
        end
      end

      # Cache Configuration
      class CacheConfig < Dry::Struct
        attribute? :directory, PathString.default('~/.pangea/cache')
        attribute? :ttl, Types::Integer.default(3600)
        attribute? :enabled, Types::Bool.default(true)

        def to_h
          super.compact
        end
      end
    end
  end
end
