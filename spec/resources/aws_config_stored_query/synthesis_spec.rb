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
require 'pangea/resources/aws/config'

RSpec.describe "aws_config_stored_query synthesis" do
  include Pangea::Resources::AWS::Config

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_stored_query(:test, {
          name: "public-s3-buckets",
          expression: "SELECT resourceId, resourceType WHERE resourceType = 'AWS::S3::Bucket'"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_config_stored_query")
      expect(result["resource"]["aws_config_stored_query"]).to have_key("test")

      query_config = result["resource"]["aws_config_stored_query"]["test"]
      expect(query_config["name"]).to eq("public-s3-buckets")
      expect(query_config["expression"]).to include("AWS::S3::Bucket")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_stored_query(:test, {
          name: "public-s3-buckets",
          expression: "SELECT resourceId WHERE resourceType = 'AWS::S3::Bucket'",
          description: "Query to find all S3 buckets"
        })
      end

      result = synthesizer.synthesis
      query_config = result["resource"]["aws_config_stored_query"]["test"]

      expect(query_config["description"]).to eq("Query to find all S3 buckets")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_stored_query(:test, {
          name: "public-s3-buckets",
          expression: "SELECT resourceId WHERE resourceType = 'AWS::S3::Bucket'",
          tags: { Name: "s3-query", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      query_config = result["resource"]["aws_config_stored_query"]["test"]

      expect(query_config).to have_key("tags")
      expect(query_config["tags"]["Name"]).to eq("s3-query")
      expect(query_config["tags"]["Environment"]).to eq("production")
    end

    it "supports complex SQL queries" do
      query = <<~SQL.strip
        SELECT
          resourceId,
          resourceType,
          configuration.instanceType
        WHERE
          resourceType = 'AWS::EC2::Instance'
          AND configuration.instanceType LIKE 't2%'
      SQL

      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_stored_query(:test, {
          name: "t2-instances",
          expression: query
        })
      end

      result = synthesizer.synthesis
      query_config = result["resource"]["aws_config_stored_query"]["test"]

      expect(query_config["expression"]).to include("AWS::EC2::Instance")
      expect(query_config["expression"]).to include("instanceType")
    end

    it "supports aggregation queries" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_stored_query(:test, {
          name: "resource-count-by-type",
          expression: "SELECT COUNT(*), resourceType GROUP BY resourceType"
        })
      end

      result = synthesizer.synthesis
      query_config = result["resource"]["aws_config_stored_query"]["test"]

      expect(query_config["expression"]).to include("COUNT")
      expect(query_config["expression"]).to include("GROUP BY")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        aws_config_stored_query(:test, {
          name: "public-s3-buckets",
          expression: "SELECT resourceId WHERE resourceType = 'AWS::S3::Bucket'"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_config_stored_query"]).to be_a(Hash)
      expect(result["resource"]["aws_config_stored_query"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      query_config = result["resource"]["aws_config_stored_query"]["test"]
      expect(query_config).to have_key("name")
      expect(query_config).to have_key("expression")
      expect(query_config["name"]).to be_a(String)
      expect(query_config["expression"]).to be_a(String)
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS::Config
        ref = aws_config_stored_query(:test, {
          name: "public-s3-buckets",
          expression: "SELECT resourceId WHERE resourceType = 'AWS::S3::Bucket'"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_config_stored_query')
      expect(ref.name).to eq(:test)
      expect(ref.outputs).to have_key(:id)
      expect(ref.outputs).to have_key(:arn)
    end
  end
end
