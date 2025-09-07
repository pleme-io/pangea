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