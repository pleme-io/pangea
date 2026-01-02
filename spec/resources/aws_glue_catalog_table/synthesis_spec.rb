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
require 'terraform-synthesizer'
require 'pangea/resources/aws_glue_catalog_table/resource'

RSpec.describe "aws_glue_catalog_table synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_table(:test, {
          name: "test_table",
          database_name: "test_database"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_glue_catalog_table")
      expect(result["resource"]["aws_glue_catalog_table"]).to have_key("test")
    end

    it "includes required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_table(:test, {
          name: "events_table",
          database_name: "analytics_db",
          description: "Events tracking table"
        })
      end

      result = synthesizer.synthesis
      table_config = result["resource"]["aws_glue_catalog_table"]["test"]

      expect(table_config["database_name"]).to eq("analytics_db")
      expect(table_config).to have_key("table_input")
      expect(table_config["table_input"]["name"]).to eq("events_table")
      expect(table_config["table_input"]["description"]).to eq("Events tracking table")
    end

    it "supports table_type for external tables" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_table(:test, {
          name: "external_table",
          database_name: "test_db",
          table_type: "EXTERNAL_TABLE",
          storage_descriptor: {
            location: "s3://bucket/data/"
          }
        })
      end

      result = synthesizer.synthesis
      table_config = result["resource"]["aws_glue_catalog_table"]["test"]

      expect(table_config["table_input"]["table_type"]).to eq("EXTERNAL_TABLE")
    end

    it "supports storage descriptor with columns" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_table(:test, {
          name: "structured_table",
          database_name: "test_db",
          table_type: "EXTERNAL_TABLE",
          storage_descriptor: {
            location: "s3://bucket/data/",
            input_format: "org.apache.hadoop.mapred.TextInputFormat",
            output_format: "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
            columns: [
              { name: "id", type: "bigint", comment: "Primary key" },
              { name: "name", type: "string", comment: "User name" },
              { name: "created_at", type: "timestamp", comment: "Creation timestamp" }
            ],
            serde_info: {
              name: "json_serde",
              serialization_library: "org.apache.hive.hcatalog.data.JsonSerDe"
            }
          }
        })
      end

      result = synthesizer.synthesis
      table_config = result["resource"]["aws_glue_catalog_table"]["test"]
      storage_desc = table_config["table_input"]["storage_descriptor"]

      expect(storage_desc["location"]).to eq("s3://bucket/data/")
      expect(storage_desc["input_format"]).to eq("org.apache.hadoop.mapred.TextInputFormat")
    end

    it "supports partition keys" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_table(:test, {
          name: "partitioned_table",
          database_name: "test_db",
          partition_keys: [
            { name: "year", type: "string" },
            { name: "month", type: "string" },
            { name: "day", type: "string" }
          ]
        })
      end

      result = synthesizer.synthesis
      table_config = result["resource"]["aws_glue_catalog_table"]["test"]

      expect(table_config["table_input"]).to have_key("partition_keys")
    end

    it "supports parameters" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_table(:test, {
          name: "parquet_table",
          database_name: "test_db",
          parameters: {
            "classification" => "parquet",
            "compressionType" => "snappy"
          }
        })
      end

      result = synthesizer.synthesis
      table_config = result["resource"]["aws_glue_catalog_table"]["test"]

      expect(table_config["table_input"]).to have_key("parameters")
    end

    it "supports catalog_id override" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_table(:test, {
          name: "cross_account_table",
          database_name: "shared_db",
          catalog_id: "123456789012"
        })
      end

      result = synthesizer.synthesis
      table_config = result["resource"]["aws_glue_catalog_table"]["test"]

      expect(table_config["catalog_id"]).to eq("123456789012")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_table(:test, {
          name: "valid_table",
          database_name: "valid_db"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_glue_catalog_table"]).to be_a(Hash)
      expect(result["resource"]["aws_glue_catalog_table"]["test"]).to be_a(Hash)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_catalog_table(:test, {
          name: "ref_test_table",
          database_name: "ref_test_db"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_glue_catalog_table.test.id}")
      expect(ref.outputs[:name]).to eq("${aws_glue_catalog_table.test.name}")
      expect(ref.outputs[:database_name]).to eq("${aws_glue_catalog_table.test.database_name}")
      expect(ref.outputs[:arn]).to eq("${aws_glue_catalog_table.test.arn}")
    end

    it "returns computed properties for partitioned tables" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_catalog_table(:test, {
          name: "partitioned",
          database_name: "test_db",
          partition_keys: [
            { name: "date", type: "string" }
          ]
        })
      end

      expect(ref.computed_properties[:is_partitioned]).to eq(true)
    end

    it "returns computed properties for external tables" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_catalog_table(:test, {
          name: "external",
          database_name: "test_db",
          table_type: "EXTERNAL_TABLE",
          storage_descriptor: {
            location: "s3://bucket/path/"
          }
        })
      end

      expect(ref.computed_properties[:is_external]).to eq(true)
    end
  end
end
