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
      # Enrichment source configuration
      class EnrichmentSource < Dry::Struct
        transform_keys(&:to_sym)

        attribute :name, Types::String
        attribute :type, Types::String.enum('geoip', 'whois', 'dns', 'asn', 'reputation', 'sandbox', 'virustotal')
        attribute? :api_endpoint, Types::String.optional
        attribute? :api_key_secret_arn, Types::String.optional
        attribute? :enabled, Types::Bool.default(true)
        attribute? :cache_ttl, Types::Integer.default(86400)
      end
    end
  end
end
