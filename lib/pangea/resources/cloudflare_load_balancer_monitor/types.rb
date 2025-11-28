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
    module Cloudflare
      module Types
        # Cloudflare Load Balancer Monitor resource attributes with validation
        class LoadBalancerMonitorAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :account_id, ::Pangea::Resources::Types::CloudflareAccountId
          attribute :type, ::Pangea::Resources::Types::CloudflareMonitorType
          attribute :expected_codes, ::Pangea::Resources::Types::CloudflareMonitorExpectedCodes.default('200')
          attribute :method, ::Pangea::Resources::Types::CloudflareMonitorMethod
          attribute :timeout, ::Pangea::Resources::Types::CloudflareMonitorTimeout.default(5)
          attribute :path, ::Pangea::Resources::Types::String.default('/')
          attribute :interval, ::Pangea::Resources::Types::CloudflareMonitorInterval.default(60)
          attribute :retries, ::Pangea::Resources::Types::CloudflareMonitorRetries.default(2)
          attribute :description, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :header, ::Pangea::Resources::Types::Hash.map(::Pangea::Resources::Types::String, ::Pangea::Resources::Types::Array.of(::Pangea::Resources::Types::String)).default({}.freeze)
          attribute :allow_insecure, ::Pangea::Resources::Types::Bool.default(false)
          attribute :follow_redirects, ::Pangea::Resources::Types::Bool.default(false)
          attribute :probe_zone, ::Pangea::Resources::Types::String.optional.default(nil)

          # Computed properties
          def is_http_monitor?
            %w[http https].include?(type)
          end

          def is_tcp_monitor?
            type == 'tcp'
          end

          def timeout_in_ms
            timeout * 1000
          end

          def has_custom_headers?
            header.any?
          end
        end
      end
    end
  end
end
