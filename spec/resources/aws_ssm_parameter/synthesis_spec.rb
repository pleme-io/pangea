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
require 'pangea/resources/aws_ssm_parameter/resource'

RSpec.describe "aws_ssm_parameter synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for String type" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_parameter(:test, {
          name: "/test/parameter",
          type: "String",
          value: "test-value"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_ssm_parameter")
      expect(result["resource"]["aws_ssm_parameter"]).to have_key("test")

      param_config = result["resource"]["aws_ssm_parameter"]["test"]
      expect(param_config["name"]).to eq("/test/parameter")
      expect(param_config["type"]).to eq("String")
      expect(param_config["value"]).to eq("test-value")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_parameter(:test, {
          name: "/tagged/parameter",
          type: "String",
          value: "tagged-value",
          tags: { Name: "test-param", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      param_config = result["resource"]["aws_ssm_parameter"]["test"]

      expect(param_config).to have_key("tags")
      expect(param_config["tags"]["Name"]).to eq("test-param")
      expect(param_config["tags"]["Environment"]).to eq("test")
    end

    it "supports SecureString type with KMS key" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_parameter(:test, {
          name: "/secure/parameter",
          type: "SecureString",
          value: "secret-value",
          key_id: "alias/my-key"
        })
      end

      result = synthesizer.synthesis
      param_config = result["resource"]["aws_ssm_parameter"]["test"]

      expect(param_config["type"]).to eq("SecureString")
      expect(param_config["key_id"]).to eq("alias/my-key")
    end

    it "supports StringList type" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_parameter(:test, {
          name: "/list/parameter",
          type: "StringList",
          value: "value1,value2,value3"
        })
      end

      result = synthesizer.synthesis
      param_config = result["resource"]["aws_ssm_parameter"]["test"]

      expect(param_config["type"]).to eq("StringList")
      expect(param_config["value"]).to eq("value1,value2,value3")
    end

    it "supports Advanced tier" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_parameter(:test, {
          name: "/advanced/parameter",
          type: "String",
          value: "large-value",
          tier: "Advanced"
        })
      end

      result = synthesizer.synthesis
      param_config = result["resource"]["aws_ssm_parameter"]["test"]

      expect(param_config["tier"]).to eq("Advanced")
    end

    it "supports description" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_parameter(:test, {
          name: "/described/parameter",
          type: "String",
          value: "described-value",
          description: "A test parameter with description"
        })
      end

      result = synthesizer.synthesis
      param_config = result["resource"]["aws_ssm_parameter"]["test"]

      expect(param_config["description"]).to eq("A test parameter with description")
    end

    it "supports allowed pattern" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_parameter(:test, {
          name: "/pattern/parameter",
          type: "String",
          value: "valid-value",
          allowed_pattern: "^[a-z-]+$"
        })
      end

      result = synthesizer.synthesis
      param_config = result["resource"]["aws_ssm_parameter"]["test"]

      expect(param_config["allowed_pattern"]).to eq("^[a-z-]+$")
    end

    it "supports data type for AMI" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_parameter(:test, {
          name: "/ami/parameter",
          type: "String",
          value: "ami-12345678",
          data_type: "aws:ec2:image"
        })
      end

      result = synthesizer.synthesis
      param_config = result["resource"]["aws_ssm_parameter"]["test"]

      expect(param_config["data_type"]).to eq("aws:ec2:image")
    end

    it "supports overwrite option" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_parameter(:test, {
          name: "/overwrite/parameter",
          type: "String",
          value: "overwrite-value",
          overwrite: true
        })
      end

      result = synthesizer.synthesis
      param_config = result["resource"]["aws_ssm_parameter"]["test"]

      expect(param_config["overwrite"]).to eq(true)
    end

    it "supports hierarchical parameter names" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_parameter(:test, {
          name: "/app/prod/database/connection_string",
          type: "SecureString",
          value: "postgres://user:pass@host:5432/db"
        })
      end

      result = synthesizer.synthesis
      param_config = result["resource"]["aws_ssm_parameter"]["test"]

      expect(param_config["name"]).to eq("/app/prod/database/connection_string")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_ssm_parameter(:test, {
          name: "/validation/parameter",
          type: "String",
          value: "validation-value"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_ssm_parameter"]).to be_a(Hash)
      expect(result["resource"]["aws_ssm_parameter"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      param_config = result["resource"]["aws_ssm_parameter"]["test"]
      expect(param_config).to have_key("name")
      expect(param_config).to have_key("type")
      expect(param_config).to have_key("value")
      expect(param_config["name"]).to be_a(String)
      expect(param_config["type"]).to be_a(String)
      expect(param_config["value"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a resource reference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_ssm_parameter(:test, {
          name: "/reference/parameter",
          type: "String",
          value: "reference-value"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq("aws_ssm_parameter")
      expect(ref.name).to eq(:test)
      expect(ref.outputs[:name]).to eq("${aws_ssm_parameter.test.name}")
      expect(ref.outputs[:arn]).to eq("${aws_ssm_parameter.test.arn}")
      expect(ref.outputs[:type]).to eq("${aws_ssm_parameter.test.type}")
      expect(ref.outputs[:value]).to eq("${aws_ssm_parameter.test.value}")
      expect(ref.outputs[:version]).to eq("${aws_ssm_parameter.test.version}")
    end
  end
end
