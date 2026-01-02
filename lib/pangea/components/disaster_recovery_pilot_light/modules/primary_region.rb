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
    module DisasterRecoveryPilotLight
      # Primary region infrastructure setup
      module PrimaryRegion
        def setup_primary_region(name, attrs, tags)
          primary = attrs.primary_region
          primary_resources = {}

          primary_resources[:vpc] = create_primary_vpc(name, primary, tags)
          primary_resources[:subnets] = create_primary_subnets(name, primary, primary_resources[:vpc], tags)

          if primary.critical_resources.any?
            primary_resources[:critical_monitors] = create_critical_monitors(
              name, primary, tags
            )
          end

          primary_resources
        end

        private

        def create_primary_vpc(name, primary, tags)
          primary.vpc_ref || aws_vpc(
            component_resource_name(name, :primary_vpc),
            {
              cidr_block: primary.vpc_cidr,
              enable_dns_hostnames: true,
              enable_dns_support: true,
              tags: tags.merge(
                Region: primary.region,
                Role: "Primary"
              )
            }
          )
        end

        def create_primary_subnets(name, primary, vpc_ref, tags)
          subnets = {}

          primary.availability_zones.each_with_index do |az, index|
            base_ip = primary.vpc_cidr.split('.')[0..1].join('.')

            subnets["public_#{index}".to_sym] = create_public_subnet(
              name, :primary_public_subnet, vpc_ref, base_ip, az, index, primary.region, tags
            )

            subnets["private_#{index}".to_sym] = create_private_subnet(
              name, :primary_private_subnet, vpc_ref, base_ip, az, index, primary.region, tags
            )
          end

          subnets
        end

        def create_public_subnet(name, prefix, vpc_ref, base_ip, az, index, region, tags)
          aws_subnet(
            component_resource_name(name, prefix, "az#{index}".to_sym),
            {
              vpc_id: vpc_ref.id,
              cidr_block: "#{base_ip}.#{index * 2}.0/24",
              availability_zone: az,
              map_public_ip_on_launch: true,
              tags: tags.merge(Type: "Public", Region: region)
            }
          )
        end

        def create_private_subnet(name, prefix, vpc_ref, base_ip, az, index, region, tags)
          aws_subnet(
            component_resource_name(name, prefix, "az#{index}".to_sym),
            {
              vpc_id: vpc_ref.id,
              cidr_block: "#{base_ip}.#{index * 2 + 1}.0/24",
              availability_zone: az,
              tags: tags.merge(Type: "Private", Region: region)
            }
          )
        end

        def create_critical_monitors(name, primary, tags)
          critical_monitors = {}

          primary.critical_resources.each_with_index do |resource, index|
            next unless resource[:type] == 'database'

            critical_monitors["db_#{index}".to_sym] = create_db_health_alarm(
              name, resource, index, tags
            )
          end

          critical_monitors
        end

        def create_db_health_alarm(name, resource, index, tags)
          aws_cloudwatch_metric_alarm(
            component_resource_name(name, :primary_db_alarm, "resource#{index}".to_sym),
            {
              alarm_name: "#{name}-primary-db-#{resource[:id]}-health",
              comparison_operator: "LessThanThreshold",
              evaluation_periods: "2",
              metric_name: "DatabaseConnections",
              namespace: "AWS/RDS",
              period: "300",
              statistic: "Average",
              threshold: "1",
              alarm_description: "Primary database health check",
              dimensions: {
                DBInstanceIdentifier: resource[:id]
              },
              tags: tags
            }
          )
        end
      end
    end
  end
end
