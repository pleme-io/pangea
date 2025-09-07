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

# Example Pangea infrastructure template
# This demonstrates the Ruby DSL that compiles to Terraform JSON

template :web_infrastructure do
  # Provider configuration
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment "development"
      end
    end
  end

# VPC and networking
resource :aws_vpc, :main do
  cidr_block "10.0.0.0/16"
  enable_dns_hostnames true
  enable_dns_support true
  
  tags do
    Name "main-vpc"
  end
end

resource :aws_subnet, :public do
  vpc_id ref(:aws_vpc, :main, :id)
  cidr_block "10.0.1.0/24"
  availability_zone "us-east-1a"
  map_public_ip_on_launch true
  
  tags do
    Name "public-subnet"
    Type "public"
  end
end

resource :aws_internet_gateway, :main do
  vpc_id ref(:aws_vpc, :main, :id)
  
  tags do
    Name "main-igw"
  end
end

# Security group
resource :aws_security_group, :web do
  name "web-security-group"
  description "Security group for web servers"
  vpc_id ref(:aws_vpc, :main, :id)
  
  ingress do
    from_port 80
    to_port 80
    protocol "tcp"
    cidr_blocks ["0.0.0.0/0"]
    description "HTTP from anywhere"
  end
  
  ingress do
    from_port 443
    to_port 443
    protocol "tcp"
    cidr_blocks ["0.0.0.0/0"]
    description "HTTPS from anywhere"
  end
  
  egress do
    from_port 0
    to_port 0
    protocol "-1"
    cidr_blocks ["0.0.0.0/0"]
    description "Allow all outbound"
  end
  
  tags do
    Name "web-sg"
  end
end

# EC2 Instance
resource :aws_instance, :web_server do
  ami "ami-0c55b159cbfafe1f0"
  instance_type "t2.micro"
  subnet_id ref(:aws_subnet, :public, :id)
  vpc_security_group_ids [ref(:aws_security_group, :web, :id)]
  
  user_data <<~USERDATA
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from Pangea!</h1>" > /var/www/html/index.html
  USERDATA
  
  tags do
    Name "web-server"
    Type "webserver"
  end
end

# S3 Bucket for static assets
resource :aws_s3_bucket, :assets do
  bucket "my-app-assets-#{data(:aws_caller_identity, :current, :account_id)}"
  
  tags do
    Name "assets-bucket"
    Purpose "static-hosting"
  end
end

resource :aws_s3_bucket_versioning, :assets do
  bucket ref(:aws_s3_bucket, :assets, :id)
  
  versioning_configuration do
    status "Enabled"
  end
end

resource :aws_s3_bucket_public_access_block, :assets do
  bucket ref(:aws_s3_bucket, :assets, :id)
  
  block_public_acls true
  block_public_policy true
  ignore_public_acls true
  restrict_public_buckets true
end

# Data sources
data :aws_caller_identity, :current do
end

  # Outputs
  output :web_server_public_ip do
    value ref(:aws_instance, :web_server, :public_ip)
    description "Public IP address of the web server"
  end
  
  output :vpc_id do
    value ref(:aws_vpc, :main, :id)
    description "ID of the VPC"
  end
  
  output :assets_bucket_name do
    value ref(:aws_s3_bucket, :assets, :id)
    description "Name of the assets S3 bucket"
  end
end

template :database do
  # Provider configuration
  provider :aws do
    region "us-east-1"
  end
  
  # RDS Instance
  resource :aws_db_instance, :main do
    identifier "main-database"
    engine "postgres"
    engine_version "13.7"
    instance_class "db.t3.micro"
    allocated_storage 20
    storage_type "gp2"
    
    db_name "myapp"
    username "admin"
    manage_master_user_password true
    
    vpc_security_group_ids [ref(:aws_security_group, :db, :id)]
    db_subnet_group_name ref(:aws_db_subnet_group, :main, :name)
    
    skip_final_snapshot true
    
    tags do
      Name "main-database"
      Type "database"
    end
  end
  
  # Security group for database
  resource :aws_security_group, :db do
    name "database-security-group"
    description "Security group for database"
    
    ingress do
      from_port 5432
      to_port 5432
      protocol "tcp"
      cidr_blocks ["10.0.0.0/16"]
      description "PostgreSQL from VPC"
    end
    
    tags do
      Name "database-sg"
    end
  end
  
  # DB subnet group
  resource :aws_db_subnet_group, :main do
    name "main-db-subnet-group"
    subnet_ids ["subnet-12345678", "subnet-87654321"]  # Reference actual subnets
    
    tags do
      Name "main-db-subnet-group"
    end
  end
end