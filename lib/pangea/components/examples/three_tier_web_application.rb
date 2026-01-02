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

require 'pangea/components'

module Pangea
  module Components
    module Examples
      # Simple 3-tier web application example
      module ThreeTierWebApplication
        def three_tier_web_application_example
          template :web_application do
            include Pangea::Resources::AWS
            include Pangea::Components

            vpc = create_vpc
            subnets = create_subnets(vpc)
            security_groups = create_security_groups(vpc, subnets)

            load_balancer = create_load_balancer(vpc, subnets, security_groups)
            web_servers = create_web_servers(vpc, subnets, security_groups, load_balancer)
            database = create_database(vpc, subnets, security_groups)
            asset_bucket = create_asset_bucket

            create_outputs(load_balancer, web_servers, database, asset_bucket)
          end
        end

        private

        def create_vpc
          aws_vpc(:main, {
            cidr_block: '10.0.0.0/16',
            enable_dns_hostnames: true,
            enable_dns_support: true,
            tags: { Name: 'main-vpc', Environment: 'production' }
          })
        end

        def create_subnets(vpc)
          {
            public: [
              aws_subnet(:public_1, subnet_config(vpc, '10.0.1.0/24', 'us-east-1a', true, 'public-subnet-1', 'public')),
              aws_subnet(:public_2, subnet_config(vpc, '10.0.2.0/24', 'us-east-1b', true, 'public-subnet-2', 'public'))
            ],
            private: [
              aws_subnet(:private_1, subnet_config(vpc, '10.0.10.0/24', 'us-east-1a', false, 'private-subnet-1', 'private')),
              aws_subnet(:private_2, subnet_config(vpc, '10.0.11.0/24', 'us-east-1b', false, 'private-subnet-2', 'private'))
            ],
            database: [
              aws_subnet(:db_1, subnet_config(vpc, '10.0.20.0/24', 'us-east-1a', false, 'db-subnet-1', 'database')),
              aws_subnet(:db_2, subnet_config(vpc, '10.0.21.0/24', 'us-east-1b', false, 'db-subnet-2', 'database'))
            ]
          }
        end

        def subnet_config(vpc, cidr, az, public_ip, name, type)
          config = { vpc_id: vpc.id, cidr_block: cidr, availability_zone: az, tags: { Name: name, Type: type } }
          config[:map_public_ip_on_launch] = true if public_ip
          config
        end

        def create_security_groups(vpc, _subnets)
          alb_sg = aws_security_group(:alb, {
            name: 'alb-sg', description: 'Security group for Application Load Balancer', vpc_id: vpc.id,
            ingress: [
              { from_port: 80, to_port: 80, protocol: 'tcp', cidr_blocks: ['0.0.0.0/0'] },
              { from_port: 443, to_port: 443, protocol: 'tcp', cidr_blocks: ['0.0.0.0/0'] }
            ],
            egress: [{ from_port: 0, to_port: 65535, protocol: 'tcp', cidr_blocks: ['10.0.0.0/16'] }],
            tags: { Name: 'alb-security-group' }
          })

          web_sg = aws_security_group(:web, {
            name: 'web-servers-sg', description: 'Security group for web servers', vpc_id: vpc.id,
            ingress: [
              { from_port: 80, to_port: 80, protocol: 'tcp', security_groups: [alb_sg.id] },
              { from_port: 443, to_port: 443, protocol: 'tcp', security_groups: [alb_sg.id] },
              { from_port: 22, to_port: 22, protocol: 'tcp', cidr_blocks: ['10.0.0.0/16'] }
            ],
            tags: { Name: 'web-servers-security-group' }
          })

          db_sg = aws_security_group(:database, {
            name: 'database-sg', description: 'Security group for database', vpc_id: vpc.id,
            ingress: [{ from_port: 3306, to_port: 3306, protocol: 'tcp', security_groups: [web_sg.id] }],
            tags: { Name: 'database-security-group' }
          })

          { alb: alb_sg, web: web_sg, database: db_sg }
        end

        def create_load_balancer(vpc, subnets, security_groups)
          application_load_balancer(:web_alb, {
            vpc_ref: vpc, subnet_refs: subnets[:public], security_group_refs: [security_groups[:alb]],
            scheme: 'internet-facing', enable_https: true,
            certificate_arn: 'arn:aws:acm:us-east-1:123456789012:certificate/example',
            ssl_redirect: true, create_default_target_group: true, default_target_group_port: 80,
            enable_access_logs: true, tags: { Environment: 'production', Component: 'load-balancer' }
          })
        end

        def create_web_servers(vpc, subnets, security_groups, load_balancer)
          auto_scaling_web_servers(:web_servers, {
            vpc_ref: vpc, subnet_refs: subnets[:private], security_group_refs: [security_groups[:web]],
            ami_id: 'ami-0abcdef1234567890', instance_type: 't3.small', key_name: 'production-key',
            min_size: 2, max_size: 10, desired_capacity: 3, health_check_type: 'ELB',
            target_group_refs: [load_balancer.resources[:target_groups][:default]],
            enable_cpu_scaling: true, cpu_target_value: 70.0,
            tags: { Environment: 'production', Component: 'web-servers' }
          })
        end

        def create_database(vpc, subnets, security_groups)
          mysql_database(:app_database, {
            vpc_ref: vpc, subnet_refs: subnets[:database], security_group_refs: [security_groups[:database]],
            engine_version: '8.0.35', db_instance_class: 'db.t3.small', allocated_storage: 100,
            max_allocated_storage: 500, storage_type: 'gp3', db_name: 'webapp', username: 'admin',
            manage_master_user_password: true, storage_encrypted: true, multi_az: false,
            backup: { backup_retention_period: 7, backup_window: '03:00-04:00' },
            tags: { Environment: 'production', Component: 'database' }
          })
        end

        def create_asset_bucket
          secure_s3_bucket(:app_assets, {
            bucket_name: "webapp-assets-#{SecureRandom.hex(4)}",
            encryption: { sse_algorithm: 'AES256', enforce_ssl: true },
            versioning: { status: 'Enabled' },
            lifecycle_rules: [{
              id: 'optimize-costs', status: 'Enabled',
              transitions: [{ days: 30, storage_class: 'STANDARD_IA' }, { days: 90, storage_class: 'GLACIER' }]
            }],
            tags: { Environment: 'production', Component: 'storage' }
          })
        end

        def create_outputs(load_balancer, _web_servers, database, asset_bucket)
          output(:load_balancer_dns) { value load_balancer.outputs[:alb_dns_name]; description 'DNS name of the Application Load Balancer' }
          output(:database_endpoint) { value database.outputs[:db_instance_endpoint]; description 'RDS MySQL database endpoint' }
          output(:asset_bucket_name) { value asset_bucket.outputs[:bucket_name]; description 'S3 bucket name for application assets' }
        end
      end
    end
  end
end
