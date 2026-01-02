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
require 'pangea/resources/aws_customer_gateway/resource'

RSpec.describe "aws_customer_gateway synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with required attributes" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_customer_gateway(:test, {
          bgp_asn: 65000,
          ip_address: "203.0.113.1",
          type: "ipsec.1",
          tags: { Name: "test-customer-gateway" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_customer_gateway")
      expect(result["resource"]["aws_customer_gateway"]).to have_key("test")

      cgw_config = result["resource"]["aws_customer_gateway"]["test"]
      expect(cgw_config["bgp_asn"]).to eq(65000)
      expect(cgw_config["ip_address"]).to eq("203.0.113.1")
      expect(cgw_config["type"]).to eq("ipsec.1")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_customer_gateway(:tagged, {
          bgp_asn: 65000,
          ip_address: "203.0.113.1",
          type: "ipsec.1",
          tags: { Name: "tagged-gateway", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      cgw_config = result["resource"]["aws_customer_gateway"]["tagged"]

      expect(cgw_config).to have_key("tags")
      expect(cgw_config["tags"]["Name"]).to eq("tagged-gateway")
      expect(cgw_config["tags"]["Environment"]).to eq("production")
    end

    it "supports certificate ARN for authentication" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_customer_gateway(:with_cert, {
          bgp_asn: 65000,
          ip_address: "203.0.113.1",
          type: "ipsec.1",
          certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
          tags: { Name: "cert-auth-gateway" }
        })
      end

      result = synthesizer.synthesis
      cgw_config = result["resource"]["aws_customer_gateway"]["with_cert"]

      expect(cgw_config["certificate_arn"]).to eq("arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012")
    end

    it "supports device name" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_customer_gateway(:named_device, {
          bgp_asn: 65000,
          ip_address: "203.0.113.1",
          type: "ipsec.1",
          device_name: "my-on-premises-router",
          tags: { Name: "named-device-gateway" }
        })
      end

      result = synthesizer.synthesis
      cgw_config = result["resource"]["aws_customer_gateway"]["named_device"]

      expect(cgw_config["device_name"]).to eq("my-on-premises-router")
    end

    it "supports 32-bit BGP ASN" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_customer_gateway(:large_asn, {
          bgp_asn: 4200000000,
          ip_address: "203.0.113.1",
          type: "ipsec.1",
          tags: { Name: "large-asn-gateway" }
        })
      end

      result = synthesizer.synthesis
      cgw_config = result["resource"]["aws_customer_gateway"]["large_asn"]

      expect(cgw_config["bgp_asn"]).to eq(4200000000)
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_customer_gateway(:test, {
          bgp_asn: 65000,
          ip_address: "203.0.113.1",
          type: "ipsec.1"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_customer_gateway"]).to be_a(Hash)
      expect(result["resource"]["aws_customer_gateway"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      cgw_config = result["resource"]["aws_customer_gateway"]["test"]
      expect(cgw_config).to have_key("bgp_asn")
      expect(cgw_config).to have_key("ip_address")
      expect(cgw_config).to have_key("type")
    end
  end

  describe "resource reference" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_customer_gateway(:test_ref, {
          bgp_asn: 65000,
          ip_address: "203.0.113.1",
          type: "ipsec.1",
          tags: { Name: "test-customer-gateway" }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_customer_gateway.test_ref.id}")
      expect(ref.outputs[:arn]).to eq("${aws_customer_gateway.test_ref.arn}")
    end
  end
end
