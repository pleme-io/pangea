#!/usr/bin/env ruby
# frozen_string_literal: true

# Advanced example showcasing Pangea's resource composition and return value patterns
# Demonstrates how resource functions return rich objects with references, outputs, and computed properties

template :composed_infrastructure do
  include Pangea::Resources::Composition  # Enable composition helpers
  
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment "development"
        Project "ResourceComposition"
      end
    end
  end
  
  # Pattern 1: Basic resource creation with return values
  # VPC function returns ResourceReference with computed properties
  vpc_ref = aws_vpc(:main, {
    cidr_block: "10.0.0.0/16",
    enable_dns_hostnames: true,
    enable_dns_support: true,
    tags: { Name: "main-vpc", Type: "foundation" }
  })
  
  # Access terraform references and computed properties
  puts "VPC ID: #{vpc_ref.id}"                           # ${aws_vpc.main.id}
  puts "VPC CIDR: #{vpc_ref.cidr_block}"                 # ${aws_vpc.main.cidr_block}  
  puts "Is Private CIDR: #{vpc_ref.is_private_cidr?}"    # Computed: true (10.0.0.0/16)
  puts "Subnet Capacity: #{vpc_ref.estimated_subnet_capacity}"  # Computed: 256 (/24 subnets)
  
  # Pattern 2: Resource chaining using return values
  # Create subnets using VPC reference
  public_subnet_a = aws_subnet(:public_a, {
    vpc_id: vpc_ref.id,                    # Use returned reference
    cidr_block: "10.0.1.0/24",
    availability_zone: "us-east-1a",
    map_public_ip_on_launch: true,
    tags: { Name: "public-subnet-a", Type: "public" }
  })
  
  public_subnet_b = aws_subnet(:public_b, {
    vpc_id: vpc_ref.id,                    # Reuse VPC reference
    cidr_block: "10.0.2.0/24", 
    availability_zone: "us-east-1b",
    map_public_ip_on_launch: true,
    tags: { Name: "public-subnet-b", Type: "public" }
  })
  
  private_subnet_a = aws_subnet(:private_a, {
    vpc_id: vpc_ref.id,
    cidr_block: "10.0.10.0/24",
    availability_zone: "us-east-1a",
    tags: { Name: "private-subnet-a", Type: "private" }
  })
  
  # Access subnet computed properties
  puts "Public Subnet A Type: #{public_subnet_a.subnet_type}"     # Computed: "public"
  puts "Public Subnet A IP Capacity: #{public_subnet_a.ip_capacity}"  # Computed: 251 (256 - 5 AWS reserved)
  puts "Private Subnet A Type: #{private_subnet_a.subnet_type}"   # Computed: "private"
  
  # Pattern 3: Internet Gateway with VPC attachment
  igw_ref = aws_internet_gateway(:main, {
    vpc_id: vpc_ref.id,
    tags: { Name: "main-igw" }
  })
  
  # Pattern 4: Route table with referenced resources
  public_rt_ref = aws_route_table(:public, {
    vpc_id: vpc_ref.id,
    routes: [
      {
        cidr_block: "0.0.0.0/0",
        gateway_id: igw_ref.id           # Use IGW reference
      }
    ],
    tags: { Name: "public-route-table" }
  })
  
  # Pattern 5: EC2 instance using multiple references
  web_server_ref = aws_instance(:web_server, {
    ami: "ami-0c55b159cbfafe1f0",
    instance_type: "t3.micro",
    subnet_id: public_subnet_a.id,        # Use subnet reference
    user_data: base64encode(<<~USERDATA),
      #!/bin/bash
      yum update -y
      yum install -y httpd
      systemctl start httpd
      systemctl enable httpd
      
      # Dynamic content using computed properties
      echo "<h1>Pangea Resource Composition Demo</h1>" > /var/www/html/index.html
      echo "<p>VPC: #{vpc_ref.id}</p>" >> /var/www/html/index.html
      echo "<p>Subnet: #{public_subnet_a.id}</p>" >> /var/www/html/index.html  
      echo "<p>Instance Type: #{web_server_ref.instance_type}</p>" >> /var/www/html/index.html
      echo "<p>Compute Family: #{web_server_ref.compute_family}</p>" >> /var/www/html/index.html
    USERDATA
    tags: {
      Name: "web-server",
      Type: "application",
      SubnetType: public_subnet_a.subnet_type  # Use computed property
    }
  })
  
  # Access instance computed properties
  puts "Instance Family: #{web_server_ref.compute_family}"  # Computed: "t3"
  puts "Instance Size: #{web_server_ref.compute_size}"      # Computed: "micro"
  puts "Will have public IP: #{web_server_ref.will_have_public_ip?}"  # Computed: true
  
  # Pattern 6: Multiple attribute access patterns
  puts "Direct attribute access: #{web_server_ref[:public_ip]}"      # ${aws_instance.web_server.public_ip}
  puts "Method access: #{web_server_ref.ref(:private_ip)}"           # ${aws_instance.web_server.private_ip}
  puts "Computed method: #{web_server_ref.public_ip}"               # ${aws_instance.web_server.public_ip}
  
  # Outputs using return values
  output :vpc_details do
    value {
      id: vpc_ref.id,
      cidr: vpc_ref.cidr_block,
      is_private: vpc_ref.is_private_cidr?,
      subnet_capacity: vpc_ref.estimated_subnet_capacity
    }
    description "VPC details with computed properties"
  end
  
  output :subnet_summary do
    value {
      public_subnets: [
        {
          id: public_subnet_a.id,
          az: public_subnet_a.availability_zone,
          type: public_subnet_a.subnet_type,
          capacity: public_subnet_a.ip_capacity
        },
        {
          id: public_subnet_b.id,
          az: public_subnet_b.availability_zone,
          type: public_subnet_b.subnet_type,
          capacity: public_subnet_b.ip_capacity
        }
      ],
      private_subnets: [
        {
          id: private_subnet_a.id,
          az: private_subnet_a.availability_zone,
          type: private_subnet_a.subnet_type,
          capacity: private_subnet_a.ip_capacity
        }
      ]
    }
    description "Subnet summary with computed properties"
  end
  
  output :web_server_info do
    value {
      instance_id: web_server_ref.id,
      public_ip: web_server_ref.public_ip,
      private_ip: web_server_ref.private_ip,
      instance_type: web_server_ref.instance_type,
      compute_family: web_server_ref.compute_family,
      compute_size: web_server_ref.compute_size,
      subnet_id: web_server_ref.subnet_id
    }
    description "Web server details with computed properties"
  end
