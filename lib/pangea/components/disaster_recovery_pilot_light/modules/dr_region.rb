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

require 'base64'

module Pangea
  module Components
    module DisasterRecoveryPilotLight
      # DR region pilot light infrastructure setup
      module DrRegion
        def setup_dr_region(name, attrs, tags)
          dr = attrs.dr_region
          dr_resources = {}

          dr_resources[:vpc] = create_dr_vpc(name, dr, tags)
          dr_resources[:subnets] = create_dr_subnets(name, dr, dr_resources[:vpc], tags)

          if attrs.pilot_light.minimal_compute
            create_dr_compute_resources(name, attrs, dr_resources, tags)
          end

          if attrs.pilot_light.database_replicas
            dr_resources[:db_subnet_group] = create_dr_db_subnet_group(
              name, dr, dr_resources[:subnets], tags
            )
          end

          dr_resources
        end

        private

        def create_dr_vpc(name, dr, tags)
          dr.vpc_ref || aws_vpc(
            component_resource_name(name, :dr_vpc),
            {
              cidr_block: dr.vpc_cidr,
              enable_dns_hostnames: true,
              enable_dns_support: true,
              tags: tags.merge(
                Region: dr.region,
                Role: "DR",
                State: "PilotLight"
              )
            }
          )
        end

        def create_dr_subnets(name, dr, vpc_ref, tags)
          subnets = {}

          dr.availability_zones.each_with_index do |az, index|
            base_ip = dr.vpc_cidr.split('.')[0..1].join('.')

            subnets["public_#{index}".to_sym] = aws_subnet(
              component_resource_name(name, :dr_public_subnet, "az#{index}".to_sym),
              {
                vpc_id: vpc_ref.id,
                cidr_block: "#{base_ip}.#{index * 2}.0/24",
                availability_zone: az,
                map_public_ip_on_launch: true,
                tags: tags.merge(Type: "Public", Region: dr.region, State: "PilotLight")
              }
            )

            subnets["private_#{index}".to_sym] = aws_subnet(
              component_resource_name(name, :dr_private_subnet, "az#{index}".to_sym),
              {
                vpc_id: vpc_ref.id,
                cidr_block: "#{base_ip}.#{index * 2 + 1}.0/24",
                availability_zone: az,
                tags: tags.merge(Type: "Private", Region: dr.region, State: "PilotLight")
              }
            )
          end

          subnets
        end

        def create_dr_compute_resources(name, attrs, dr_resources, tags)
          dr_resources[:launch_template] = create_dr_launch_template(name, attrs, tags)
          dr_resources[:asg] = create_dr_asg(name, attrs, dr_resources, tags)
        end

        def create_dr_launch_template(name, attrs, tags)
          aws_launch_template(
            component_resource_name(name, :dr_launch_template),
            {
              name: "#{name}-dr-template",
              description: "DR activation launch template",
              image_id: "ami-12345678",
              instance_type: attrs.pilot_light.standby_instance_type,
              vpc_security_group_ids: [],
              user_data: Base64.encode64(generate_dr_userdata(attrs)),
              tag_specifications: [{
                resource_type: "instance",
                tags: tags.merge(State: "DR-Activated")
              }],
              metadata_options: {
                http_tokens: "required",
                http_put_response_hop_limit: 1
              },
              tags: tags.merge(State: "PilotLight")
            }
          )
        end

        def create_dr_asg(name, attrs, dr_resources, tags)
          private_subnet_ids = dr_resources[:subnets]
            .select { |k, _| k.to_s.start_with?('private_') }
            .values
            .map(&:id)

          aws_autoscaling_group(
            component_resource_name(name, :dr_asg),
            {
              name: "#{name}-dr-asg",
              min_size: 0,
              max_size: attrs.pilot_light.auto_scaling_max,
              desired_capacity: 0,
              launch_template: {
                id: dr_resources[:launch_template].id,
                version: "$Latest"
              },
              vpc_zone_identifier: private_subnet_ids,
              health_check_type: "ELB",
              health_check_grace_period: 300,
              tags: [
                { key: "Name", value: "#{name}-dr-instance", propagate_at_launch: true },
                { key: "State", value: "PilotLight", propagate_at_launch: true }
              ]
            }
          )
        end

        def create_dr_db_subnet_group(name, dr, subnets, tags)
          private_subnet_ids = subnets
            .select { |k, _| k.to_s.start_with?('private_') }
            .values
            .map(&:id)

          aws_db_subnet_group(
            component_resource_name(name, :dr_db_subnet_group),
            {
              name: "#{name}-dr-db-subnet-group",
              description: "DR database subnet group",
              subnet_ids: private_subnet_ids,
              tags: tags.merge(Region: dr.region, State: "PilotLight")
            }
          )
        end
      end
    end
  end
end
