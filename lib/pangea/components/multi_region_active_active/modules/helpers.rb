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
  module Components
    module MultiRegionActiveActive
      # Shared helper methods for multi-region active-active components
      module Helpers
        def extract_database_endpoints(resources)
          endpoints = {}

          return endpoints unless resources[:global_database]

          case resources[:global_database].type
          when 'aws_dynamodb_table'
            endpoints[:type] = 'dynamodb'
            endpoints[:table_name] = resources[:global_database].attributes[:name]
          when 'aws_rds_global_cluster'
            extract_aurora_endpoints(resources, endpoints)
          end

          endpoints
        end

        def estimate_multi_region_cost(attrs, resources)
          cost = 0.0
          cost += estimate_global_accelerator_cost(attrs)
          cost += estimate_route53_cost(attrs)
          cost += estimate_database_cost(attrs)
          cost += estimate_application_cost(attrs)
          cost += estimate_transit_gateway_cost(attrs)
          cost += estimate_monitoring_cost(attrs)
          cost += estimate_data_transfer_cost(attrs)
          cost.round(2)
        end

        def estimate_aurora_instance_cost(instance_class)
          instance_costs = {
            'db.r5.large' => 230.0,
            'db.r5.xlarge' => 460.0,
            'db.r5.2xlarge' => 920.0,
            'db.r6g.large' => 180.0,
            'db.r6g.xlarge' => 360.0
          }
          instance_costs[instance_class] || 200.0
        end

        private

        def extract_aurora_endpoints(resources, endpoints)
          endpoints[:type] = 'aurora'
          endpoints[:global_cluster] = resources[:global_database].id
          endpoints[:regional] = {}

          resources[:regional].each do |region, region_resources|
            next unless region_resources[:regional_cluster]

            endpoints[:regional][region] = {
              cluster_endpoint: region_resources[:regional_cluster][:cluster].endpoint,
              reader_endpoint: region_resources[:regional_cluster][:cluster].reader_endpoint
            }
          end
        end

        def estimate_global_accelerator_cost(attrs)
          return 0.0 unless attrs.enable_global_accelerator

          hourly_cost = 0.025 * 24 * 30
          data_processing = 0.015 * 1000
          hourly_cost + data_processing
        end

        def estimate_route53_cost(attrs)
          hosted_zone = 0.50
          health_checks = attrs.regions.length * 0.50
          hosted_zone + health_checks
        end

        def estimate_database_cost(attrs)
          case attrs.global_database.engine
          when 'dynamodb'
            estimate_dynamodb_cost(attrs)
          when 'aurora-mysql', 'aurora-postgresql'
            estimate_aurora_cost(attrs)
          else
            0.0
          end
        end

        def estimate_dynamodb_cost(attrs)
          base_cost = attrs.regions.length * 25
          storage_throughput = attrs.regions.length * 1.25 * 100
          base_cost + storage_throughput
        end

        def estimate_aurora_cost(attrs)
          cost = 0.0
          attrs.regions.each do |region|
            instance_count = region.is_primary ? 2 : 1
            cost += instance_count * estimate_aurora_instance_cost(attrs.global_database.instance_class)
            cost += 100 # Storage estimate
          end
          cost
        end

        def estimate_application_cost(attrs)
          return 0.0 unless attrs.application

          cost = 0.0
          attrs.regions.each do |_region|
            cost += 22.0 # ALB cost
            cost += estimate_fargate_cost(attrs)
          end
          cost
        end

        def estimate_fargate_cost(attrs)
          task_hours = attrs.application.desired_count * 24 * 30
          cpu_cost = (attrs.application.task_cpu / 1024.0) * 0.04048 * task_hours
          memory_cost = (attrs.application.task_memory / 1024.0) * 0.004445 * task_hours
          cpu_cost + memory_cost
        end

        def estimate_transit_gateway_cost(attrs)
          return 0.0 unless attrs.regions.length > 1

          tgw_cost = attrs.regions.length * 36
          peering_cost = attrs.regions.length * (attrs.regions.length - 1) * 20
          tgw_cost + peering_cost
        end

        def estimate_monitoring_cost(attrs)
          return 0.0 unless attrs.monitoring.enabled

          base_cost = attrs.regions.length * 15
          synthetic_cost = attrs.monitoring.synthetic_monitoring ? attrs.regions.length * 10 : 0
          base_cost + synthetic_cost
        end

        def estimate_data_transfer_cost(attrs)
          cross_region_gb = 500
          cross_region_gb * 0.02 * attrs.regions.length
        end

        def build_component_outputs(attrs, resources, regional_endpoints)
          {
            deployment_name: attrs.deployment_name, domain_name: attrs.domain_name,
            hosted_zone_id: resources[:hosted_zone].zone_id,
            regions: attrs.regions.map(&:region), primary_regions: attrs.regions.select(&:is_primary).map(&:region),
            consistency_model: attrs.consistency.consistency_model,
            conflict_resolution: attrs.consistency.conflict_resolution,
            global_accelerator_dns: resources[:global_accelerator]&.dns_name,
            global_accelerator_ips: resources[:global_accelerator]&.ip_sets&.map { |s| s[:ip_addresses] }&.flatten,
            regional_endpoints: regional_endpoints.map { |e| { region: e[:region], endpoint: e[:endpoint] } },
            database_engine: attrs.global_database.engine,
            database_endpoints: extract_database_endpoints(resources),
            features_enabled: build_features_list(attrs),
            estimated_monthly_cost: estimate_multi_region_cost(attrs, resources),
            health_status: build_health_status(attrs, regional_endpoints)
          }
        end

        def build_features_list(attrs)
          [
            ('Global Accelerator' if attrs.enable_global_accelerator),
            ('Circuit Breaker' if attrs.enable_circuit_breaker),
            ('Bulkhead Pattern' if attrs.enable_bulkhead_pattern),
            ('Chaos Engineering' if attrs.enable_chaos_engineering),
            ('Data Residency' if attrs.data_residency_enabled),
            ('Synthetic Monitoring' if attrs.monitoring.synthetic_monitoring),
            ('Anomaly Detection' if attrs.monitoring.anomaly_detection)
          ].compact
        end

        def build_health_status(attrs, regional_endpoints)
          { regions_healthy: regional_endpoints.length, total_regions: attrs.regions.length, failover_ready: attrs.failover.enabled }
        end
      end
    end
  end
end
