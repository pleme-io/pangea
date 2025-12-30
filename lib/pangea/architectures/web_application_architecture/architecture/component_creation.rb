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
    module WebApplicationArchitecture
      class Architecture
        # Component creation methods
        module ComponentCreation
          def create_components(name, attributes)
            extend Pangea::Components if defined?(Pangea::Components)

            components = {}
            components[:network] = create_network_component(name, attributes)
            components[:security_groups] = create_security_groups(name, attributes, components[:network])
            components[:load_balancer] = create_load_balancer(name, attributes, components[:network], components[:security_groups])
            components[:web_servers] = create_web_servers(name, attributes, components[:network], components[:security_groups], components[:load_balancer])
            components[:database] = create_database(name, attributes, components[:network], components[:security_groups]) if attributes[:database_enabled] != false
            components[:monitoring] = create_monitoring(name, attributes, components)
            components[:cache] = create_cache_component(name, attributes, components[:network], components[:security_groups]) if attributes[:enable_caching]
            components[:cdn] = create_cdn_component(name, attributes, components[:load_balancer]) if attributes[:enable_cdn]
            components
          end

          def create_network_component(name, attributes)
            if defined?(Pangea::Components) && respond_to?(:secure_vpc)
              secure_vpc(:"#{name}_network", {
                cidr_block: attributes[:vpc_cidr] || '10.0.0.0/16',
                availability_zones: attributes[:availability_zones] || %w[us-east-1a us-east-1b us-east-1c],
                enable_flow_logs: attributes[:environment] == 'production',
                tags: architecture_tags(attributes)
              })
            else
              create_vpc_directly(name, attributes)
            end
          end

          def create_security_groups(name, attributes, network)
            if defined?(Pangea::Components) && respond_to?(:web_security_group)
              web_security_group(:"#{name}_web_sg", {
                vpc_ref: network.respond_to?(:vpc) ? network.vpc : network,
                allowed_cidr_blocks: attributes[:allowed_cidr_blocks] || ['0.0.0.0/0'],
                tags: architecture_tags(attributes)
              })
            else
              create_security_groups_directly(name, attributes, network)
            end
          end

          def create_load_balancer(name, attributes, network, security_groups)
            if defined?(Pangea::Components) && respond_to?(:application_load_balancer)
              subnets = network.respond_to?(:public_subnets) ? network.public_subnets : []
              sg_refs = security_groups.respond_to?(:security_groups) ? security_groups.security_groups : [security_groups]

              application_load_balancer(:"#{name}_alb", {
                subnet_refs: subnets, security_group_refs: sg_refs,
                enable_deletion_protection: attributes[:environment] == 'production',
                certificate_arn: attributes[:ssl_certificate_arn],
                tags: architecture_tags(attributes)
              })
            else
              create_load_balancer_directly(name, attributes, network, security_groups)
            end
          end

          def create_web_servers(name, attributes, network, security_groups, load_balancer)
            if defined?(Pangea::Components) && respond_to?(:auto_scaling_web_servers)
              subnets = network.respond_to?(:private_subnets) ? network.private_subnets : []
              auto_scaling_web_servers(:"#{name}_web", {
                subnet_refs: subnets,
                target_group_ref: load_balancer.respond_to?(:target_group) ? load_balancer.target_group : nil,
                min_size: attributes[:auto_scaling][:min], max_size: attributes[:auto_scaling][:max],
                desired_capacity: attributes[:auto_scaling][:desired] || attributes[:auto_scaling][:min],
                instance_type: attributes[:instance_type] || 't3.medium',
                tags: architecture_tags(attributes)
              })
            else
              create_web_servers_directly(name, attributes, network, security_groups, load_balancer)
            end
          end

          def create_database(name, attributes, network, security_groups)
            engine = attributes[:database_engine] || 'mysql'

            if defined?(Pangea::Components)
              component_method = engine == 'postgresql' ? :postgresql_database : :mysql_database
              return create_database_directly(name, attributes, network, security_groups) unless respond_to?(component_method)

              subnets = network.respond_to?(:private_subnets) ? network.private_subnets : []
              vpc = network.respond_to?(:vpc) ? network.vpc : network

              send(component_method, :"#{name}_db", {
                subnet_refs: subnets, vpc_ref: vpc,
                instance_class: attributes[:database_instance_class] || 'db.t3.micro',
                allocated_storage: attributes[:database_allocated_storage] || 20,
                storage_encrypted: attributes[:environment] == 'production',
                backup_retention_days: attributes.dig(:backup, :retention_days) || (attributes[:environment] == 'production' ? 7 : 1),
                multi_az: attributes[:high_availability] && attributes[:environment] == 'production',
                tags: architecture_tags(attributes)
              })
            else
              create_database_directly(name, attributes, network, security_groups)
            end
          end

          def create_monitoring(name, attributes, components)
            monitoring_resources = {}
            monitoring_resources[:alarms] = create_cloudwatch_alarms(name, attributes, components) if attributes[:monitoring][:enable_alerting]
            monitoring_resources[:dashboard] = create_cloudwatch_dashboard(name, attributes, components) if attributes[:monitoring][:detailed_monitoring]
            monitoring_resources
          end

          def create_cache_component(name, attributes, network, security_groups)
            if defined?(Pangea::Components) && respond_to?(:elasticache_redis)
              subnets = network.respond_to?(:private_subnets) ? network.private_subnets : []
              elasticache_redis(:"#{name}_cache", { subnet_refs: subnets, node_type: 'cache.t3.micro', num_cache_nodes: 1, port: 6379, tags: architecture_tags(attributes) })
            else
              create_cache_directly(name, attributes, network, security_groups)
            end
          end

          def create_cdn_component(name, attributes, load_balancer)
            if defined?(Pangea::Components) && respond_to?(:cloudfront_distribution)
              cloudfront_distribution(:"#{name}_cdn", { origin_domain_name: load_balancer.respond_to?(:dns_name) ? load_balancer.dns_name : '', price_class: 'PriceClass_100', tags: architecture_tags(attributes) })
            else
              create_cdn_directly(name, attributes, load_balancer)
            end
          end
        end
      end
    end
  end
end
