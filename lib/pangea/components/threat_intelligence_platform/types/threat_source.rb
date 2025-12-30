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
    module ThreatIntelligencePlatform
      # Authentication configuration for threat sources
      class ThreatSourceAuthentication < Dry::Struct
        transform_keys(&:to_sym)

        attribute :type, Types::String.enum('none', 'api_key', 'oauth', 'basic')
        attribute? :credentials_secret_arn, Types::String.optional
      end

      # Threat intelligence source configuration
      class ThreatSource < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :type, Types::String.enum('osint', 'commercial', 'government', 'custom', 'community')
        attribute :category, Types::String.enum('ip', 'domain', 'url', 'hash', 'email', 'cve', 'ttp', 'ioc')
        attribute? :source_url, Types::String.optional
        attribute? :api_endpoint, Types::String.optional
        attribute? :api_key_secret_arn, Types::String.optional
        attribute :format, Types::String.enum('stix', 'taxii', 'json', 'csv', 'xml', 'misp').default('json')
        attribute :polling_interval, Types::Integer.default(3600).constrained(gteq: 300)
        attribute? :confidence_threshold, Types::Integer.default(70).constrained(gteq: 0, lteq: 100)
        attribute? :enabled, Types::Bool.default(true)
        attribute? :authentication, ThreatSourceAuthentication.optional
      end
    end
  end
end
