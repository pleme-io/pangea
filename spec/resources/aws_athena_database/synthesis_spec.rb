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
require 'pangea/resources/aws_athena_database/resource'

RSpec.describe "aws_athena_database synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_database(:test, {
          name: "test_database",
          bucket: "my-athena-bucket"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_athena_database")
      expect(result["resource"]["aws_athena_database"]).to have_key("test")
    end

    it "includes required bucket attribute" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_database(:test, {
          name: "analytics_db",
          bucket: "analytics-data-bucket"
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_athena_database"]["test"]

      expect(db_config["bucket"]).to eq("analytics-data-bucket")
    end

    it "includes comment when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_database(:test, {
          name: "documented_db",
          bucket: "my-bucket",
          comment: "Database for analytics queries"
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_athena_database"]["test"]

      expect(db_config["comment"]).to eq("Database for analytics queries")
    end

    it "supports encryption configuration with SSE_S3" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_database(:test, {
          name: "encrypted_db",
          bucket: "encrypted-bucket",
          encryption_configuration: {
            encryption_option: "SSE_S3"
          }
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_athena_database"]["test"]

      expect(db_config).to have_key("encryption_configuration")
      expect(db_config["encryption_configuration"]["encryption_option"]).to eq("SSE_S3")
    end

    it "supports encryption configuration with SSE_KMS" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_database(:test, {
          name: "kms_encrypted_db",
          bucket: "kms-bucket",
          encryption_configuration: {
            encryption_option: "SSE_KMS",
            kms_key: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
          }
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_athena_database"]["test"]

      expect(db_config["encryption_configuration"]["encryption_option"]).to eq("SSE_KMS")
      expect(db_config["encryption_configuration"]["kms_key"]).to include("arn:aws:kms")
    end

    it "supports force_destroy flag" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_database(:test, {
          name: "destroyable_db",
          bucket: "my-bucket",
          force_destroy: true
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_athena_database"]["test"]

      expect(db_config["force_destroy"]).to eq(true)
    end

    it "supports expected_bucket_owner" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_database(:test, {
          name: "cross_account_db",
          bucket: "shared-bucket",
          expected_bucket_owner: "123456789012"
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_athena_database"]["test"]

      expect(db_config["expected_bucket_owner"]).to eq("123456789012")
    end

    it "supports properties" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_database(:test, {
          name: "properties_db",
          bucket: "my-bucket",
          properties: {
            "classification" => "data_lake",
            "projection.enabled" => "true"
          }
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_athena_database"]["test"]

      expect(db_config).to have_key("properties")
    end

    it "supports acl_configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_database(:test, {
          name: "acl_db",
          bucket: "my-bucket",
          acl_configuration: {
            s3_acl_option: "BUCKET_OWNER_FULL_CONTROL"
          }
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_athena_database"]["test"]

      expect(db_config).to have_key("acl_configuration")
      expect(db_config["acl_configuration"]["s3_acl_option"]).to eq("BUCKET_OWNER_FULL_CONTROL")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_database(:test, {
          name: "tagged_db",
          bucket: "my-bucket",
          tags: { Name: "athena-database", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      db_config = result["resource"]["aws_athena_database"]["test"]

      expect(db_config).to have_key("tags")
      expect(db_config["tags"]["Name"]).to eq("athena-database")
      expect(db_config["tags"]["Environment"]).to eq("production")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_database(:test, {
          name: "valid_db",
          bucket: "valid-bucket"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_athena_database"]).to be_a(Hash)
      expect(result["resource"]["aws_athena_database"]["test"]).to be_a(Hash)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_database(:test, {
          name: "ref_test_db",
          bucket: "test-bucket"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_athena_database.test.id}")
      expect(ref.outputs[:name]).to eq("${aws_athena_database.test.name}")
    end

    it "returns computed properties for encrypted databases" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_database(:test, {
          name: "encrypted_db",
          bucket: "encrypted-bucket",
          encryption_configuration: {
            encryption_option: "SSE_KMS",
            kms_key: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
          }
        })
      end

      expect(ref.computed_properties[:encrypted]).to eq(true)
      expect(ref.computed_properties[:encryption_type]).to eq("SSE_KMS")
      expect(ref.computed_properties[:uses_kms]).to eq(true)
    end

    it "returns computed properties for non-encrypted databases" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_database(:test, {
          name: "plain_db",
          bucket: "plain-bucket"
        })
      end

      expect(ref.computed_properties[:encrypted]).to eq(false)
      expect(ref.computed_properties[:uses_kms]).to eq(false)
    end

    it "returns location_uri in computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_database(:test, {
          name: "location_db",
          bucket: "my-bucket"
        })
      end

      expect(ref.computed_properties[:location_uri]).to eq("s3://my-bucket/location_db/")
    end
  end
end
