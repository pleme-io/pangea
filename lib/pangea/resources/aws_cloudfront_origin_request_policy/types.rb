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
      class CloudFrontOriginRequestPolicyAttributes < Dry::Struct
        transform_keys(&:to_sym)
        
        attribute :name, Resources::Types::String
        attribute :comment, Resources::Types::String.default('')
        attribute :headers_config, Resources::Types::Hash.schema(
          header_behavior: Resources::Types::String.enum('none', 'whitelist', 'allViewer', 'allViewerAndWhitelistCloudFront').default('none'),
          headers?: Resources::Types::Hash.schema(
            items?: Resources::Types::Array.of(Resources::Types::String).optional
          ).optional
        ).default({ header_behavior: 'none' })
        attribute :query_strings_config, Resources::Types::Hash.schema(
          query_string_behavior: Resources::Types::String.enum('none', 'whitelist', 'all').default('none'),
          query_strings?: Resources::Types::Hash.schema(
            items?: Resources::Types::Array.of(Resources::Types::String).optional
          ).optional
        ).default({ query_string_behavior: 'none' })
        attribute :cookies_config, Resources::Types::Hash.schema(
          cookie_behavior: Resources::Types::String.enum('none', 'whitelist', 'all').default('none'),
          cookies?: Resources::Types::Hash.schema(
            items?: Resources::Types::Array.of(Resources::Types::String).optional
          ).optional
        ).default({ cookie_behavior: 'none' })
      end
    end
  end
end