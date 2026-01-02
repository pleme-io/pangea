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

require 'pangea/architectures/base'
require_relative 'microservices/types'
require_relative 'microservices/orchestration'
require_relative 'microservices/shared_services'
require_relative 'microservices/service_mesh'
require_relative 'microservices/observability'
require_relative 'microservices/platform_security'
require_relative 'microservices/service'
require_relative 'microservices/helpers'

module Pangea
  module Architectures
    module Patterns
      # Microservices Architecture - Service mesh platform with individual services
      module Microservices
        include Base
        include Orchestration
        include SharedServices
        include ServiceMesh
        include Observability
        include PlatformSecurity
        include Service
        include Helpers

        # Create a complete microservices platform
        def microservices_platform_architecture(name, attributes = {})
          platform_attrs = MicroservicesPlatformAttributes.new(attributes)
          arch_ref = create_architecture_reference('microservices_platform', name, platform_attrs.to_h)

          base_tags = architecture_tags(arch_ref, {
            Platform: platform_attrs.platform_name,
            Environment: platform_attrs.environment,
            ServiceMesh: platform_attrs.service_mesh
          }.merge(platform_attrs.tags))

          # Network foundation
          arch_ref.network = vpc_with_subnets(
            architecture_resource_name(name, :platform_network),
            vpc_cidr: platform_attrs.vpc_cidr,
            availability_zones: platform_attrs.availability_zones,
            attributes: {
              vpc_tags: base_tags.merge(Tier: 'network'),
              public_subnet_tags: base_tags.merge(Tier: 'public', Purpose: 'load-balancers'),
              private_subnet_tags: base_tags.merge(Tier: 'private', Purpose: 'services')
            }
          )

          # Container orchestration
          arch_ref.compute = create_orchestration_platform(name, arch_ref, platform_attrs, base_tags)

          # Shared services
          arch_ref.storage = create_shared_services(name, arch_ref, platform_attrs, base_tags)

          # Service mesh
          if platform_attrs.service_mesh != 'none'
            arch_ref.network[:service_mesh] = create_service_mesh(name, arch_ref, platform_attrs, base_tags)
          end

          # Observability
          arch_ref.monitoring = create_observability_stack(name, arch_ref, platform_attrs, base_tags)

          # Security
          arch_ref.security = create_security_services(name, arch_ref, platform_attrs, base_tags)

          arch_ref
        end

        # Create an individual microservice within the platform
        def microservice_architecture(name, platform_ref:, attributes: {})
          service_attrs = MicroserviceAttributes.new(attributes.merge(service_name: name.to_s))
          arch_ref = create_architecture_reference('microservice', name, service_attrs.to_h)

          base_tags = architecture_tags(arch_ref, {
            Service: service_attrs.service_name,
            Runtime: service_attrs.runtime,
            SecurityLevel: service_attrs.security_level,
            Platform: platform_ref.name.to_s
          }.merge(service_attrs.tags))

          # Database
          if service_attrs.database_type != 'none'
            arch_ref.database = create_service_database(name, arch_ref, platform_ref, service_attrs, base_tags)
          end

          # Compute
          arch_ref.compute = create_service_compute(name, arch_ref, platform_ref, service_attrs, base_tags)

          # Security
          arch_ref.security = create_service_security(name, arch_ref, platform_ref, service_attrs, base_tags)

          # Monitoring
          arch_ref.monitoring = create_service_monitoring(name, arch_ref, platform_ref, service_attrs, base_tags)

          arch_ref
        end
      end
    end
  end
end
