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
require 'pangea/resources/aws_glue_catalog_database/resource'

RSpec.describe "aws_glue_catalog_database synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_database(:test, {
          name: "test_database",
          description: "Test database for Glue catalog"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_glue_catalog_database")
      expect(result["resource"]["aws_glue_catalog_database"]).to have_key("test")
    end

    it "includes database_input block with name" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_database(:test, {
          name: "analytics_db",
          description: "Analytics database"
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_glue_catalog_database"]["test"]

      expect(db_config).to have_key("database_input")
      expect(db_config["database_input"]["name"]).to eq("analytics_db")
      expect(db_config["database_input"]["description"]).to eq("Analytics database")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_database(:test, {
          name: "test_database",
          tags: { Name: "test-db", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_glue_catalog_database"]["test"]

      expect(db_config).to have_key("tags")
      expect(db_config["tags"]["Name"]).to eq("test-db")
      expect(db_config["tags"]["Environment"]).to eq("test")
    end

    it "supports location_uri for external databases" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_database(:test, {
          name: "external_db",
          location_uri: "s3://my-bucket/external-data/"
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_glue_catalog_database"]["test"]

      expect(db_config["database_input"]["location_uri"]).to eq("s3://my-bucket/external-data/")
    end

    it "supports catalog_id override" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_database(:test, {
          name: "cross_account_db",
          catalog_id: "123456789012"
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_glue_catalog_database"]["test"]

      expect(db_config["catalog_id"]).to eq("123456789012")
    end

    it "supports parameters for database configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_database(:test, {
          name: "parameterized_db",
          parameters: {
            "classification" => "data_lake",
            "compressionType" => "gzip"
          }
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_glue_catalog_database"]["test"]

      expect(db_config["database_input"]).to have_key("parameters")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_catalog_database(:test, { name: "valid_db" })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_glue_catalog_database"]).to be_a(Hash)
      expect(result["resource"]["aws_glue_catalog_database"]["test"]).to be_a(Hash)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_catalog_database(:test, { name: "ref_test_db" })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_glue_catalog_database.test.id}")
      expect(ref.outputs[:name]).to eq("${aws_glue_catalog_database.test.name}")
      expect(ref.outputs[:arn]).to eq("${aws_glue_catalog_database.test.arn}")
    end

    it "returns computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_catalog_database(:test, {
          name: "external_db",
          location_uri: "s3://bucket/path/"
        })
      end

      expect(ref.computed_properties[:is_external]).to eq(true)
      expect(ref.computed_properties[:database_type]).to eq("s3")
    end
  end
end
