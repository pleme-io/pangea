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
      # E-commerce platform architecture example
      module EcommercePlatform
        def ecommerce_platform_architecture(name, attributes = {})
          platform_attrs = build_platform_attrs(name, attributes)

          web_app = create_web_app(name, platform_attrs)
          services_platform = create_services_platform(name, platform_attrs)
          services = create_microservices(name, services_platform)
          analytics_platform = create_analytics_platform(name, platform_attrs)

          build_composite_ref(name, platform_attrs, web_app, services_platform, services, analytics_platform)
        end

        private

        def build_platform_attrs(name, attributes)
          {
            domain: attributes[:domain] || "#{name}.com",
            environment: attributes[:environment] || 'production',
            high_availability: true,
            regions: attributes[:regions] || %w[us-east-1 us-west-2]
          }
        end

        def create_web_app(name, platform_attrs)
          web_application_architecture(
            :"#{name}_web",
            platform_attrs.merge({
              auto_scaling: { min: 3, max: 20 },
              database_engine: 'postgresql',
              cdn_enabled: true,
              waf_enabled: true
            })
          )
        end

        def create_services_platform(name, platform_attrs)
          microservices_platform_architecture(
            :"#{name}_services",
            platform_name: "#{name}-services",
            environment: platform_attrs[:environment],
            vpc_cidr: '10.1.0.0/16',
            service_mesh: 'istio',
            orchestrator: 'ecs',
            message_queue: 'sqs',
            shared_cache: true
          )
        end

        def create_microservices(name, services_platform)
          {
            user: microservice_architecture(:"#{name}_user_service", platform_ref: services_platform, attributes: { runtime: 'nodejs', database_type: 'postgresql', min_instances: 2, max_instances: 10, cache_enabled: true }),
            inventory: microservice_architecture(:"#{name}_inventory_service", platform_ref: services_platform, attributes: { runtime: 'java', database_type: 'postgresql', min_instances: 2, max_instances: 15, depends_on: ['user_service'] }),
            order: microservice_architecture(:"#{name}_order_service", platform_ref: services_platform, attributes: { runtime: 'golang', database_type: 'postgresql', min_instances: 3, max_instances: 20, security_level: 'high', depends_on: %w[user_service inventory_service] }),
            payment: microservice_architecture(:"#{name}_payment_service", platform_ref: services_platform, attributes: { runtime: 'java', database_type: 'postgresql', min_instances: 2, max_instances: 8, security_level: 'high', depends_on: %w[user_service order_service] })
          }
        end

        def create_analytics_platform(name, platform_attrs)
          data_lake_architecture(
            :"#{name}_analytics",
            data_lake_name: "#{name}-analytics",
            environment: platform_attrs[:environment],
            vpc_cidr: '10.2.0.0/16',
            data_sources: %w[rds kinesis s3],
            real_time_processing: true,
            batch_processing: true,
            data_warehouse: 'redshift',
            machine_learning: true,
            business_intelligence: true
          )
        end

        def build_composite_ref(name, platform_attrs, web_app, services_platform, services, analytics_platform)
          composite_ref = create_architecture_reference('ecommerce_platform', name, platform_attrs)
          composite_ref.web_application = web_app
          composite_ref.microservices_platform = services_platform
          composite_ref.services = services
          composite_ref.analytics = analytics_platform
          composite_ref
        end
      end
    end
  end
end
