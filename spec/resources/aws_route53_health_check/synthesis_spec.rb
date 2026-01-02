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
require 'pangea/resources/aws_route53_health_check/resource'

RSpec.describe "aws_route53_health_check synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON for HTTP health check" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_health_check(:test, {
          type: "HTTP",
          fqdn: "example.com",
          port: 80,
          resource_path: "/health",
          failure_threshold: 3,
          request_interval: 30
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_route53_health_check")
      expect(result["resource"]["aws_route53_health_check"]).to have_key("test")

      health_check_config = result["resource"]["aws_route53_health_check"]["test"]
      expect(health_check_config["type"]).to eq("HTTP")
      expect(health_check_config["fqdn"]).to eq("example.com")
      expect(health_check_config["port"]).to eq(80)
      expect(health_check_config["resource_path"]).to eq("/health")
    end

    it "generates terraform for HTTPS health check" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_health_check(:test, {
          type: "HTTPS",
          fqdn: "secure.example.com",
          port: 443,
          resource_path: "/health",
          failure_threshold: 3,
          request_interval: 30,
          enable_sni: true
        })
      end

      result = synthesizer.synthesis
      health_check_config = result["resource"]["aws_route53_health_check"]["test"]

      expect(health_check_config["type"]).to eq("HTTPS")
      expect(health_check_config["enable_sni"]).to eq(true)
    end

    it "generates terraform for HTTP_STR_MATCH health check" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_health_check(:test, {
          type: "HTTP_STR_MATCH",
          fqdn: "example.com",
          port: 80,
          resource_path: "/health",
          search_string: "OK",
          failure_threshold: 3,
          request_interval: 30
        })
      end

      result = synthesizer.synthesis
      health_check_config = result["resource"]["aws_route53_health_check"]["test"]

      expect(health_check_config["type"]).to eq("HTTP_STR_MATCH")
      expect(health_check_config["search_string"]).to eq("OK")
    end

    it "generates terraform for TCP health check" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_health_check(:test, {
          type: "TCP",
          fqdn: "db.example.com",
          port: 5432,
          failure_threshold: 3,
          request_interval: 30
        })
      end

      result = synthesizer.synthesis
      health_check_config = result["resource"]["aws_route53_health_check"]["test"]

      expect(health_check_config["type"]).to eq("TCP")
      expect(health_check_config["port"]).to eq(5432)
    end

    it "generates terraform for calculated health check" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_health_check(:test, {
          type: "CALCULATED",
          child_health_checks: ["id-1", "id-2", "id-3"],
          child_health_threshold: 2,
          failure_threshold: 1
        })
      end

      result = synthesizer.synthesis
      health_check_config = result["resource"]["aws_route53_health_check"]["test"]

      expect(health_check_config["type"]).to eq("CALCULATED")
      expect(health_check_config["child_health_checks"]).to eq(["id-1", "id-2", "id-3"])
      expect(health_check_config["child_health_threshold"]).to eq(2)
    end

    it "generates terraform for CloudWatch metric health check" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_health_check(:test, {
          type: "CLOUDWATCH_METRIC",
          cloudwatch_alarm_name: "my-alarm",
          cloudwatch_alarm_region: "us-east-1",
          insufficient_data_health_status: "LastKnownStatus",
          failure_threshold: 1
        })
      end

      result = synthesizer.synthesis
      health_check_config = result["resource"]["aws_route53_health_check"]["test"]

      expect(health_check_config["type"]).to eq("CLOUDWATCH_METRIC")
      expect(health_check_config["cloudwatch_alarm_name"]).to eq("my-alarm")
      expect(health_check_config["cloudwatch_alarm_region"]).to eq("us-east-1")
    end

    it "generates terraform with tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_health_check(:test, {
          type: "HTTP",
          fqdn: "example.com",
          tags: { Name: "test-health-check", Environment: "test" }
        })
      end

      result = synthesizer.synthesis
      health_check_config = result["resource"]["aws_route53_health_check"]["test"]

      expect(health_check_config).to have_key("tags")
      expect(health_check_config["tags"]["Name"]).to eq("test-health-check")
      expect(health_check_config["tags"]["Environment"]).to eq("test")
    end

    it "generates terraform with latency measurement enabled" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_health_check(:test, {
          type: "HTTP",
          fqdn: "example.com",
          measure_latency: true
        })
      end

      result = synthesizer.synthesis
      health_check_config = result["resource"]["aws_route53_health_check"]["test"]

      expect(health_check_config["measure_latency"]).to eq(true)
    end

    it "generates terraform with fast request interval" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_health_check(:test, {
          type: "HTTP",
          fqdn: "example.com",
          request_interval: 10,
          failure_threshold: 2
        })
      end

      result = synthesizer.synthesis
      health_check_config = result["resource"]["aws_route53_health_check"]["test"]

      expect(health_check_config["request_interval"]).to eq(10)
    end

    it "generates terraform with health check regions" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_health_check(:test, {
          type: "HTTP",
          fqdn: "example.com",
          regions: ["us-east-1", "us-west-2", "eu-west-1"]
        })
      end

      result = synthesizer.synthesis
      health_check_config = result["resource"]["aws_route53_health_check"]["test"]

      expect(health_check_config["regions"]).to eq(["us-east-1", "us-west-2", "eu-west-1"])
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_route53_health_check(:test, {
          type: "HTTP",
          fqdn: "example.com"
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_route53_health_check"]).to be_a(Hash)
      expect(result["resource"]["aws_route53_health_check"]["test"]).to be_a(Hash)

      # Validate required attributes are present
      health_check_config = result["resource"]["aws_route53_health_check"]["test"]
      expect(health_check_config).to have_key("type")
      expect(health_check_config["type"]).to be_a(String)
    end
  end

  describe "resource references" do
    it "returns a resource reference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_health_check(:test, {
          type: "HTTP",
          fqdn: "example.com"
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_route53_health_check')
      expect(ref.name).to eq(:test)

      # Verify output references
      expect(ref.outputs[:id]).to eq("${aws_route53_health_check.test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_route53_health_check.test.arn}")
      expect(ref.outputs[:type]).to eq("${aws_route53_health_check.test.type}")
    end

    it "provides computed properties for endpoint health check" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_health_check(:test, {
          type: "HTTP",
          fqdn: "example.com"
        })
      end

      expect(ref.is_endpoint_health_check?).to eq(true)
      expect(ref.is_calculated_health_check?).to eq(false)
      expect(ref.is_cloudwatch_health_check?).to eq(false)
      expect(ref.requires_endpoint?).to eq(true)
      expect(ref.endpoint_identifier).to eq("example.com")
    end

    it "provides computed properties for calculated health check" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_health_check(:test, {
          type: "CALCULATED",
          child_health_checks: ["id-1", "id-2"],
          child_health_threshold: 1
        })
      end

      expect(ref.is_calculated_health_check?).to eq(true)
      expect(ref.is_endpoint_health_check?).to eq(false)
      expect(ref.requires_endpoint?).to eq(false)
    end

    it "provides computed properties for CloudWatch health check" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_health_check(:test, {
          type: "CLOUDWATCH_METRIC",
          cloudwatch_alarm_name: "my-alarm",
          cloudwatch_alarm_region: "us-east-1"
        })
      end

      expect(ref.is_cloudwatch_health_check?).to eq(true)
      expect(ref.is_endpoint_health_check?).to eq(false)
    end

    it "provides SSL support detection" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_health_check(:test, {
          type: "HTTPS",
          fqdn: "secure.example.com"
        })
      end

      expect(ref.supports_ssl?).to eq(true)
      expect(ref.default_port_for_type).to eq(443)
    end

    it "provides string matching support detection" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_route53_health_check(:test, {
          type: "HTTP_STR_MATCH",
          fqdn: "example.com",
          search_string: "OK"
        })
      end

      expect(ref.supports_string_matching?).to eq(true)
    end
  end
end
