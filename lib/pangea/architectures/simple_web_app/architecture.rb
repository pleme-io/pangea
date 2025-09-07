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


require 'pangea/architecture_registry'
require 'pangea/architectures/simple_web_app/types'

module Pangea
  module Architectures
    # Simple web app architecture for testing auto-registration
    module SimpleWebAppModule
      def simple_web_app_architecture(name, attributes = {})
        # Validate attributes
        arch_attrs = SimpleWebApp::Types::SimpleWebAppAttributes.new(attributes)
        
        # Create VPC using require pattern (assuming VPC is available)
        vpc_ref = aws_vpc(:"#{name}_vpc", {
          cidr_block: arch_attrs.vpc_cidr,
          enable_dns_hostnames: true,
          enable_dns_support: true,
          tags: arch_attrs.tags.merge({
            Name: "#{name}-vpc",
            Environment: arch_attrs.environment,
            Architecture: "SimpleWebApp"
          })
        })
        
        # Create subnets in each AZ
        subnet_refs = []
        arch_attrs.availability_zones.each_with_index do |az, index|
          subnet_refs << aws_subnet(:"#{name}_subnet_#{index}", {
            vpc_id: vpc_ref.id,
            cidr_block: "#{arch_attrs.vpc_cidr.split('.')[0]}.#{arch_attrs.vpc_cidr.split('.')[1]}.#{index + 1}.0/24",
            availability_zone: az,
            map_public_ip_on_launch: true,
            tags: arch_attrs.tags.merge({
              Name: "#{name}-subnet-#{az}",
              Environment: arch_attrs.environment,
              Type: "public"
            })
          })
        end
        
        # Return simple architecture reference
        {
          name: name,
          type: 'simple_web_app_architecture',
          vpc: vpc_ref,
          subnets: subnet_refs,
          availability_zones: arch_attrs.availability_zones
        }
      end
    end
  end
end

# Auto-register this architecture module when it's loaded
Pangea::ArchitectureRegistry.register_architecture(Pangea::Architectures::SimpleWebAppModule)