#!/usr/bin/env ruby
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


# Example showcasing Pangea's type-safe resource abstraction system
# This demonstrates the benefits of pure functions with runtime validation

# Foundation template - networking infrastructure with type safety
template :foundation do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment "development"
        Project "TypeSafeExample"
      end
    end
  end
  
  # Type-safe VPC creation with CIDR validation
  aws_vpc(:main, {
    cidr_block: "10.0.0.0/16",  # Automatically validates CIDR format and size
    enable_dns_hostnames: true,
    enable_dns_support: true,
    tags: {
      Name: "main-vpc",
      Purpose: "demonstration"
    }
  })
  
  # Type-safe public subnets with availability zone validation
  aws_subnet(:public_a, {
    vpc_id: ref(:aws_vpc, :main, :id),
    cidr_block: "10.0.1.0/24",
    availability_zone: "us-east-1a",
    map_public_ip_on_launch: true,
    tags: {
      Name: "public-subnet-a",
      Type: "public"
    }
  })
  
  aws_subnet(:public_b, {
    vpc_id: ref(:aws_vpc, :main, :id),
    cidr_block: "10.0.2.0/24", 
    availability_zone: "us-east-1b",
    map_public_ip_on_launch: true,
    tags: {
      Name: "public-subnet-b",
      Type: "public"
    }
  })
  
  # Type-safe private subnets
  aws_subnet(:private_a, {
    vpc_id: ref(:aws_vpc, :main, :id),
    cidr_block: "10.0.10.0/24",
    availability_zone: "us-east-1a",
    tags: {
      Name: "private-subnet-a",
      Type: "private"
    }
  })
  
  aws_subnet(:private_b, {
    vpc_id: ref(:aws_vpc, :main, :id),
    cidr_block: "10.0.20.0/24",
    availability_zone: "us-east-1b",
    tags: {
      Name: "private-subnet-b",
      Type: "private"
    }
  })
  
  # Type-safe Internet Gateway
  aws_internet_gateway(:main, {
    vpc_id: ref(:aws_vpc, :main, :id),
    tags: {
      Name: "main-igw"
    }
  })
  
  # Type-safe Route Table with routing rules
  aws_route_table(:public, {
    vpc_id: ref(:aws_vpc, :main, :id),
    routes: [
      {
        cidr_block: "0.0.0.0/0",
        gateway_id: ref(:aws_internet_gateway, :main, :id)
      }
    ],
    tags: {
      Name: "public-rt"
    }
  })
  
  # Outputs for other templates to reference
  output :vpc_id do
    value ref(:aws_vpc, :main, :id)
    description "VPC ID for use by other templates"
  end
  
  output :public_subnet_ids do
    value [
      ref(:aws_subnet, :public_a, :id),
      ref(:aws_subnet, :public_b, :id)
    ]
    description "Public subnet IDs"
  end
  
  output :private_subnet_ids do
    value [
      ref(:aws_subnet, :private_a, :id),
      ref(:aws_subnet, :private_b, :id)
    ]
    description "Private subnet IDs"
  end
end

# Web application template demonstrating cross-template references
template :web_application do
  provider :aws do
    region "us-east-1"
  end
  
  # Reference foundation outputs via remote state
  data :terraform_remote_state, :foundation do
    backend "s3"
    config do
      bucket "terraform-state-dev"
      key "pangea/development/foundation/terraform.tfstate"
      region "us-east-1"
    end
  end
  
  # Type-safe EC2 instance with strict validation
  # This will validate instance_type against allowed values
  aws_instance(:web_server, {
    ami: "ami-0c55b159cbfafe1f0",      # Amazon Linux 2
    instance_type: "t3.micro",         # Validated against enum
    subnet_id: data(:terraform_remote_state, :foundation, :outputs, :public_subnet_ids, 0),
    user_data: base64encode(<<~USERDATA),
      #!/bin/bash
      yum update -y
      yum install -y httpd
      systemctl start httpd
      systemctl enable httpd
      echo "<h1>Hello from Pangea Type-Safe Infrastructure!</h1>" > /var/www/html/index.html
      echo "<p>This server was created using type-safe resource functions.</p>" >> /var/www/html/index.html
      echo "<p>Instance Type: t3.micro (validated at compile time)</p>" >> /var/www/html/index.html
    USERDATA
    tags: {
      Name: "web-server",
      Type: "application",
      Framework: "pangea-type-safe"
    }
  })
  
  output :web_server_id do
    value ref(:aws_instance, :web_server, :id)
    description "Web server instance ID"
  end
  
  output :web_server_public_ip do
    value ref(:aws_instance, :web_server, :public_ip)
    description "Web server public IP address"
  end
end

# This example demonstrates several key benefits:
#
# 1. Type Safety: All attributes are validated at runtime
#    - CIDR blocks are validated for correct format
#    - Instance types are validated against allowed values
#    - Required attributes cause clear errors if missing
#
# 2. IDE Support: With RBS definitions, IDEs provide:
#    - Autocomplete for resource attributes
#    - Parameter hints showing required vs optional
#    - Type checking warnings before runtime
#
# 3. Consistency: All resources use the same function pattern
#    - resource_name(symbol, attributes_hash)
#    - No need to remember different DSL syntaxes
#
# 4. Default Values: Resource functions provide sensible defaults
#    - enable_dns_hostnames: true (default for VPCs)
#    - map_public_ip_on_launch: false (default for subnets)
#
# 5. Custom Validation: Beyond basic types
#    - CIDR block size validation (not too large/small)
#    - Availability zone format validation
#    - Cross-attribute validation where applicable
#
# To use this infrastructure:
#   pangea plan type_safe_infrastructure.rb --template foundation
#   pangea apply type_safe_infrastructure.rb --template foundation
#   pangea plan type_safe_infrastructure.rb --template web_application  
#   pangea apply type_safe_infrastructure.rb --template web_application