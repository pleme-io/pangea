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
require 'pangea/resources/aws_wafv2_ip_set/resource'

RSpec.describe "aws_wafv2_ip_set synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for IPv4 IP set" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_ip_set(:blocked_ips, {
          name: "blocked-ips",
          scope: "REGIONAL",
          ip_address_version: "IPV4",
          addresses: ["192.0.2.0/24", "198.51.100.0/24"],
          tags: { Environment: "production" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_wafv2_ip_set")
      expect(result["resource"]["aws_wafv2_ip_set"]).to have_key("blocked_ips")

      ip_set_config = result["resource"]["aws_wafv2_ip_set"]["blocked_ips"]
      expect(ip_set_config["name"]).to eq("blocked-ips")
      expect(ip_set_config["scope"]).to eq("regional")
      expect(ip_set_config["ip_address_version"]).to eq("IPV4")
      expect(ip_set_config["addresses"]).to eq(["192.0.2.0/24", "198.51.100.0/24"])
    end

    it "generates valid terraform JSON for IPv6 IP set" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_ip_set(:ipv6_allowlist, {
          name: "ipv6-allowlist",
          scope: "REGIONAL",
          ip_address_version: "IPV6",
          addresses: ["2001:0db8::/32"],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      ip_set_config = result["resource"]["aws_wafv2_ip_set"]["ipv6_allowlist"]

      expect(ip_set_config["ip_address_version"]).to eq("IPV6")
      expect(ip_set_config["addresses"]).to eq(["2001:0db8::/32"])
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_ip_set(:test_ip_set, {
          name: "test-ip-set",
          scope: "REGIONAL",
          ip_address_version: "IPV4",
          addresses: ["10.0.0.1/32"],
          description: "Test IP set for blocking malicious IPs",
          tags: {}
        })
      end

      result = synthesizer.synthesis
      ip_set_config = result["resource"]["aws_wafv2_ip_set"]["test_ip_set"]

      expect(ip_set_config).to have_key("description")
      expect(ip_set_config["description"]).to eq("Test IP set for blocking malicious IPs")
    end

    it "supports CLOUDFRONT scope" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_ip_set(:cloudfront_ips, {
          name: "cloudfront-blocked-ips",
          scope: "CLOUDFRONT",
          ip_address_version: "IPV4",
          addresses: ["203.0.113.0/24"],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      ip_set_config = result["resource"]["aws_wafv2_ip_set"]["cloudfront_ips"]

      expect(ip_set_config["scope"]).to eq("cloudfront")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_ip_set(:tagged_ip_set, {
          name: "tagged-ip-set",
          scope: "REGIONAL",
          ip_address_version: "IPV4",
          addresses: ["10.0.0.0/8"],
          tags: { Name: "tagged-ip-set", Environment: "test", Purpose: "security" }
        })
      end

      result = synthesizer.synthesis
      ip_set_config = result["resource"]["aws_wafv2_ip_set"]["tagged_ip_set"]

      expect(ip_set_config).to have_key("tags")
      expect(ip_set_config["tags"]["Name"]).to eq("tagged-ip-set")
      expect(ip_set_config["tags"]["Environment"]).to eq("test")
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_wafv2_ip_set(:ref_test, {
          name: "ref-test-ip-set",
          scope: "REGIONAL",
          ip_address_version: "IPV4",
          addresses: ["172.16.0.0/12"],
          tags: {}
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_wafv2_ip_set.ref_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_wafv2_ip_set.ref_test.arn}")
      expect(ref.outputs[:lock_token]).to eq("${aws_wafv2_ip_set.ref_test.lock_token}")
    end

    it "returns computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_wafv2_ip_set(:computed_test, {
          name: "computed-test",
          scope: "REGIONAL",
          ip_address_version: "IPV4",
          addresses: ["10.0.0.0/8", "172.16.0.0/12", "192.168.1.1/32"],
          tags: {}
        })
      end

      expect(ref.computed[:address_count]).to eq(3)
      expect(ref.computed[:has_cidr_blocks]).to eq(true)
      expect(ref.computed[:has_individual_ips]).to eq(true)
      expect(ref.computed[:ip_version]).to eq("IPV4")
      expect(ref.computed[:scope]).to eq("REGIONAL")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_ip_set(:validation_test, {
          name: "validation-test",
          scope: "REGIONAL",
          ip_address_version: "IPV4",
          addresses: ["10.0.0.0/8"],
          tags: {}
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_wafv2_ip_set"]).to be_a(Hash)
      expect(result["resource"]["aws_wafv2_ip_set"]["validation_test"]).to be_a(Hash)

      ip_set_config = result["resource"]["aws_wafv2_ip_set"]["validation_test"]
      expect(ip_set_config).to have_key("name")
      expect(ip_set_config).to have_key("scope")
      expect(ip_set_config).to have_key("ip_address_version")
      expect(ip_set_config).to have_key("addresses")
    end
  end
end
