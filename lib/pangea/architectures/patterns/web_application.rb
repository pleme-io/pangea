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

require_relative 'web_application/types'
require_relative 'web_application/security_tier'
require_relative 'web_application/storage_tier'
require_relative 'web_application/database_tier'
require_relative 'web_application/compute_tier'
require_relative 'web_application/load_balancer_tier'
require_relative 'web_application/monitoring_tier'
require_relative 'web_application/user_data'

module Pangea
  module Architectures
    module Patterns
      # Web Application Architecture - Complete 3-tier web application
      module WebApplication
        include Base
        include SecurityTier
        include StorageTier
        include DatabaseTier
        include ComputeTier
        include LoadBalancerTier
        include MonitoringTier
        include UserData

        # Create a complete web application architecture
        #
        # @param name [Symbol] Architecture name
        # @param attributes [Hash] Architecture configuration
        # @return [ArchitectureReference] Complete architecture reference
        def web_application_architecture(name, attributes = {})
          arch_attrs = Attributes.new(attributes)
          arch_ref = create_architecture_reference('web_application', name, architecture_attributes: arch_attrs.to_h)

          base_tags = architecture_tags(arch_ref, {
                                          Domain: arch_attrs.domain,
                                          Environment: arch_attrs.environment
                                        }.merge(arch_attrs.tags))

          create_all_tiers(name, arch_ref, arch_attrs, base_tags)

          arch_ref
        end

        private

        def create_all_tiers(name, arch_ref, arch_attrs, base_tags)
          arch_ref.network = vpc_with_subnets(
            architecture_resource_name(name, :network),
            vpc_cidr: arch_attrs.vpc_cidr,
            availability_zones: arch_attrs.availability_zones,
            attributes: {
              vpc_tags: base_tags.merge(Tier: 'network'),
              public_subnet_tags: base_tags.merge(Tier: 'public'),
              private_subnet_tags: base_tags.merge(Tier: 'private')
            }
          )

          arch_ref.security = create_security_tier(name, arch_ref, arch_attrs, base_tags)

          arch_ref.storage = create_storage_tier(name, arch_ref, arch_attrs, base_tags) if arch_attrs.s3_bucket_enabled

          arch_ref.database = create_database_tier(name, arch_ref, arch_attrs, base_tags) if arch_attrs.database_enabled

          arch_ref.compute = create_compute_tier(name, arch_ref, arch_attrs, base_tags)
          arch_ref.compute[:load_balancer] = create_load_balancer_tier(name, arch_ref, arch_attrs, base_tags)

          return unless arch_attrs.monitoring_enabled

          arch_ref.monitoring = create_monitoring_tier(name, arch_ref, arch_attrs, base_tags)
        end
      end
    end
  end
end

# Auto-register when loaded
require 'pangea/architecture_registry'
Pangea::ArchitectureRegistry.register_architecture(Pangea::Architectures::Patterns::WebApplication)
