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
      class CloudFrontCachePolicyAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :name, Resources::Types::String
        attribute :comment, Resources::Types::String.default('')
        attribute :default_ttl, Resources::Types::Integer.constrained(gteq: 0).default(86400)
        attribute :max_ttl, Resources::Types::Integer.constrained(gteq: 0).default(31536000)
        attribute :min_ttl, Resources::Types::Integer.constrained(gteq: 0).default(0)
        attribute :parameters_in_cache_key_and_forwarded_to_origin, Resources::Types::Hash.schema(
          enable_accept_encoding_brotli: Resources::Types::Bool.default(false),
          enable_accept_encoding_gzip: Resources::Types::Bool.default(false),
          headers_config: Resources::Types::Hash.schema(
            header_behavior: Resources::Types::String.enum('none', 'whitelist').default('none'),
            headers?: Resources::Types::Hash.schema(
              items?: Resources::Types::Array.of(Resources::Types::String).optional
            ).optional
          ).default({ header_behavior: 'none' }),
          query_strings_config: Resources::Types::Hash.schema(
            query_string_behavior: Resources::Types::String.enum('none', 'whitelist', 'allExcept', 'all').default('none'),
            query_strings?: Resources::Types::Hash.schema(
              items?: Resources::Types::Array.of(Resources::Types::String).optional
            ).optional
          ).default({ query_string_behavior: 'none' }),
          cookies_config: Resources::Types::Hash.schema(
            cookie_behavior: Resources::Types::String.enum('none', 'whitelist', 'allExcept', 'all').default('none'),
            cookies?: Resources::Types::Hash.schema(
              items?: Resources::Types::Array.of(Resources::Types::String).optional
            ).optional
          ).default({ cookie_behavior: 'none' })
        )
      end
    end
  end
end