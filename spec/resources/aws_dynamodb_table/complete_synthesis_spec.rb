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
require 'json'

# Load aws_dynamodb_table resource and terraform-synthesizer for testing
require 'pangea/resources/aws_dynamodb_table/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_dynamodb_table terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }

  # Test simple hash key table synthesis
  it "synthesizes simple hash key table correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:users, {
        name: "users",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id"
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig(:resource, :aws_dynamodb_table, :users)
    
    expect(table_config[:table_name]).to eq("users")
    expect(table_config[:billing_mode]).to eq("PAY_PER_REQUEST")
    expect(table_config[:hash_key]).to eq("id")
    expect(table_config[:attribute]).to be_a(Hash)
    expect(table_config[:attribute][:name]).to eq("id")
    expect(table_config[:attribute][:type]).to eq("S")
    expect(table_config[:point_in_time_recovery][:enabled]).to eq(false)
    expect(table_config[:deletion_protection_enabled]).to eq(false)
    expect(table_config[:table_class]).to eq("STANDARD")
  end

  # Test composite key table synthesis
  it "synthesizes composite key table correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:orders, {
        name: "orders",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "customer_id", type: "S" },
          { name: "order_date", type: "S" }
        ],
        hash_key: "customer_id",
        range_key: "order_date"
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "orders")
    
    expect(table_config["table_name"]).to eq("orders")
    expect(table_config["hash_key"]).to eq("customer_id")
    expect(table_config["range_key"]).to eq("order_date")
    expect(table_config["attribute"].size).to eq(2)
  end

  # Test provisioned billing mode synthesis
  it "synthesizes provisioned billing mode correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:high_throughput, {
        name: "high-throughput",
        billing_mode: "PROVISIONED",
        read_capacity: 1000,
        write_capacity: 500,
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id"
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "high_throughput")
    
    expect(table_config["table_name"]).to eq("high-throughput")
    expect(table_config["billing_mode"]).to eq("PROVISIONED")
    expect(table_config["read_capacity"]).to eq(1000)
    expect(table_config["write_capacity"]).to eq(500)
  end

  # Test Global Secondary Index synthesis
  it "synthesizes table with GSI correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:analytics, {
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
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "analytics")
    
    expect(table_config["global_secondary_index"]).to be_an(Array)
    expect(table_config["global_secondary_index"].size).to eq(1)
    
    gsi = table_config["global_secondary_index"][0]
    expect(gsi["name"]).to eq("GSI1")
    expect(gsi["hash_key"]).to eq("gsi1pk")
    expect(gsi["range_key"]).to eq("gsi1sk")
    expect(gsi["projection_type"]).to eq("ALL")
  end

  # Test Local Secondary Index synthesis
  it "synthesizes table with LSI correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:products, {
        name: "products",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "category", type: "S" },
          { name: "product_id", type: "S" },
          { name: "price", type: "N" }
        ],
        hash_key: "category",
        range_key: "product_id",
        local_secondary_index: [
          {
            name: "price-index",
            range_key: "price",
            projection_type: "KEYS_ONLY"
          }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "products")
    
    expect(table_config["local_secondary_index"]).to be_an(Array)
    expect(table_config["local_secondary_index"].size).to eq(1)
    
    lsi = table_config["local_secondary_index"][0]
    expect(lsi["name"]).to eq("price-index")
    expect(lsi["range_key"]).to eq("price")
    expect(lsi["projection_type"]).to eq("KEYS_ONLY")
  end

  # Test TTL configuration synthesis
  it "synthesizes table with TTL correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:sessions, {
        name: "user-sessions",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "session_id", type: "S" }
        ],
        hash_key: "session_id",
        ttl: {
          attribute_name: "expires_at",
          enabled: true
        }
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "sessions")
    
    expect(table_config["ttl"]).to be_a(Hash)
    expect(table_config["ttl"]["attribute_name"]).to eq("expires_at")
    expect(table_config["ttl"]["enabled"]).to eq(true)
  end

  # Test stream configuration synthesis
  it "synthesizes table with streams correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:events, {
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
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "events")
    
    expect(table_config["stream_enabled"]).to eq(true)
    expect(table_config["stream_view_type"]).to eq("NEW_AND_OLD_IMAGES")
  end

  # Test encryption configuration synthesis
  it "synthesizes table with encryption correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:secure, {
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
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "secure")
    
    expect(table_config["server_side_encryption"]).to be_a(Hash)
    expect(table_config["server_side_encryption"]["enabled"]).to eq(true)
    expect(table_config["server_side_encryption"]["kms_key_id"]).to eq(kms_key_arn)
  end

  # Test point-in-time recovery synthesis
  it "synthesizes table with PITR correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:backups, {
        name: "backup-enabled",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id",
        point_in_time_recovery_enabled: true
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "backups")
    
    expect(table_config["point_in_time_recovery"]["enabled"]).to eq(true)
  end

  # Test Global Table replica synthesis
  it "synthesizes global table with replicas correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:global, {
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
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "global")
    
    expect(table_config["replica"]).to be_an(Array)
    expect(table_config["replica"].size).to eq(2)
    
    replica1 = table_config["replica"][0]
    expect(replica1["region_name"]).to eq("us-west-2")
    expect(replica1["kms_key_id"]).to eq(kms_key_arn)
    expect(replica1["point_in_time_recovery"]).to eq(true)
    
    replica2 = table_config["replica"][1]
    expect(replica2["region_name"]).to eq("eu-west-1")
    expect(replica2["table_class"]).to eq("STANDARD_INFREQUENT_ACCESS")
  end

  # Test comprehensive table configuration synthesis
  it "synthesizes comprehensive table configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:comprehensive, {
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
          Service: "core",
          Team: "platform"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "comprehensive")
    
    expect(table_config["table_name"]).to eq("comprehensive-table")
    expect(table_config["billing_mode"]).to eq("PAY_PER_REQUEST")
    expect(table_config["hash_key"]).to eq("pk")
    expect(table_config["range_key"]).to eq("sk")
    
    # Verify GSI configuration
    expect(table_config["global_secondary_index"].size).to eq(1)
    gsi = table_config["global_secondary_index"][0]
    expect(gsi["name"]).to eq("GSI1")
    expect(gsi["hash_key"]).to eq("gsi1pk")
    expect(gsi["projection_type"]).to eq("INCLUDE")
    expect(gsi["non_key_attributes"]).to eq(["attr1", "attr2"])
    
    # Verify LSI configuration
    expect(table_config["local_secondary_index"].size).to eq(1)
    lsi = table_config["local_secondary_index"][0]
    expect(lsi["name"]).to eq("LSI1")
    expect(lsi["range_key"]).to eq("lsi1sk")
    expect(lsi["projection_type"]).to eq("ALL")
    
    # Verify other configurations
    expect(table_config["ttl"]["attribute_name"]).to eq("expires_at")
    expect(table_config["stream_enabled"]).to eq(true)
    expect(table_config["stream_view_type"]).to eq("NEW_AND_OLD_IMAGES")
    expect(table_config["point_in_time_recovery"]["enabled"]).to eq(true)
    expect(table_config["server_side_encryption"]["enabled"]).to eq(true)
    expect(table_config["server_side_encryption"]["kms_key_id"]).to eq(kms_key_arn)
    expect(table_config["deletion_protection_enabled"]).to eq(true)
    expect(table_config["table_class"]).to eq("STANDARD_INFREQUENT_ACCESS")
    
    expect(table_config["tags"]).to eq({
      "Environment" => "production",
      "Service" => "core",
      "Team" => "platform"
    })
  end

  # Test provisioned GSI synthesis
  it "synthesizes provisioned table with GSI capacities correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:provisioned_gsi, {
        name: "provisioned-with-gsi",
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
            write_capacity: 25,
            projection_type: "ALL"
          }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "provisioned_gsi")
    
    expect(table_config["billing_mode"]).to eq("PROVISIONED")
    expect(table_config["read_capacity"]).to eq(100)
    expect(table_config["write_capacity"]).to eq(50)
    
    gsi = table_config["global_secondary_index"][0]
    expect(gsi["read_capacity"]).to eq(25)
    expect(gsi["write_capacity"]).to eq(25)
  end

  # Test all stream view types synthesis
  it "synthesizes different stream view types correctly" do
    view_types = ["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"]
    
    view_types.each do |view_type|
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        
        aws_dynamodb_table(:"stream_#{view_type.downcase.gsub('_', '')}", {
          name: "stream-#{view_type.downcase.gsub('_', '-')}",
          billing_mode: "PAY_PER_REQUEST",
          attribute: [
            { name: "id", type: "S" }
          ],
          hash_key: "id",
          stream_enabled: true,
          stream_view_type: view_type
        })
      end
      
      json_output = synthesizer.synthesis
      table_name = "stream_#{view_type.downcase.gsub('_', '')}"
      table_config = json_output.dig("resource", "aws_dynamodb_table", table_name)
      
      expect(table_config["stream_enabled"]).to eq(true)
      expect(table_config["stream_view_type"]).to eq(view_type)
    end
  end

  # Test multiple attribute types synthesis
  it "synthesizes table with different attribute types correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:mixed_types, {
        name: "mixed-attribute-types",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "string_key", type: "S" },
          { name: "number_key", type: "N" },
          { name: "binary_key", type: "B" }
        ],
        hash_key: "string_key",
        global_secondary_index: [
          {
            name: "number-index",
            hash_key: "number_key",
            projection_type: "KEYS_ONLY"
          },
          {
            name: "binary-index",
            hash_key: "binary_key",
            projection_type: "ALL"
          }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "mixed_types")
    
    expect(table_config["attribute"].size).to eq(3)
    
    string_attr = table_config["attribute"].find { |attr| attr["name"] == "string_key" }
    expect(string_attr["type"]).to eq("S")
    
    number_attr = table_config["attribute"].find { |attr| attr["name"] == "number_key" }
    expect(number_attr["type"]).to eq("N")
    
    binary_attr = table_config["attribute"].find { |attr| attr["name"] == "binary_key" }
    expect(binary_attr["type"]).to eq("B")
  end

  # Test table with import configuration synthesis
  it "synthesizes table with import configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:imported, {
        name: "imported-table",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id",
        import_table: {
          input_format: "CSV",
          s3_bucket_source: {
            bucket: "my-import-bucket",
            bucket_owner: "123456789012",
            key_prefix: "imports/"
          },
          input_format_options: {
            csv: {
              delimiter: ",",
              header_list: ["id", "name", "email"]
            }
          },
          input_compression_type: "GZIP"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "imported")
    
    expect(table_config["import_table"]).to be_a(Hash)
    expect(table_config["import_table"]["input_format"]).to eq("CSV")
    
    s3_source = table_config["import_table"]["s3_bucket_source"]
    expect(s3_source["bucket"]).to eq("my-import-bucket")
    expect(s3_source["bucket_owner"]).to eq("123456789012")
    expect(s3_source["key_prefix"]).to eq("imports/")
    
    csv_options = table_config["import_table"]["input_format_options"]["csv"]
    expect(csv_options["delimiter"]).to eq(",")
    expect(csv_options["header_list"]).to eq(["id", "name", "email"])
    
    expect(table_config["import_table"]["input_compression_type"]).to eq("GZIP")
  end

  # Test standard infrequent access table class synthesis
  it "synthesizes table with infrequent access class correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:infrequent, {
        name: "infrequent-access",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id",
        table_class: "STANDARD_INFREQUENT_ACCESS"
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "infrequent")
    
    expect(table_config["table_class"]).to eq("STANDARD_INFREQUENT_ACCESS")
  end

  # Test minimal table configuration synthesis
  it "synthesizes minimal table without optional fields" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:minimal, {
        name: "minimal-table",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "id", type: "S" }
        ],
        hash_key: "id"
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "minimal")
    
    expect(table_config["table_name"]).to eq("minimal-table")
    expect(table_config["billing_mode"]).to eq("PAY_PER_REQUEST")
    expect(table_config["hash_key"]).to eq("id")
    
    # Optional fields should not be present when not specified
    expect(table_config).not_to have_key("range_key")
    expect(table_config).not_to have_key("read_capacity")
    expect(table_config).not_to have_key("write_capacity")
    expect(table_config).not_to have_key("global_secondary_index")
    expect(table_config).not_to have_key("local_secondary_index")
    expect(table_config).not_to have_key("ttl")
    expect(table_config).not_to have_key("stream_enabled")
    expect(table_config).not_to have_key("server_side_encryption")
    expect(table_config).not_to have_key("replica")
    expect(table_config).not_to have_key("import_table")
  end

  # Test e-commerce order pattern synthesis
  it "synthesizes e-commerce order pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:ecommerce_orders, {
        name: "ecommerce-orders",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "customer_id", type: "S" },
          { name: "order_date", type: "S" },
          { name: "status", type: "S" },
          { name: "total_amount", type: "N" }
        ],
        hash_key: "customer_id",
        range_key: "order_date",
        global_secondary_index: [
          {
            name: "status-index",
            hash_key: "status",
            range_key: "order_date",
            projection_type: "ALL"
          },
          {
            name: "amount-index",
            hash_key: "customer_id",
            range_key: "total_amount",
            projection_type: "INCLUDE",
            non_key_attributes: ["status", "order_id"]
          }
        ],
        stream_enabled: true,
        stream_view_type: "NEW_AND_OLD_IMAGES",
        tags: {
          Service: "ecommerce",
          Pattern: "order-management"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "ecommerce_orders")
    
    expect(table_config["hash_key"]).to eq("customer_id")
    expect(table_config["range_key"]).to eq("order_date")
    expect(table_config["global_secondary_index"].size).to eq(2)
    expect(table_config["stream_enabled"]).to eq(true)
    expect(table_config["tags"]["Pattern"]).to eq("order-management")
  end

  # Test multi-tenant SaaS pattern synthesis
  it "synthesizes multi-tenant SaaS pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:multitenant, {
        name: "multitenant-data",
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
        ],
        local_secondary_index: [
          {
            name: "entity-created-index",
            range_key: "created_at",
            projection_type: "INCLUDE",
            non_key_attributes: ["entity_type", "updated_at"]
          }
        ],
        server_side_encryption: {
          enabled: true,
          kms_key_id: kms_key_arn
        },
        point_in_time_recovery_enabled: true
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "multitenant")
    
    expect(table_config["hash_key"]).to eq("tenant_id")
    expect(table_config["range_key"]).to eq("entity_id")
    expect(table_config["global_secondary_index"].size).to eq(2)
    expect(table_config["local_secondary_index"].size).to eq(1)
    expect(table_config["server_side_encryption"]["enabled"]).to eq(true)
    expect(table_config["point_in_time_recovery"]["enabled"]).to eq(true)
  end

  # Test high-performance gaming leaderboard pattern synthesis
  it "synthesizes gaming leaderboard pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:leaderboard, {
        name: "gaming-leaderboard",
        billing_mode: "PROVISIONED",
        read_capacity: 5000,
        write_capacity: 1000,
        attribute: [
          { name: "game_id", type: "S" },
          { name: "score", type: "N" },
          { name: "player_id", type: "S" },
          { name: "timestamp", type: "S" }
        ],
        hash_key: "game_id",
        range_key: "score",
        global_secondary_index: [
          {
            name: "player-index",
            hash_key: "player_id",
            range_key: "timestamp",
            read_capacity: 100,
            write_capacity: 100,
            projection_type: "ALL"
          }
        ],
        local_secondary_index: [
          {
            name: "recent-scores",
            range_key: "timestamp",
            projection_type: "ALL"
          }
        ],
        stream_enabled: true,
        stream_view_type: "NEW_IMAGE",
        tags: {
          Service: "gaming",
          Pattern: "leaderboard",
          Performance: "high-throughput"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "leaderboard")
    
    expect(table_config["billing_mode"]).to eq("PROVISIONED")
    expect(table_config["read_capacity"]).to eq(5000)
    expect(table_config["write_capacity"]).to eq(1000)
    expect(table_config["hash_key"]).to eq("game_id")
    expect(table_config["range_key"]).to eq("score")
    
    gsi = table_config["global_secondary_index"][0]
    expect(gsi["read_capacity"]).to eq(100)
    expect(gsi["write_capacity"]).to eq(100)
    
    expect(table_config["stream_view_type"]).to eq("NEW_IMAGE")
    expect(table_config["tags"]["Performance"]).to eq("high-throughput")
  end

  # Test IoT sensor data pattern synthesis
  it "synthesizes IoT sensor data pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_dynamodb_table(:iot_data, {
        name: "iot-sensor-data",
        billing_mode: "PAY_PER_REQUEST",
        attribute: [
          { name: "device_id", type: "S" },
          { name: "timestamp", type: "S" },
          { name: "sensor_type", type: "S" }
        ],
        hash_key: "device_id",
        range_key: "timestamp",
        global_secondary_index: [
          {
            name: "sensor-type-index",
            hash_key: "sensor_type",
            range_key: "timestamp",
            projection_type: "INCLUDE",
            non_key_attributes: ["value", "location", "battery_level"]
          }
        ],
        ttl: {
          attribute_name: "expires_at",
          enabled: true
        },
        stream_enabled: true,
        stream_view_type: "KEYS_ONLY",
        table_class: "STANDARD_INFREQUENT_ACCESS",
        tags: {
          Service: "iot",
          Pattern: "time-series",
          DataRetention: "30-days"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    table_config = json_output.dig("resource", "aws_dynamodb_table", "iot_data")
    
    expect(table_config["hash_key"]).to eq("device_id")
    expect(table_config["range_key"]).to eq("timestamp")
    expect(table_config["ttl"]["attribute_name"]).to eq("expires_at")
    expect(table_config["table_class"]).to eq("STANDARD_INFREQUENT_ACCESS")
    
    gsi = table_config["global_secondary_index"][0]
    expect(gsi["projection_type"]).to eq("INCLUDE")
    expect(gsi["non_key_attributes"]).to eq(["value", "location", "battery_level"])
    
    expect(table_config["tags"]["Pattern"]).to eq("time-series")
  end
end