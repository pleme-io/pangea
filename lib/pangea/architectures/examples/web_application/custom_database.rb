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

require 'pangea'

# Example 4: Custom Database Override
template :custom_database_web_app do
  include Pangea::Architectures

  web_app = web_application_architecture(:custom_db_app, {
    domain_name: 'custom-app.com',
    environment: 'production',
    database_enabled: true
  })

  web_app.override(:database) do |arch_ref|
    aws_rds_cluster(:custom_aurora, {
      cluster_identifier: "#{arch_ref.name}-aurora-cluster",
      engine: 'aurora-postgresql',
      engine_mode: 'serverless',
      master_username: 'postgres',
      manage_master_user_password: true,
      scaling_configuration: {
        auto_pause: true,
        max_capacity: 16,
        min_capacity: 2,
        seconds_until_auto_pause: 300
      },
      backup_retention_period: 7,
      preferred_backup_window: '07:00-09:00',
      preferred_maintenance_window: 'sun:05:00-sun:06:00',
      storage_encrypted: true,
      db_subnet_group_name: aws_db_subnet_group(:aurora_subnet_group, {
        name: "#{arch_ref.name}-aurora-subnet-group",
        subnet_ids: arch_ref.network.private_subnets.map(&:id),
        description: "Aurora subnet group for #{arch_ref.name}"
      }).name,
      vpc_security_group_ids: [
        aws_security_group(:aurora_sg, {
          name: "#{arch_ref.name}-aurora-sg",
          description: 'Aurora PostgreSQL security group',
          vpc_id: arch_ref.network.vpc.id,
          ingress: [{
            from_port: 5432,
            to_port: 5432,
            protocol: 'tcp',
            security_groups: [arch_ref.security_groups.web_sg.id]
          }],
          egress: [{
            from_port: 0,
            to_port: 0,
            protocol: '-1',
            cidr_blocks: ['0.0.0.0/0']
          }]
        }).id
      ],
      tags: {
        Name: "#{arch_ref.name}-aurora-cluster",
        Environment: 'production',
        Engine: 'Aurora PostgreSQL Serverless'
      }
    })
  end

  output :application_url do
    value web_app.application_url
  end

  output :aurora_endpoint do
    value web_app.database.endpoint
    description 'Aurora Serverless cluster endpoint'
  end
end
