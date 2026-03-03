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

require 'singleton'

module Pangea
  module Testing
    class TestDataRegistry
      include Singleton
      
      def initialize
        @data = {}
        register_vpc_data
        register_subnet_data
        register_instance_data
      end
      
      def for_resource(resource_type)
        @data[resource_type] || raise("No test data for #{resource_type}")
      end
      
      def register(resource_type, data)
        @data[resource_type] = data
      end
      
      private
      
      def register_vpc_data
        register(:aws_vpc, {
          valid: {
            cidr_block: "10.0.0.0/16",
            enable_dns_hostnames: true,
            enable_dns_support: true,
            tags: { "Name" => "test-vpc", "Environment" => "test" }
          },
          minimal: {
            cidr_block: "10.0.0.0/16"
          },
          invalid: {
            cidr_block: "invalid-cidr"
          }
        })
      end
      
      def register_subnet_data
        register(:aws_subnet, {
          valid: {
            vpc_id: "${aws_vpc.test.id}",
            cidr_block: "10.0.1.0/24",
            availability_zone: "us-east-1a",
            tags: { "Name" => "test-subnet" }
          },
          minimal: {
            vpc_id: "${aws_vpc.test.id}",
            cidr_block: "10.0.1.0/24"
          },
          invalid: {
            cidr_block: "10.0.1.0/24"
            # Missing required vpc_id
          }
        })
      end
      
      def register_instance_data
        register(:aws_instance, {
          valid: {
            instance_type: "t3.micro",
            ami: "ami-12345678",
            subnet_id: "${aws_subnet.test.id}",
            tags: { "Name" => "test-instance" }
          },
          minimal: {
            instance_type: "t3.micro",
            ami: "ami-12345678"
          },
          invalid: {
            instance_type: "invalid.type",
            ami: "not-an-ami"
          }
        })
      end
    end
  end
end