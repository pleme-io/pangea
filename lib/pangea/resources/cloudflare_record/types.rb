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
        # SRV record data schema
        SrvData = ::Pangea::Resources::Types::Hash.schema(
          service?: ::Pangea::Resources::Types::String.optional,
          proto?: ::Pangea::Resources::Types::String.optional,
          name?: ::Pangea::Resources::Types::String.optional,
          priority?: ::Pangea::Resources::Types::CloudflarePriority.optional,
          weight?: ::Pangea::Resources::Types::Integer.constrained(gteq: 0, lteq: 65535).optional,
          port?: ::Pangea::Resources::Types::Port.optional,
          target?: ::Pangea::Resources::Types::String.optional
        )

        # Cloudflare DNS Record resource attributes with validation
        class RecordAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :zone_id, ::Pangea::Resources::Types::CloudflareZoneId
          attribute :name, ::Pangea::Resources::Types::String
          attribute :type, ::Pangea::Resources::Types::CloudflareDnsRecordType
          attribute :value, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :ttl, ::Pangea::Resources::Types::CloudflareTtl.default(1)
          attribute :priority, ::Pangea::Resources::Types::CloudflarePriority.optional.default(nil)
          attribute :proxied, ::Pangea::Resources::Types::CloudflareProxied
          attribute :data, SrvData.optional.default(nil)
          attribute :comment, ::Pangea::Resources::Types::String.optional.default(nil)
          attribute :tags, ::Pangea::Resources::Types::CloudflareTags

          # Custom validation for record-specific requirements
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}

            # Validate MX records have priority
            if attrs[:type] == 'MX' && !attrs[:priority]
              raise Dry::Struct::Error, "MX records require a priority value"
            end

            # Validate SRV records have data
            if attrs[:type] == 'SRV' && !attrs[:data]
              raise Dry::Struct::Error, "SRV records require data attribute with service, proto, name, priority, weight, port, and target"
            end

            # Validate that proxied is only used with compatible record types
            if attrs[:proxied] && !%w[A AAAA CNAME].include?(attrs[:type])
              raise Dry::Struct::Error, "Proxied (orange cloud) can only be used with A, AAAA, and CNAME records"
            end

            # Validate TTL for proxied records
            if attrs[:proxied] && attrs[:ttl] && attrs[:ttl] != 1
              raise Dry::Struct::Error, "Proxied records must use TTL=1 (automatic)"
            end

            super(attrs)
          end

          # Computed properties
          def is_proxied?
            proxied
          end

          def is_root_domain?
            # Check if name is @ or matches zone
            name == '@'
          end

          def requires_priority?
            %w[MX SRV].include?(type)
          end

          def can_be_proxied?
            %w[A AAAA CNAME].include?(type)
          end

          def is_txt_record?
            type == 'TXT'
          end

          def is_mx_record?
            type == 'MX'
          end

          def is_srv_record?
            type == 'SRV'
          end

          def is_caa_record?
            type == 'CAA'
          end
        end
      end
    end
  end
end
