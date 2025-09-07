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


require 'spec_helper'

# Load aws_dynamodb_table resource and types for testing
require 'pangea/resources/aws_dynamodb_table/resource'
require 'pangea/resources/aws_dynamodb_table/types'

RSpec.describe "aws_dynamodb_table resource function" do
  # Create a test class that includes the AWS module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      # Mock the terraform-synthesizer resource method
      def resource(type, name)
        @resources ||= {}
        resource_data = { type: type, name: name, attributes: {} }
        
        yield if block_given?
        
        @resources["#{type}.#{name}"] = resource_data
        resource_data
      end
      
      # Method missing to capture terraform attributes
      def method_missing(method_name, *args, &block)
        # Don't capture certain methods that might interfere
        return super if [:expect, :be_a, :eq].include?(method_name)
        # For terraform-synthesizer attribute calls, just return the value
        args.first if args.any?
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }
  
  describe "DynamoDbTableAttributes validation" do
    it "accepts simple hash key table configuration" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "users",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id"
      })
      
      expect(attrs.name).to eq("users")
      expect(attrs.billing_mode).to eq("PAY_PER_REQUEST")
      expect(attrs.hash_key).to eq("id")
      expect(attrs.attribute.size).to eq(1)
      expect(attrs.attribute[0][:name]).to eq("id")
      expect(attrs.attribute[0][:type]).to eq("S")
      expect(attrs.is_pay_per_request?).to eq(true)
      expect(attrs.is_provisioned?).to eq(false)
      expect(attrs.has_range_key?).to eq(false)
    end
    
    it "accepts composite key table configuration" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "orders",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "pk", type: "S" },
          { name: "sk", type: "S" }
        ],
        hash_key: "pk",
        range_key: "sk"
      })
      
      expect(attrs.hash_key).to eq("pk")
      expect(attrs.range_key).to eq("sk")
      expect(attrs.has_range_key?).to eq(true)
      expect(attrs.attribute.size).to eq(2)
    end
    
    it "accepts provisioned billing mode configuration" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "high-throughput",
        billing_mode: "PROVISIONED",
        read_capacity: 1000,
        write_capacity: 500,
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id"
      })
      
      expect(attrs.billing_mode).to eq("PROVISIONED")
      expect(attrs.read_capacity).to eq(1000)
      expect(attrs.write_capacity).to eq(500)
      expect(attrs.is_provisioned?).to eq(true)
      expect(attrs.is_pay_per_request?).to eq(false)
    end
    
    it "accepts global secondary index configuration" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "analytics",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "pk", type: "S" },
          { name: "sk", type: "S" },
          { name: "gsi1pk", type: "S" },
          { name: "gsi1sk", type: "S" }
        ],
        hash_key: "pk",
        range_key: "sk",
        global_secondary_index: [
          {
            name: "GSI1",
            hash_key: "gsi1pk",
            range_key: "gsi1sk",
            projection_type: "ALL"
          }
        ]
      })
      
      expect(attrs.has_gsi?).to eq(true)
      expect(attrs.global_secondary_index.size).to eq(1)
      expect(attrs.global_secondary_index[0][:name]).to eq("GSI1")
      expect(attrs.global_secondary_index[0][:hash_key]).to eq("gsi1pk")
      expect(attrs.global_secondary_index[0][:range_key]).to eq("gsi1sk")
      expect(attrs.global_secondary_index[0][:projection_type]).to eq("ALL")
    end
    
    it "accepts local secondary index configuration" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "products",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "pk", type: "S" },
          { name: "sk", type: "S" },
          { name: "lsi1sk", type: "N" }
        ],
        hash_key: "pk",
        range_key: "sk",
        local_secondary_index: [
          {
            name: "LSI1",
            range_key: "lsi1sk",
            projection_type: "KEYS_ONLY"
          }
        ]
      })
      
      expect(attrs.has_lsi?).to eq(true)
      expect(attrs.local_secondary_index.size).to eq(1)
      expect(attrs.local_secondary_index[0][:name]).to eq("LSI1")
      expect(attrs.local_secondary_index[0][:range_key]).to eq("lsi1sk")
      expect(attrs.local_secondary_index[0][:projection_type]).to eq("KEYS_ONLY")
    end
    
    it "accepts TTL configuration" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "sessions",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id",
        ttl: {
          attribute_name: "expires_at",
          enabled: true
        }
      })
      
      expect(attrs.has_ttl?).to eq(true)
      expect(attrs.ttl[:attribute_name]).to eq("expires_at")
      expect(attrs.ttl[:enabled]).to eq(true)
    end
    
    it "accepts stream configuration" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "events",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id",
        stream_enabled: true,
        stream_view_type: "NEW_AND_OLD_IMAGES"
      })
      
      expect(attrs.has_stream?).to eq(true)
      expect(attrs.stream_enabled).to eq(true)
      expect(attrs.stream_view_type).to eq("NEW_AND_OLD_IMAGES")
    end
    
    it "accepts encryption configuration" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "secure-data",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id",
        server_side_encryption: {
          enabled: true,
          kms_key_id: kms_key_arn
        }
      })
      
      expect(attrs.has_encryption?).to eq(true)
      expect(attrs.server_side_encryption[:enabled]).to eq(true)
      expect(attrs.server_side_encryption[:kms_key_id]).to eq(kms_key_arn)
    end
    
    it "accepts point-in-time recovery configuration" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "backups",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id",
        point_in_time_recovery_enabled: true
      })
      
      expect(attrs.has_pitr?).to eq(true)
      expect(attrs.point_in_time_recovery_enabled).to eq(true)
    end
    
    it "accepts global table replica configuration" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "global-users",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id",
        replica: [
          {
            region_name: "us-west-2",
            kms_key_id: kms_key_arn,
            point_in_time_recovery: true
          },
          {
            region_name: "eu-west-1",
            table_class: "STANDARD_INFREQUENT_ACCESS"
          }
        ]
      })
      
      expect(attrs.is_global_table?).to eq(true)
      expect(attrs.replica.size).to eq(2)
      expect(attrs.replica[0][:region_name]).to eq("us-west-2")
      expect(attrs.replica[1][:region_name]).to eq("eu-west-1")
    end
    
    it "accepts comprehensive table configuration" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "comprehensive",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "pk", type: "S" },
          { name: "sk", type: "S" },
          { name: "gsi1pk", type: "S" },
          { name: "lsi1sk", type: "N" }
        ],
        hash_key: "pk",
        range_key: "sk",
        global_secondary_index: [
          {
            name: "GSI1",
            hash_key: "gsi1pk",
            projection_type: "INCLUDE",
            non_key_attributes: ["attr1", "attr2"]
          }
        ],
        local_secondary_index: [
          {
            name: "LSI1",
            range_key: "lsi1sk",
            projection_type: "ALL"
          }
        ],
        ttl: {
          attribute_name: "expires_at",
          enabled: true
        },
        stream_enabled: true,
        stream_view_type: "NEW_AND_OLD_IMAGES",
        point_in_time_recovery_enabled: true,
        server_side_encryption: {
          enabled: true,
          kms_key_id: kms_key_arn
        },
        deletion_protection_enabled: true,
        table_class: "STANDARD_INFREQUENT_ACCESS",
        tags: {
          Environment: "production",
          Service: "core"
        }
      })
      
      expect(attrs.has_gsi?).to eq(true)
      expect(attrs.has_lsi?).to eq(true)
      expect(attrs.has_ttl?).to eq(true)
      expect(attrs.has_stream?).to eq(true)
      expect(attrs.has_encryption?).to eq(true)
      expect(attrs.has_pitr?).to eq(true)
      expect(attrs.total_indexes).to eq(2)
      expect(attrs.table_class).to eq("STANDARD_INFREQUENT_ACCESS")
    end
    
    it "validates provisioned billing mode requires capacity" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid",
          billing_mode: "PROVISIONED",
          attribute: [{ name: "id", type: "S" }],
          hash_key: "id"
          # Missing read_capacity and write_capacity
        })
      }.to raise_error(Dry::Struct::Error, /requires read_capacity and write_capacity/)
    end
    
    it "validates pay per request billing mode rejects capacity" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid",
          billing_mode: "PAY_PER_REQUEST",
          read_capacity: 5, # Not allowed for PAY_PER_REQUEST
          attribute: [{ name: "id", type: "S" }],
          hash_key: "id"
        })
      }.to raise_error(Dry::Struct::Error, /does not support read_capacity/)
    end
    
    it "validates GSI capacity for provisioned billing mode" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid",
          billing_mode: "PROVISIONED",
          read_capacity: 5,
          write_capacity: 5,
          attribute: [
            { name: "id", type: "S" },
            { name: "gsi1pk", type: "S" }
          ],
          hash_key: "id",
          global_secondary_index: [
            {
              name: "GSI1",
              hash_key: "gsi1pk"
              # Missing read_capacity and write_capacity
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /requires read_capacity and write_capacity/)
    end
    
    it "validates stream configuration requires view type" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid",
          billing_mode: "PAY_PER_REQUEST",
          attribute: [{ name: "id", type: "S" }],
          hash_key: "id",
          stream_enabled: true
          # Missing stream_view_type
        })
      }.to raise_error(Dry::Struct::Error, /stream_view_type is required/)
    end
    
    it "validates attribute definitions for all key attributes" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid",
          billing_mode: "PAY_PER_REQUEST",
          attribute: [
            { name: "id", type: "S" }
            # Missing gsi1pk definition
          ],
          hash_key: "id",
          global_secondary_index: [
            {
              name: "GSI1",
              hash_key: "gsi1pk"  # Referenced but not defined
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /Missing attribute definitions/)
    end
    
    it "validates GSI projection INCLUDE requires non_key_attributes" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid",
          billing_mode: "PAY_PER_REQUEST",
          attribute: [
            { name: "id", type: "S" },
            { name: "gsi1pk", type: "S" }
          ],
          hash_key: "id",
          global_secondary_index: [
            {
              name: "GSI1",
              hash_key: "gsi1pk",
              projection_type: "INCLUDE"
              # Missing non_key_attributes
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /requires non_key_attributes/)
    end
    
    it "validates GSI projection non-INCLUDE cannot have non_key_attributes" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid",
          billing_mode: "PAY_PER_REQUEST",
          attribute: [
            { name: "id", type: "S" },
            { name: "gsi1pk", type: "S" }
          ],
          hash_key: "id",
          global_secondary_index: [
            {
              name: "GSI1",
              hash_key: "gsi1pk",
              projection_type: "ALL",
              non_key_attributes: ["attr1"] # Not allowed for ALL
            }
          ]
        })
      }.to raise_error(Dry::Struct::Error, /cannot have non_key_attributes/)
    end
    
    it "validates maximum GSI limit" do
      # Create 21 GSIs (over the limit of 20)
      gsis = (1..21).map do |i|
        {
          name: "GSI#{i}",
          hash_key: "gsi#{i}pk"
        }
      end
      
      attributes = (1..21).map { |i| { name: "gsi#{i}pk", type: "S" } }
      attributes << { name: "id", type: "S" }
      
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "too-many-gsis",
          billing_mode: "PAY_PER_REQUEST",
          attribute: attributes,
          hash_key: "id",
          global_secondary_index: gsis
        })
      }.to raise_error(Dry::Struct::Error, /Maximum of 20 Global Secondary Indexes/)
    end
    
    it "validates maximum LSI limit" do
      # Create 11 LSIs (over the limit of 10)
      lsis = (1..11).map do |i|
        {
          name: "LSI#{i}",
          range_key: "lsi#{i}sk"
        }
      end
      
      attributes = (1..11).map { |i| { name: "lsi#{i}sk", type: "S" } }
      attributes << { name: "pk", type: "S" }
      attributes << { name: "sk", type: "S" }
      
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "too-many-lsis",
          billing_mode: "PAY_PER_REQUEST",
          attribute: attributes,
          hash_key: "pk",
          range_key: "sk",
          local_secondary_index: lsis
        })
      }.to raise_error(Dry::Struct::Error, /Maximum of 10 Local Secondary Indexes/)
    end
    
    it "validates capacity constraints" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid-capacity",
          billing_mode: "PROVISIONED",
          read_capacity: 50000, # Over 40000 limit
          write_capacity: 5,
          attribute: [{ name: "id", type: "S" }],
          hash_key: "id"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates attribute type enumeration" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid-type",
          billing_mode: "PAY_PER_REQUEST",
          attribute: [
            { name: "id", type: "X" } # Invalid type
          ],
          hash_key: "id"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates billing mode enumeration" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid-billing",
          billing_mode: "INVALID_MODE",
          attribute: [{ name: "id", type: "S" }],
          hash_key: "id"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates stream view type enumeration" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid-stream",
          billing_mode: "PAY_PER_REQUEST",
          attribute: [{ name: "id", type: "S" }],
          hash_key: "id",
          stream_enabled: true,
          stream_view_type: "INVALID_TYPE"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "validates table class enumeration" do
      expect {
        Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "invalid-class",
          billing_mode: "PAY_PER_REQUEST",
          attribute: [{ name: "id", type: "S" }],
          hash_key: "id",
          table_class: "INVALID_CLASS"
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "automatically enables stream when view type is specified" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "auto-stream",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id",
        stream_view_type: "KEYS_ONLY"
        # stream_enabled not specified but should be auto-enabled
      })
      
      expect(attrs.stream_enabled).to eq(true)
      expect(attrs.has_stream?).to eq(true)
    end
    
    it "computes estimated monthly cost for provisioned mode" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "cost-test",
        billing_mode: "PROVISIONED",
        read_capacity: 100,
        write_capacity: 50,
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id"
      })
      
      cost = attrs.estimated_monthly_cost
      expect(cost).to include("$")
      expect(cost).to include("/month")
      expect(cost).not_to include("Variable")
    end
    
    it "returns variable cost for pay per request mode" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "variable-cost",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id"
      })
      
      cost = attrs.estimated_monthly_cost
      expect(cost).to include("Variable")
      expect(cost).to include("Pay per request")
    end
  end
  
  describe "aws_dynamodb_table function" do
    it "creates basic DynamoDB table resource reference" do
      result = test_instance.aws_dynamodb_table(:users, {
        name: "users",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id"
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_dynamodb_table')
      expect(result.name).to eq(:users)
    end
    
    it "returns DynamoDB table reference with terraform outputs" do
      result = test_instance.aws_dynamodb_table(:orders, {
        name: "orders",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "pk", type: "S" },
          { name: "sk", type: "S" }
        ],
        hash_key: "pk",
        range_key: "sk"
      })
      
      expect(result.id).to eq("${aws_dynamodb_table.orders.id}")
      expect(result.arn).to eq("${aws_dynamodb_table.orders.arn}")
      expect(result.name).to eq("${aws_dynamodb_table.orders.name}")
      expect(result.hash_key).to eq("${aws_dynamodb_table.orders.hash_key}")
      expect(result.range_key).to eq("${aws_dynamodb_table.orders.range_key}")
      expect(result.billing_mode).to eq("${aws_dynamodb_table.orders.billing_mode}")
    end
    
    it "returns DynamoDB table reference with computed properties" do
      result = test_instance.aws_dynamodb_table(:analytics, {
        name: "analytics",
        billing_mode: "PROVISIONED",
        read_capacity: 100,
        write_capacity: 50,
        attribute: [
          { name: "pk", type: "S" },
          { name: "sk", type: "S" },
          { name: "gsi1pk", type: "S" }
        ],
        hash_key: "pk",
        range_key: "sk",
        global_secondary_index: [
          {
            name: "GSI1",
            hash_key: "gsi1pk",
            read_capacity: 25,
            write_capacity: 25
          }
        ]
      })
      
      expect(result.is_provisioned?).to eq(true)
      expect(result.is_pay_per_request?).to eq(false)
      expect(result.has_range_key?).to eq(true)
      expect(result.has_gsi?).to eq(true)
      expect(result.has_lsi?).to eq(false)
      expect(result.has_stream?).to eq(false)
      expect(result.has_ttl?).to eq(false)
      expect(result.has_encryption?).to eq(false)
      expect(result.has_pitr?).to eq(false)
      expect(result.is_global_table?).to eq(false)
      expect(result.total_indexes).to eq(1)
    end
    
    it "returns DynamoDB table reference with streaming properties" do
      result = test_instance.aws_dynamodb_table(:events, {
        name: "events",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id",
        stream_enabled: true,
        stream_view_type: "NEW_AND_OLD_IMAGES"
      })
      
      expect(result.has_stream?).to eq(true)
      expect(result.stream_arn).to eq("${aws_dynamodb_table.events.stream_arn}")
      expect(result.stream_label).to eq("${aws_dynamodb_table.events.stream_label}")
    end
    
    it "returns DynamoDB table reference with security features" do
      result = test_instance.aws_dynamodb_table(:secure, {
        name: "secure-data",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id",
        server_side_encryption: {
          enabled: true,
          kms_key_id: kms_key_arn
        },
        point_in_time_recovery_enabled: true,
        deletion_protection_enabled: true
      })
      
      expect(result.has_encryption?).to eq(true)
      expect(result.has_pitr?).to eq(true)
    end
    
    it "returns DynamoDB table reference for global table" do
      result = test_instance.aws_dynamodb_table(:global, {
        name: "global-users",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id",
        replica: [
          { region_name: "us-west-2" },
          { region_name: "eu-west-1" }
        ]
      })
      
      expect(result.is_global_table?).to eq(true)
    end
    
    it "returns DynamoDB table reference with comprehensive configuration" do
      result = test_instance.aws_dynamodb_table(:comprehensive, {
        name: "comprehensive-table",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "pk", type: "S" },
          { name: "sk", type: "S" },
          { name: "gsi1pk", type: "S" },
          { name: "lsi1sk", type: "N" }
        ],
        hash_key: "pk",
        range_key: "sk",
        global_secondary_index: [
          {
            name: "GSI1",
            hash_key: "gsi1pk",
            projection_type: "INCLUDE",
            non_key_attributes: ["attr1", "attr2"]
          }
        ],
        local_secondary_index: [
          {
            name: "LSI1", 
            range_key: "lsi1sk",
            projection_type: "ALL"
          }
        ],
        ttl: {
          attribute_name: "expires_at",
          enabled: true
        },
        stream_enabled: true,
        stream_view_type: "NEW_AND_OLD_IMAGES",
        point_in_time_recovery_enabled: true,
        server_side_encryption: {
          enabled: true,
          kms_key_id: kms_key_arn
        },
        deletion_protection_enabled: true,
        table_class: "STANDARD_INFREQUENT_ACCESS",
        tags: {
          Environment: "production",
          Service: "core"
        }
      })
      
      expect(result.has_gsi?).to eq(true)
      expect(result.has_lsi?).to eq(true)
      expect(result.has_ttl?).to eq(true)
      expect(result.has_stream?).to eq(true)
      expect(result.has_encryption?).to eq(true)
      expect(result.has_pitr?).to eq(true)
      expect(result.total_indexes).to eq(2)
      expect(result.estimated_monthly_cost).to include("Variable")
    end
  end
  
  describe "DynamoDB configuration patterns" do
    it "supports simple user table pattern" do
      result = test_instance.aws_dynamodb_table(:users, {
        name: "users",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id"
      })
      
      expect(result.is_pay_per_request?).to eq(true)
      expect(result.has_range_key?).to eq(false)
    end
    
    it "supports order management pattern" do
      result = test_instance.aws_dynamodb_table(:orders, {
        name: "orders",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "customer_id", type: "S" },
          { name: "order_date", type: "S" },
          { name: "status", type: "S" }
        ],
        hash_key: "customer_id",
        range_key: "order_date",
        global_secondary_index: [
          {
            name: "status-index",
            hash_key: "status",
            range_key: "order_date",
            projection_type: "ALL"
          }
        ]
      })
      
      expect(result.has_range_key?).to eq(true)
      expect(result.has_gsi?).to eq(true)
      expect(result.total_indexes).to eq(1)
    end
    
    it "supports high-throughput pattern" do
      result = test_instance.aws_dynamodb_table(:high_throughput, {
        name: "high-throughput",
        billing_mode: "PROVISIONED",
        read_capacity: 5000,
        write_capacity: 2000,
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id",
        point_in_time_recovery_enabled: true,
        server_side_encryption: { enabled: true }
      })
      
      expect(result.is_provisioned?).to eq(true)
      expect(result.has_pitr?).to eq(true)
      expect(result.has_encryption?).to eq(true)
    end
    
    it "supports session management pattern" do
      result = test_instance.aws_dynamodb_table(:sessions, {
        name: "user-sessions",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [{ name: "session_id", type: "S" }],
        hash_key: "session_id",
        ttl: {
          attribute_name: "expires_at",
          enabled: true
        }
      })
      
      expect(result.has_ttl?).to eq(true)
    end
    
    it "supports event sourcing pattern" do
      result = test_instance.aws_dynamodb_table(:events, {
        name: "event-store",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "aggregate_id", type: "S" },
          { name: "sequence_number", type: "N" }
        ],
        hash_key: "aggregate_id",
        range_key: "sequence_number",
        stream_enabled: true,
        stream_view_type: "NEW_AND_OLD_IMAGES"
      })
      
      expect(result.has_range_key?).to eq(true)
      expect(result.has_stream?).to eq(true)
    end
    
    it "supports multi-tenant pattern" do
      result = test_instance.aws_dynamodb_table(:multi_tenant, {
        name: "multi-tenant-data",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "tenant_id", type: "S" },
          { name: "entity_id", type: "S" },
          { name: "created_at", type: "S" },
          { name: "entity_type", type: "S" }
        ],
        hash_key: "tenant_id",
        range_key: "entity_id",
        global_secondary_index: [
          {
            name: "tenant-created-index",
            hash_key: "tenant_id",
            range_key: "created_at",
            projection_type: "ALL"
          },
          {
            name: "tenant-type-index",
            hash_key: "tenant_id",
            range_key: "entity_type",
            projection_type: "KEYS_ONLY"
          }
        ]
      })
      
      expect(result.has_gsi?).to eq(true)
      expect(result.total_indexes).to eq(2)
    end
    
    it "supports analytics pattern with sparse GSI" do
      result = test_instance.aws_dynamodb_table(:analytics, {
        name: "analytics-data",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "partition", type: "S" },
          { name: "timestamp", type: "S" },
          { name: "metric_type", type: "S" }
        ],
        hash_key: "partition",
        range_key: "timestamp",
        global_secondary_index: [
          {
            name: "metric-type-index",
            hash_key: "metric_type",
            range_key: "timestamp",
            projection_type: "INCLUDE",
            non_key_attributes: ["value", "tags"]
          }
        ]
      })
      
      expect(result.has_gsi?).to eq(true)
      expect(result.total_indexes).to eq(1)
    end
    
    it "supports global application pattern" do
      result = test_instance.aws_dynamodb_table(:global_app, {
        name: "global-application",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id",
        server_side_encryption: {
          enabled: true,
          kms_key_id: kms_key_arn
        },
        point_in_time_recovery_enabled: true,
        replica: [
          {
            region_name: "us-west-2",
            kms_key_id: kms_key_arn,
            point_in_time_recovery: true
          },
          {
            region_name: "eu-west-1",
            table_class: "STANDARD_INFREQUENT_ACCESS"
          },
          {
            region_name: "ap-southeast-1"
          }
        ]
      })
      
      expect(result.is_global_table?).to eq(true)
      expect(result.has_encryption?).to eq(true)
      expect(result.has_pitr?).to eq(true)
    end
  end
  
  describe "validation edge cases" do
    it "handles minimum attribute requirements" do
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "minimal",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id"
      })
      
      expect(attrs.attribute.size).to eq(1)
      expect(attrs.global_secondary_index).to be_empty
      expect(attrs.local_secondary_index).to be_empty
      expect(attrs.total_indexes).to eq(0)
    end
    
    it "handles boundary capacity values" do
      # Test minimum values
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "boundary-min",
        billing_mode: "PROVISIONED",
        read_capacity: 1,
        write_capacity: 1,
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id"
      })
      
      expect(attrs.read_capacity).to eq(1)
      expect(attrs.write_capacity).to eq(1)
      
      # Test maximum values
      attrs_max = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "boundary-max",
        billing_mode: "PROVISIONED",
        read_capacity: 40000,
        write_capacity: 40000,
        attribute: [{ name: "id", type: "S" }],
        hash_key: "id"
      })
      
      expect(attrs_max.read_capacity).to eq(40000)
      expect(attrs_max.write_capacity).to eq(40000)
    end
    
    it "handles all stream view types" do
      view_types = ["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"]
      
      view_types.each do |view_type|
        attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "stream-#{view_type.downcase.gsub('_', '-')}",
          billing_mode: "PAY_PER_REQUEST",
          attribute: [{ name: "id", type: "S" }],
          hash_key: "id",
          stream_view_type: view_type
        })
        
        expect(attrs.stream_view_type).to eq(view_type)
        expect(attrs.stream_enabled).to eq(true)
      end
    end
    
    it "handles all attribute types" do
      types = ["S", "N", "B"]
      
      types.each_with_index do |type, index|
        attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
          name: "type-#{type}",
          billing_mode: "PAY_PER_REQUEST",
          attribute: [{ name: "key#{index}", type: type }],
          hash_key: "key#{index}"
        })
        
        expect(attrs.attribute[0][:type]).to eq(type)
      end
    end
    
    it "handles maximum number of indexes within limits" do
      # Test maximum GSIs (20)
      gsis = (1..20).map do |i|
        { name: "GSI#{i}", hash_key: "gsi#{i}pk" }
      end
      
      gsi_attributes = (1..20).map { |i| { name: "gsi#{i}pk", type: "S" } }
      gsi_attributes << { name: "id", type: "S" }
      
      attrs = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "max-gsis",
        billing_mode: "PAY_PER_REQUEST",
        attribute: gsi_attributes,
        hash_key: "id",
        global_secondary_index: gsis
      })
      
      expect(attrs.global_secondary_index.size).to eq(20)
      expect(attrs.total_indexes).to eq(20)
      
      # Test maximum LSIs (10)
      lsis = (1..10).map do |i|
        { name: "LSI#{i}", range_key: "lsi#{i}sk" }
      end
      
      lsi_attributes = (1..10).map { |i| { name: "lsi#{i}sk", type: "S" } }
      lsi_attributes << { name: "pk", type: "S" }
      lsi_attributes << { name: "sk", type: "S" }
      
      attrs_lsi = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "max-lsis",
        billing_mode: "PAY_PER_REQUEST",
        attribute: lsi_attributes,
        hash_key: "pk",
        range_key: "sk",
        local_secondary_index: lsis
      })
      
      expect(attrs_lsi.local_secondary_index.size).to eq(10)
      expect(attrs_lsi.total_indexes).to eq(10)
    end
    
    it "handles complex GSI projection configurations" do
      # Test ALL projection
      attrs_all = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "projection-all",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" },
          { name: "gsi1pk", type: "S" }
        ],
        hash_key: "id",
        global_secondary_index: [
          {
            name: "GSI1",
            hash_key: "gsi1pk",
            projection_type: "ALL"
          }
        ]
      })
      
      expect(attrs_all.global_secondary_index[0][:projection_type]).to eq("ALL")
      
      # Test KEYS_ONLY projection
      attrs_keys = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "projection-keys",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" },
          { name: "gsi1pk", type: "S" }
        ],
        hash_key: "id",
        global_secondary_index: [
          {
            name: "GSI1",
            hash_key: "gsi1pk",
            projection_type: "KEYS_ONLY"
          }
        ]
      })
      
      expect(attrs_keys.global_secondary_index[0][:projection_type]).to eq("KEYS_ONLY")
      
      # Test INCLUDE projection
      attrs_include = Pangea::Resources::AWS::Types::DynamoDbTableAttributes.new({
        name: "projection-include",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" },
          { name: "gsi1pk", type: "S" }
        ],
        hash_key: "id",
        global_secondary_index: [
          {
            name: "GSI1",
            hash_key: "gsi1pk",
            projection_type: "INCLUDE",
            non_key_attributes: ["attr1", "attr2", "attr3"]
          }
        ]
      })
      
      expect(attrs_include.global_secondary_index[0][:projection_type]).to eq("INCLUDE")
      expect(attrs_include.global_secondary_index[0][:non_key_attributes]).to eq(["attr1", "attr2", "attr3"])
    end
  end
end