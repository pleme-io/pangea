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
        # Fallback resource creation methods (when components aren't available)
        module FallbackResources
          def create_vpc_directly(name, _attributes)
            { vpc: { id: "#{name}-vpc-id" }, public_subnets: [], private_subnets: [] }
          end

          def create_security_groups_directly(name, _attributes, _network)
            { web_sg: { id: "#{name}-web-sg-id" }, db_sg: { id: "#{name}-db-sg-id" } }
          end

          def create_load_balancer_directly(name, _attributes, _network, _security_groups)
            {
              arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/#{name}/1234567890123456",
              dns_name: "#{name}-alb-1234567890.us-east-1.elb.amazonaws.com",
              target_group: { arn: "#{name}-tg-arn" }
            }
          end

          def create_web_servers_directly(name, attributes, _network, _security_groups, _load_balancer)
            {
              auto_scaling_group_name: "#{name}-asg",
              launch_template_id: "#{name}-lt",
              min_size: attributes[:auto_scaling][:min],
              max_size: attributes[:auto_scaling][:max]
            }
          end

          def create_database_directly(name, _attributes, _network, _security_groups)
            { endpoint: "#{name}-db.cluster-xyz.us-east-1.rds.amazonaws.com", port: 3306, db_name: name.to_s.tr('-', '_') }
          end

          def create_cache_directly(name, _attributes, _network, _security_groups)
            { cache_cluster_id: "#{name}-cache", redis_endpoint: "#{name}-cache.abc123.0001.use1.cache.amazonaws.com", port: 6379 }
          end

          def create_cdn_directly(name, _attributes, _load_balancer)
            { distribution_id: 'E1234567890123', domain_name: 'd1234567890123.cloudfront.net' }
          end
        end
      end
    end
  end
end
