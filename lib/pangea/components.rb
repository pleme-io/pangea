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


require 'pangea/components/base'
require 'pangea/components/types'

# Load all component implementations
require 'pangea/components/secure_vpc/component'
require 'pangea/components/public_private_subnets/component'
require 'pangea/components/web_tier_subnets/component'
require 'pangea/components/web_security_group/component'
require 'pangea/components/application_load_balancer/component'
require 'pangea/components/auto_scaling_web_servers/component'
require 'pangea/components/mysql_database/component'
require 'pangea/components/secure_s3_bucket/component'
require 'pangea/components/microservice_deployment/component'
require 'pangea/components/api_gateway_microservices/component'
require 'pangea/components/event_driven_microservice/component'
require 'pangea/components/service_mesh_observability/component'
require 'pangea/components/multi_region_active_active/component'
require 'pangea/components/global_traffic_manager/component'
require 'pangea/components/disaster_recovery_pilot_light/component'
require 'pangea/components/global_service_mesh/component'

module Pangea
  # Pangea Component Abstraction System
  #
  # Components are reusable, type-safe building blocks that compose multiple related resources
  # into common patterns. They provide a middle abstraction layer between individual resources
  # and complete architectures.
  #
  # @example Basic component usage
  #   include Pangea::Components::SecureVpc
  #   include Pangea::Components::PublicPrivateSubnets
  #   
  #   network = secure_vpc(:main, {
  #     cidr_block: "10.0.0.0/16",
  #     availability_zones: ["us-east-1a", "us-east-1b"]
  #   })
  #   
  #   subnets = public_private_subnets(:web_tier, {
  #     vpc_ref: network.vpc,
  #     public_cidrs: ["10.0.1.0/24", "10.0.2.0/24"],
  #     private_cidrs: ["10.0.10.0/24", "10.0.20.0/24"]
  #   })
  #
  # @see https://docs.pangea.io/components Component Documentation
  module Components
    # Include all component modules for easy access
    include SecureVpc
    include PublicPrivateSubnets  
    include WebTierSubnets
    include WebSecurityGroup
    include ApplicationLoadBalancer
    include AutoScalingWebServers
    include MysqlDatabase
    include SecureS3Bucket
    include MicroserviceDeployment
    include ApiGatewayMicroservices
    include EventDrivenMicroservice
    include ServiceMeshObservability
    include MultiRegionActiveActive
    include GlobalTrafficManager
    include DisasterRecoveryPilotLight
    include GlobalServiceMesh
  end
end