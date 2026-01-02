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
require 'pangea/resources/aws_route53_record/resource'

RSpec.describe "aws_route53_record synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for A record" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "www.example.com",
          type: "A",
          ttl: 300,
          records: ["192.168.1.1"]
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_route53_record")
      expect(result["resource"]["aws_route53_record"]).to have_key("test")

      record_config = result["resource"]["aws_route53_record"]["test"]
      expect(record_config["zone_id"]).to eq("Z1234567890ABC")
      expect(record_config["name"]).to eq("www.example.com")
      expect(record_config["type"]).to eq("A")
      expect(record_config["ttl"]).to eq(300)
      expect(record_config["records"]).to eq(["192.168.1.1"])
    end

    it "generates terraform for CNAME record" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "blog.example.com",
          type: "CNAME",
          ttl: 300,
          records: ["www.example.com"]
        })
      end

      result = synthesizer.synthesis
      record_config = result["resource"]["aws_route53_record"]["test"]

      expect(record_config["type"]).to eq("CNAME")
      expect(record_config["records"]).to eq(["www.example.com"])
    end

    it "generates terraform for MX record" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "example.com",
          type: "MX",
          ttl: 300,
          records: ["10 mail.example.com", "20 backup.mail.example.com"]
        })
      end

      result = synthesizer.synthesis
      record_config = result["resource"]["aws_route53_record"]["test"]

      expect(record_config["type"]).to eq("MX")
      expect(record_config["records"]).to include("10 mail.example.com")
    end

    it "generates terraform for TXT record" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "example.com",
          type: "TXT",
          ttl: 300,
          records: ["v=spf1 include:_spf.google.com ~all"]
        })
      end

      result = synthesizer.synthesis
      record_config = result["resource"]["aws_route53_record"]["test"]

      expect(record_config["type"]).to eq("TXT")
    end

    it "generates terraform for alias record" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "www.example.com",
          type: "A",
          alias: {
            name: "d1234567890.cloudfront.net",
            zone_id: "Z2FDTNDATAQYW2",
            evaluate_target_health: true
          }
        })
      end

      result = synthesizer.synthesis
      record_config = result["resource"]["aws_route53_record"]["test"]

      expect(record_config).to have_key("alias")
    end

    it "generates terraform with weighted routing policy" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "api.example.com",
          type: "A",
          ttl: 300,
          records: ["192.168.1.1"],
          set_identifier: "primary",
          weighted_routing_policy: { weight: 70 }
        })
      end

      result = synthesizer.synthesis
      record_config = result["resource"]["aws_route53_record"]["test"]

      expect(record_config["set_identifier"]).to eq("primary")
      expect(record_config).to have_key("weighted_routing_policy")
    end

    it "generates terraform with failover routing policy" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "api.example.com",
          type: "A",
          ttl: 300,
          records: ["192.168.1.1"],
          set_identifier: "primary-failover",
          failover_routing_policy: { type: "PRIMARY" }
        })
      end

      result = synthesizer.synthesis
      record_config = result["resource"]["aws_route53_record"]["test"]

      expect(record_config).to have_key("failover_routing_policy")
    end

    it "generates terraform with health check association" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "api.example.com",
          type: "A",
          ttl: 300,
          records: ["192.168.1.1"],
          set_identifier: "primary",
          health_check_id: "abcd1234-5678-90ab-cdef-example12345",
          failover_routing_policy: { type: "PRIMARY" }
        })
      end

      result = synthesizer.synthesis
      record_config = result["resource"]["aws_route53_record"]["test"]

      expect(record_config["health_check_id"]).to eq("abcd1234-5678-90ab-cdef-example12345")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "www.example.com",
          type: "A",
          ttl: 300,
          records: ["192.168.1.1"]
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_route53_record"]).to be_a(Hash)
      expect(result["resource"]["aws_route53_record"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      record_config = result["resource"]["aws_route53_record"]["test"]
      expect(record_config).to have_key("zone_id")
      expect(record_config).to have_key("name")
      expect(record_config).to have_key("type")
    end
  end

  describe "resource references" do
    it "returns a resource reference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "www.example.com",
          type: "A",
          ttl: 300,
          records: ["192.168.1.1"]
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_route53_record')
      expect(ref.name).to eq(:test)

      # Verify output references
      expect(ref.outputs[:id]).to eq("${aws_route53_record.test.id}")
      expect(ref.outputs[:fqdn]).to eq("${aws_route53_record.test.fqdn}")
      expect(ref.outputs[:name]).to eq("${aws_route53_record.test.name}")
      expect(ref.outputs[:type]).to eq("${aws_route53_record.test.type}")
    end

    it "provides computed properties for record type" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "www.example.com",
          type: "A",
          ttl: 300,
          records: ["192.168.1.1"]
        })
      end

      expect(ref.is_simple_record?).to eq(true)
      expect(ref.is_alias_record?).to eq(false)
      expect(ref.routing_policy_type).to eq("simple")
      expect(ref.record_count).to eq(1)
    end

    it "provides computed properties for alias record" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "www.example.com",
          type: "A",
          alias: {
            name: "d1234567890.cloudfront.net",
            zone_id: "Z2FDTNDATAQYW2",
            evaluate_target_health: false
          }
        })
      end

      expect(ref.is_alias_record?).to eq(true)
      expect(ref.is_simple_record?).to eq(true)
    end

    it "provides computed properties for wildcard record" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "*.example.com",
          type: "A",
          ttl: 300,
          records: ["192.168.1.1"]
        })
      end

      expect(ref.is_wildcard_record?).to eq(true)
      expect(ref.domain_name).to eq("example.com")
    end

    it "provides computed properties for routing policies" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_record(:test, {
          zone_id: "Z1234567890ABC",
          name: "api.example.com",
          type: "A",
          ttl: 300,
          records: ["192.168.1.1"],
          set_identifier: "weighted-record",
          weighted_routing_policy: { weight: 70 }
        })
      end

      expect(ref.has_routing_policy?).to eq(true)
      expect(ref.routing_policy_type).to eq("weighted")
    end
  end
end
