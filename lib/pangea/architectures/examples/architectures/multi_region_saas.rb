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

module Pangea
  module Architectures
    module Examples
      # Multi-region SaaS platform architecture example
      module MultiRegionSaas
        def multi_region_saas_architecture(name, attributes = {})
          primary_region = attributes[:primary_region] || 'us-east-1'
          secondary_region = attributes[:secondary_region] || 'us-west-2'
          domain = attributes[:domain] || "#{name}.com"

          primary_app = create_primary_region_app(name, domain, primary_region)
          secondary_app = create_secondary_region_app(name, domain, secondary_region)
          global_analytics = create_global_analytics(name)

          composite_ref = create_architecture_reference('multi_region_saas', name, {
            primary_region: primary_region,
            secondary_region: secondary_region,
            domain: domain
          })

          composite_ref.primary_region = primary_app
          composite_ref.secondary_region = secondary_app
          composite_ref.global_analytics = global_analytics

          composite_ref
        end

        private

        def create_primary_region_app(name, domain, primary_region)
          web_application_architecture(
            :"#{name}_primary",
            domain: domain,
            environment: 'production',
            availability_zones: %W[#{primary_region}a #{primary_region}b #{primary_region}c],
            vpc_cidr: '10.0.0.0/16',
            high_availability: true,
            auto_scaling: { min: 5, max: 50 },
            database_engine: 'postgresql',
            database_backup_retention: 30,
            cdn_enabled: true,
            waf_enabled: true,
            monitoring_enabled: true
          )
        end

        def create_secondary_region_app(name, domain, secondary_region)
          web_application_architecture(
            :"#{name}_secondary",
            domain: "dr.#{domain}",
            environment: 'production',
            availability_zones: %W[#{secondary_region}a #{secondary_region}b],
            vpc_cidr: '10.10.0.0/16',
            high_availability: true,
            auto_scaling: { min: 2, max: 20 },
            database_engine: 'postgresql',
            database_backup_retention: 30,
            cdn_enabled: false,
            monitoring_enabled: true
          )
        end

        def create_global_analytics(name)
          streaming_data_architecture(
            :"#{name}_global_stream",
            stream_name: "#{name}-global-events",
            stream_type: 'kinesis',
            shard_count: 10,
            retention_hours: 168,
            stream_processing_framework: 'kinesis-analytics',
            output_destinations: %w[s3 elasticsearch],
            monitoring_enabled: true,
            alerting_enabled: true
          )
        end
      end
    end
  end
end
