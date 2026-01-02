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
require 'pangea/resources/aws_cognito_user_pool_domain/resource'

RSpec.describe "aws_cognito_user_pool_domain synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for Cognito domain prefix" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool_domain(:test, {
          domain: "my-app-auth",
          user_pool_id: "us-east-1_abc123"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cognito_user_pool_domain")
      expect(result["resource"]["aws_cognito_user_pool_domain"]).to have_key("test")

      domain_config = result["resource"]["aws_cognito_user_pool_domain"]["test"]
      expect(domain_config["domain"]).to eq("my-app-auth")
      expect(domain_config["user_pool_id"]).to eq("us-east-1_abc123")
    end

    it "generates valid terraform JSON for custom domain" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool_domain(:test, {
          domain: "auth.example.com",
          user_pool_id: "us-east-1_abc123",
          certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
        })
      end

      result = synthesizer.synthesis
      domain_config = result["resource"]["aws_cognito_user_pool_domain"]["test"]

      expect(domain_config["domain"]).to eq("auth.example.com")
      expect(domain_config["certificate_arn"]).to eq("arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012")
    end

    it "does not include certificate_arn for Cognito domain prefix" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool_domain(:test, {
          domain: "my-app-auth",
          user_pool_id: "us-east-1_abc123"
        })
      end

      result = synthesizer.synthesis
      domain_config = result["resource"]["aws_cognito_user_pool_domain"]["test"]

      expect(domain_config).not_to have_key("certificate_arn")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_cognito_user_pool_domain(:test, {
          domain: "my-app-auth",
          user_pool_id: "us-east-1_abc123"
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_user_pool_domain"]).to be_a(Hash)
      expect(result["resource"]["aws_cognito_user_pool_domain"]["test"]).to be_a(Hash)

      domain_config = result["resource"]["aws_cognito_user_pool_domain"]["test"]
      expect(domain_config).to have_key("domain")
      expect(domain_config).to have_key("user_pool_id")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with correct outputs for Cognito domain" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user_pool_domain(:test, {
          domain: "my-app-auth",
          user_pool_id: "us-east-1_abc123"
        })
      end

      expect(reference).to be_a(Pangea::Resources::ResourceReference)
      expect(reference.outputs[:domain]).to eq("${aws_cognito_user_pool_domain.test.domain}")
      expect(reference.outputs[:cloudfront_distribution_arn]).to eq("${aws_cognito_user_pool_domain.test.cloudfront_distribution_arn}")
    end

    it "includes computed properties for domain type" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user_pool_domain(:test, {
          domain: "my-app-auth",
          user_pool_id: "us-east-1_abc123"
        })
      end

      expect(reference.computed_properties[:cognito_domain]).to eq(true)
      expect(reference.computed_properties[:custom_domain]).to eq(false)
      expect(reference.computed_properties[:domain_type]).to eq(:cognito)
    end

    it "identifies custom domain correctly" do
      reference = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        reference = aws_cognito_user_pool_domain(:test, {
          domain: "auth.example.com",
          user_pool_id: "us-east-1_abc123",
          certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
        })
      end

      expect(reference.computed_properties[:custom_domain]).to eq(true)
      expect(reference.computed_properties[:cognito_domain]).to eq(false)
      expect(reference.computed_properties[:domain_type]).to eq(:custom)
    end
  end
end
