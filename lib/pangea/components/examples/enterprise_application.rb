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
      # High-availability enterprise application example
      module EnterpriseApplication
        def enterprise_application_example
          template :enterprise_app do
            include Pangea::Resources::AWS
            include Pangea::Components

            vpc = aws_vpc(:enterprise, { cidr_block: '10.0.0.0/16', tags: { Environment: 'production', Tier: 'enterprise' } })

            subnets = create_enterprise_subnets(vpc)
            security_groups = create_enterprise_security_groups(vpc)

            enterprise_alb = create_enterprise_alb(vpc, subnets, security_groups)
            enterprise_asg = create_enterprise_asg(vpc, subnets, security_groups, enterprise_alb)
            enterprise_db = create_enterprise_database(vpc, subnets, security_groups)
            primary_data = create_enterprise_storage

            create_enterprise_outputs(enterprise_alb, enterprise_asg, enterprise_db, primary_data)
          end
        end

        private

        def create_enterprise_subnets(vpc)
          {
            public: create_az_subnets(vpc, 'public', 1, true),
            private: create_az_subnets(vpc, 'private', 10, false),
            database: create_az_subnets(vpc, 'db', 20, false)
          }
        end

        def create_az_subnets(vpc, name_prefix, cidr_offset, public_ip)
          %w[a b c].map.with_index do |az, i|
            config = {
              vpc_id: vpc.id, cidr_block: "10.0.#{i + cidr_offset}.0/24",
              availability_zone: "us-east-1#{az}",
              tags: { Name: "#{name_prefix}-subnet-#{az}", Type: name_prefix }
            }
            config[:map_public_ip_on_launch] = true if public_ip
            aws_subnet("#{name_prefix}_#{az}".to_sym, config)
          end
        end

        def create_enterprise_security_groups(vpc)
          alb_sg = aws_security_group(:alb, {
            name: 'enterprise-alb-sg', vpc_id: vpc.id,
            ingress: [{ from_port: 443, to_port: 443, protocol: 'tcp', cidr_blocks: ['0.0.0.0/0'] }]
          })

          web_sg = aws_security_group(:web, {
            name: 'enterprise-web-sg', vpc_id: vpc.id,
            ingress: [{ from_port: 80, to_port: 80, protocol: 'tcp', security_groups: [alb_sg.id] }]
          })

          db_sg = aws_security_group(:db, {
            name: 'enterprise-db-sg', vpc_id: vpc.id,
            ingress: [{ from_port: 3306, to_port: 3306, protocol: 'tcp', security_groups: [web_sg.id] }]
          })

          { alb: alb_sg, web: web_sg, database: db_sg }
        end

        def create_enterprise_alb(vpc, subnets, security_groups)
          application_load_balancer(:enterprise_alb, {
            vpc_ref: vpc, subnet_refs: subnets[:public], security_group_refs: [security_groups[:alb]],
            scheme: 'internet-facing', enable_deletion_protection: true, enable_cross_zone_load_balancing: true,
            enable_https: true, certificate_arn: 'arn:aws:acm:us-east-1:123456789012:certificate/enterprise',
            ssl_redirect: true, idle_timeout: 300,
            target_groups: [
              { name: 'api', port: 8080, protocol: 'HTTP', health_check: { path: '/health', healthy_threshold: 2, unhealthy_threshold: 3, interval: 15 } },
              { name: 'admin', port: 9000, protocol: 'HTTP', stickiness_enabled: true, health_check: { path: '/admin/health', matcher: '200,202' } }
            ],
            enable_access_logs: true, access_logs_bucket: 'enterprise-alb-logs',
            tags: { Environment: 'production', Criticality: 'high' }
          })
        end

        def create_enterprise_asg(vpc, subnets, security_groups, enterprise_alb)
          auto_scaling_web_servers(:enterprise_web, {
            vpc_ref: vpc, subnet_refs: subnets[:private], security_group_refs: [security_groups[:web]],
            ami_id: 'ami-0abcdef1234567890', instance_type: 'c5.large', key_name: 'enterprise-key',
            min_size: 3, max_size: 20, desired_capacity: 6, health_check_type: 'ELB', health_check_grace_period: 600,
            target_group_refs: enterprise_alb.resources[:target_groups].values,
            enable_cpu_scaling: false,
            scaling_policies: [
              { policy_type: 'TargetTrackingScaling', target_value: 60.0, metric_type: 'ASGAverageCPUUtilization' },
              { policy_type: 'TargetTrackingScaling', target_value: 1000.0, metric_type: 'ALBRequestCountPerTarget', target_group_arn: enterprise_alb.resources[:target_groups][:api].arn }
            ],
            block_device_mappings: [{ device_name: '/dev/xvda', volume_type: 'gp3', volume_size: 50, iops: 3000, throughput: 250, encrypted: true }],
            monitoring: { enabled: true, granularity: '1Minute' },
            tags: { Environment: 'production', Criticality: 'high' }
          })
        end

        def create_enterprise_database(vpc, subnets, security_groups)
          mysql_database(:enterprise_db, {
            vpc_ref: vpc, subnet_refs: subnets[:database], security_group_refs: [security_groups[:database]],
            engine_version: '8.0.35', db_instance_class: 'db.r5.xlarge', allocated_storage: 500,
            max_allocated_storage: 2000, storage_type: 'gp3', iops: 3000, multi_az: true,
            storage_encrypted: true, kms_key_id: 'alias/rds-enterprise-key', deletion_protection: true,
            db_name: 'enterprise', username: 'admin', manage_master_user_password: true,
            backup: { backup_retention_period: 30, backup_window: '02:00-03:00', copy_tags_to_snapshot: true, skip_final_snapshot: false },
            monitoring: { monitoring_interval: 60, performance_insights_enabled: true, performance_insights_retention_period: 731 },
            create_read_replica: true, read_replica_count: 2, read_replica_instance_class: 'db.r5.large',
            tags: { Environment: 'production', Criticality: 'high' }
          })
        end

        def create_enterprise_storage
          secure_s3_bucket(:primary_data, {
            encryption: { sse_algorithm: 'aws:kms', kms_key_id: 'alias/s3-enterprise-key', enforce_ssl: true },
            versioning: { status: 'Enabled' }, object_lock_enabled: true,
            replication: {
              enabled: true, role_arn: 'arn:aws:iam::123456789012:role/S3ReplicationRole',
              rules: [{ id: 'disaster-recovery', status: 'Enabled', destination: { bucket: 'arn:aws:s3:::enterprise-data-dr', storage_class: 'STANDARD_IA' } }]
            },
            lifecycle_rules: [{
              id: 'enterprise-lifecycle', status: 'Enabled',
              transitions: [{ days: 30, storage_class: 'STANDARD_IA' }, { days: 90, storage_class: 'GLACIER_IR' }, { days: 365, storage_class: 'DEEP_ARCHIVE' }]
            }],
            logging: { enabled: true, target_bucket: 'enterprise-access-logs', target_prefix: 'data-access/' },
            tags: { Environment: 'production', Compliance: 'SOX-HIPAA' }
          })
        end

        def create_enterprise_outputs(enterprise_alb, enterprise_asg, enterprise_db, primary_data)
          output(:application_url) { value "https://#{enterprise_alb.outputs[:alb_dns_name]}"; description 'Enterprise application HTTPS URL' }
          output(:database_connection) { value enterprise_db.outputs[:db_instance_endpoint]; description 'Primary database connection endpoint' }
          output(:read_replicas) { value enterprise_db.outputs[:read_replica_identifiers]; description 'Read replica database endpoints' }
          output(:data_bucket) { value primary_data.outputs[:bucket_name]; description 'Primary data storage bucket' }
          output(:security_score) do
            combined_features = enterprise_alb.outputs[:security_features] + enterprise_asg.outputs[:security_features] + enterprise_db.outputs[:security_features] + primary_data.outputs[:security_features]
            value combined_features.uniq.count
            description 'Total number of security features enabled'
          end
          output(:estimated_monthly_cost) do
            total = enterprise_alb.outputs[:estimated_monthly_cost] + enterprise_asg.outputs[:estimated_monthly_cost] + enterprise_db.outputs[:estimated_monthly_cost] + primary_data.outputs[:estimated_monthly_cost]
            value total.round(2)
            description 'Total estimated monthly cost (USD)'
          end
        end
      end
    end
  end
end
