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

# Example 5: Microservices Backend Architecture
template :microservices_web_backend do
  include Pangea::Architectures

  frontend = web_application_architecture(:frontend, {
    domain_name: 'app.microservices.com',
    environment: 'production',
    instance_type: 't3.medium',
    auto_scaling: { min: 2, max: 8 },
    database_enabled: false,
    enable_cdn: true,
    tags: { Service: 'Frontend', Architecture: 'Microservices' }
  })

  services = [
    { name: 'user-service', subdomain: 'users.api.microservices.com', database: 'postgresql' },
    { name: 'order-service', subdomain: 'orders.api.microservices.com', database: 'mysql' },
    { name: 'notification-service', subdomain: 'notifications.api.microservices.com', database: false }
  ]

  services.each do |service|
    service_app = web_application_architecture(service[:name].tr('-', '_').to_sym, {
      domain_name: service[:subdomain],
      environment: 'production',
      instance_type: 't3.small',
      auto_scaling: { min: 2, max: 6 },
      database_enabled: !!service[:database],
      database_engine: service[:database] || 'mysql',
      database_instance_class: 'db.t3.small',
      enable_caching: true,
      enable_cdn: false,
      vpc_cidr: '10.0.0.0/16',
      tags: { Service: service[:name], Architecture: 'Microservices', Type: 'Backend' }
    })

    output :"#{service[:name].tr('-', '_')}_url" do
      value service_app.application_url
      description "#{service[:name]} API endpoint"
    end
  end

  api_gateway = aws_api_gateway_rest_api(:microservices_gateway, {
    name: 'microservices-gateway',
    description: 'API Gateway for microservices',
    endpoint_configuration: { types: ['REGIONAL'] }
  })

  shared_cache = aws_elasticache_replication_group(:shared_cache, {
    description: 'Shared Redis cache for microservices',
    replication_group_id: 'microservices-cache',
    port: 6379,
    parameter_group_name: 'default.redis7',
    node_type: 'cache.t3.micro',
    num_cache_clusters: 2,
    automatic_failover_enabled: true,
    multi_az_enabled: true,
    subnet_group_name: aws_elasticache_subnet_group(:cache_subnet_group, {
      name: 'microservices-cache-subnet-group',
      subnet_ids: frontend.network.private_subnets.map(&:id)
    }).name,
    security_group_ids: [
      aws_security_group(:cache_sg, {
        name: 'microservices-cache-sg',
        description: 'Redis cache security group',
        vpc_id: frontend.network.vpc.id,
        ingress: [{
          from_port: 6379,
          to_port: 6379,
          protocol: 'tcp',
          security_groups: services.map { |s| "#{s[:name].tr('-', '_')}_sg_id" }
        }]
      }).id
    ]
  })

  output :frontend_url do
    value frontend.application_url
    description 'Frontend application URL'
  end

  output :api_gateway_url do
    value "https://#{api_gateway.id}.execute-api.us-east-1.amazonaws.com/prod"
    description 'API Gateway endpoint for microservices'
  end

  output :shared_cache_endpoint do
    value shared_cache.primary_endpoint_address
    description 'Shared Redis cache endpoint'
  end

  output :total_architecture_cost do
    service_costs = services.sum do |service|
      case service[:database]
      when 'postgresql', 'mysql' then 85.0
      when false then 50.0
      end
    end
    total_cost = frontend.estimated_monthly_cost + service_costs + 25.0
    value total_cost
    description 'Total estimated monthly cost for microservices architecture'
  end
end