end

# Template demonstrating composition helpers
template :composition_helpers do
  include Pangea::Resources::Composition
  
  provider :aws do
    region "us-east-1"
  end
  
  # Pattern 7: High-level composition function
  # Creates VPC + subnets + routing in one call
  network = vpc_with_subnets(:myapp, 
    vpc_cidr: "10.1.0.0/16",
    availability_zones: ["us-east-1a", "us-east-1b", "us-east-1c"],
    attributes: {
      vpc_tags: { Environment: "production", Team: "platform" },
      public_subnet_tags: { Tier: "web" },
      private_subnet_tags: { Tier: "app" }
    }
  )
  
  # Access composite reference properties
  puts "Created VPC: #{network.vpc.id}"
  puts "Created #{network.availability_zone_count} AZs"
  puts "Public subnet IDs: #{network.public_subnet_ids}"
  puts "Private subnet IDs: #{network.private_subnet_ids}"
  
  # Pattern 8: Composed web server creation
  # Uses composition helper that creates instance + security group
  web_app = web_server(:frontend,
    subnet_ref: network.public_subnets.first,  # Use first public subnet
    attributes: {
      instance_type: "t3.small",
      ami: "ami-0c55b159cbfafe1f0",
      instance_tags: { Role: "frontend", Environment: "production" }
    }
  )
  
  # Access composed resource properties
  puts "Web server instance: #{web_app.instance_id}"
  puts "Security group: #{web_app.security_group_id}"
  puts "Public IP: #{web_app.public_ip}"
  puts "Private IP: #{web_app.private_ip}"
  
  # Pattern 9: Cross-resource computed values
  # Use subnet properties to configure instance
  backend_server = aws_instance(:backend, {
    ami: "ami-0c55b159cbfafe1f0",
    instance_type: "c5.large",  # Compute-optimized for backend
    subnet_id: network.private_subnets.first.id,
    user_data: base64encode(<<~USERDATA),
      #!/bin/bash
      # Configure backend server
      echo "Backend server in subnet: #{network.private_subnets.first.id}"
      echo "Subnet type: #{network.private_subnets.first.subnet_type}"
      echo "Subnet IP capacity: #{network.private_subnets.first.ip_capacity}"
    USERDATA
    tags: {
      Name: "backend-server",
      Type: "backend",
      SubnetType: network.private_subnets.first.subnet_type,
      Environment: "production"
    }
  })
  
  # Output composition results
  output :network_topology do
    value {
      vpc: {
        id: network.vpc.id,
        cidr: network.vpc.cidr_block,
        is_private_cidr: network.vpc.is_private_cidr?
      },
      availability_zones: network.availability_zone_count,
      public_subnets: network.public_subnet_ids,
      private_subnets: network.private_subnet_ids,
      internet_gateway: network.internet_gateway.id
    }
    description "Complete network topology with references"
  end
  
  output :application_tier do
    value {
      frontend: {
        instance_id: web_app.instance_id,
        security_group: web_app.security_group_id,
        public_ip: web_app.public_ip,
        subnet: network.public_subnets.first.id
      },
      backend: {
        instance_id: backend_server.id,
        instance_type: backend_server.instance_type,
        compute_family: backend_server.compute_family,
        subnet: network.private_subnets.first.id,
        subnet_capacity: network.private_subnets.first.ip_capacity
      }
    }
    description "Application tier with resource references"
  end
end

# This example demonstrates the key benefits of resource return values:
#
# 1. **Reference Chaining**: Resources return references that can be used by other resources
# 2. **Computed Properties**: Access to derived attributes not available in raw terraform
# 3. **Type Safety**: All references are type-checked and validated
# 4. **Composition Patterns**: High-level functions that create multiple related resources
# 5. **Rich Outputs**: Use computed properties in outputs and other resources
# 6. **Multiple Access Patterns**: ref(), [], and direct method access
# 7. **Resource Metadata**: Access to original attributes and terraform outputs
# 8. **Composite References**: Collections of related resources with helper methods
#
# Usage:
#   pangea plan resource_composition_patterns.rb --template composed_infrastructure
#   pangea apply resource_composition_patterns.rb --template composed_infrastructure
#   pangea plan resource_composition_patterns.rb --template composition_helpers
#   pangea apply resource_composition_patterns.rb --template composition_helpers