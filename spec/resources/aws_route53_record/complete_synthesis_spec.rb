# frozen_string_literal: true
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
require 'json'

# Load aws_route53_record resource and terraform-synthesizer for testing
require 'pangea/resources/aws_route53_record/resource'
require 'terraform_synthesizer'

RSpec.describe "aws_route53_record terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:test_zone_id) { "Z123456ABCDEFGH" }

  # Test simple A record synthesis
  it "synthesizes basic A record correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:www, {
        zone_id: test_zone_id,
        name: "www.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "www")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("www.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["ttl"]).to eq(300)
    expect(record_config["records"]).to eq(["203.0.113.1"])
    expect(record_config).not_to have_key("alias")
  end

  # Test AAAA record synthesis
  it "synthesizes AAAA record correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:ipv6, {
        zone_id: test_zone_id,
        name: "ipv6.example.com",
        type: "AAAA",
        ttl: 600,
        records: ["2001:0db8:85a3:0000:0000:8a2e:0370:7334"]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "ipv6")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("ipv6.example.com")
    expect(record_config["type"]).to eq("AAAA")
    expect(record_config["ttl"]).to eq(600)
    expect(record_config["records"]).to eq(["2001:0db8:85a3:0000:0000:8a2e:0370:7334"])
  end

  # Test CNAME record synthesis
  it "synthesizes CNAME record correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:blog, {
        zone_id: test_zone_id,
        name: "blog.example.com",
        type: "CNAME",
        ttl: 300,
        records: ["blog-hosting.example.net"]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "blog")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("blog.example.com")
    expect(record_config["type"]).to eq("CNAME")
    expect(record_config["ttl"]).to eq(300)
    expect(record_config["records"]).to eq(["blog-hosting.example.net"])
  end

  # Test MX record synthesis
  it "synthesizes MX record correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:mail, {
        zone_id: test_zone_id,
        name: "example.com",
        type: "MX",
        ttl: 3600,
        records: ["10 mail.example.com", "20 mail2.example.com"]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "mail")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("example.com")
    expect(record_config["type"]).to eq("MX")
    expect(record_config["ttl"]).to eq(3600)
    expect(record_config["records"]).to eq(["10 mail.example.com", "20 mail2.example.com"])
  end

  # Test TXT record synthesis
  it "synthesizes TXT record correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:spf, {
        zone_id: test_zone_id,
        name: "example.com",
        type: "TXT",
        ttl: 300,
        records: ["v=spf1 include:_spf.google.com ~all", "google-site-verification=abc123"]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "spf")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("example.com")
    expect(record_config["type"]).to eq("TXT")
    expect(record_config["ttl"]).to eq(300)
    expect(record_config["records"]).to eq(["v=spf1 include:_spf.google.com ~all", "google-site-verification=abc123"])
  end

  # Test alias record synthesis
  it "synthesizes alias record correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:app, {
        zone_id: test_zone_id,
        name: "app.example.com",
        type: "A",
        alias: {
          name: "app-lb-123456.us-east-1.elb.amazonaws.com",
          zone_id: "Z35SXDOTRQ7X7K",
          evaluate_target_health: true
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "app")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("app.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config).not_to have_key("ttl")
    expect(record_config).not_to have_key("records")
    
    # Check alias block
    alias_config = record_config["alias"]
    expect(alias_config).not_to be_nil
    expect(alias_config["name"]).to eq("app-lb-123456.us-east-1.elb.amazonaws.com")
    expect(alias_config["zone_id"]).to eq("Z35SXDOTRQ7X7K")
    expect(alias_config["evaluate_target_health"]).to eq(true)
  end

  # Test weighted routing policy synthesis
  it "synthesizes weighted routing policy correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:weighted_primary, {
        zone_id: test_zone_id,
        name: "api.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "primary",
        weighted_routing_policy: { weight: 80 }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "weighted_primary")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("api.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["ttl"]).to eq(300)
    expect(record_config["records"]).to eq(["203.0.113.1"])
    expect(record_config["set_identifier"]).to eq("primary")
    
    # Check weighted routing policy block
    policy = record_config["weighted_routing_policy"]
    expect(policy).not_to be_nil
    expect(policy["weight"]).to eq(80)
  end

  # Test latency routing policy synthesis
  it "synthesizes latency routing policy correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:latency_us_east, {
        zone_id: test_zone_id,
        name: "api.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "us-east-1",
        latency_routing_policy: { region: "us-east-1" }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "latency_us_east")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("api.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["set_identifier"]).to eq("us-east-1")
    
    # Check latency routing policy block
    policy = record_config["latency_routing_policy"]
    expect(policy).not_to be_nil
    expect(policy["region"]).to eq("us-east-1")
  end

  # Test failover routing policy synthesis
  it "synthesizes failover routing policy correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:failover_primary, {
        zone_id: test_zone_id,
        name: "api.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "primary",
        failover_routing_policy: { type: "PRIMARY" },
        health_check_id: "abcd1234-5678-90ef-ghij-klmnopqrstuv"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "failover_primary")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("api.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["set_identifier"]).to eq("primary")
    expect(record_config["health_check_id"]).to eq("abcd1234-5678-90ef-ghij-klmnopqrstuv")
    
    # Check failover routing policy block
    policy = record_config["failover_routing_policy"]
    expect(policy).not_to be_nil
    expect(policy["type"]).to eq("PRIMARY")
  end

  # Test geolocation routing policy synthesis
  it "synthesizes geolocation routing policy correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:geo_us, {
        zone_id: test_zone_id,
        name: "api.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "us",
        geolocation_routing_policy: {
          country: "US"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "geo_us")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("api.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["set_identifier"]).to eq("us")
    
    # Check geolocation routing policy block
    policy = record_config["geolocation_routing_policy"]
    expect(policy).not_to be_nil
    expect(policy["country"]).to eq("US")
  end

  # Test geoproximity routing policy synthesis
  it "synthesizes geoproximity routing policy correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:geo_proximity_virginia, {
        zone_id: test_zone_id,
        name: "api.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "virginia",
        geoproximity_routing_policy: {
          aws_region: "us-east-1",
          bias: 50
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "geo_proximity_virginia")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("api.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["set_identifier"]).to eq("virginia")
    
    # Check geoproximity routing policy block
    policy = record_config["geoproximity_routing_policy"]
    expect(policy).not_to be_nil
    expect(policy["aws_region"]).to eq("us-east-1")
    expect(policy["bias"]).to eq(50)
  end

  # Test multivalue answer synthesis
  it "synthesizes multivalue answer correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:multivalue, {
        zone_id: test_zone_id,
        name: "api.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "server-1",
        multivalue_answer: true,
        health_check_id: "abcd1234-5678-90ef-ghij-klmnopqrstuv"
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "multivalue")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("api.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["set_identifier"]).to eq("server-1")
    expect(record_config["multivalue_answer"]).to eq(true)
    expect(record_config["health_check_id"]).to eq("abcd1234-5678-90ef-ghij-klmnopqrstuv")
  end

  # Test SRV record synthesis with complex format
  it "synthesizes SRV record correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:sip_srv, {
        zone_id: test_zone_id,
        name: "_sip._tcp.example.com",
        type: "SRV",
        ttl: 600,
        records: ["10 5 5060 sipserver.example.com", "20 10 5060 backup-sip.example.com"]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "sip_srv")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("_sip._tcp.example.com")
    expect(record_config["type"]).to eq("SRV")
    expect(record_config["ttl"]).to eq(600)
    expect(record_config["records"]).to eq(["10 5 5060 sipserver.example.com", "20 10 5060 backup-sip.example.com"])
  end

  # Test wildcard record synthesis
  it "synthesizes wildcard record correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:wildcard, {
        zone_id: test_zone_id,
        name: "*.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"]
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "wildcard")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("*.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["ttl"]).to eq(300)
    expect(record_config["records"]).to eq(["203.0.113.1"])
  end

  # Test record with allow_overwrite synthesis
  it "synthesizes record with allow_overwrite correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:overwrite_allowed, {
        zone_id: test_zone_id,
        name: "migrate.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        allow_overwrite: true
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "overwrite_allowed")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("migrate.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["allow_overwrite"]).to eq(true)
  end

  # Test geolocation routing with continent and subdivision
  it "synthesizes geolocation routing with all fields correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:geo_california, {
        zone_id: test_zone_id,
        name: "api.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "california",
        geolocation_routing_policy: {
          continent: "NA",
          country: "US",
          subdivision: "CA"
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "geo_california")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("api.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["set_identifier"]).to eq("california")
    
    # Check geolocation routing policy block with all fields
    policy = record_config["geolocation_routing_policy"]
    expect(policy).not_to be_nil
    expect(policy["continent"]).to eq("NA")
    expect(policy["country"]).to eq("US")
    expect(policy["subdivision"]).to eq("CA")
  end

  # Test geoproximity routing with coordinates
  it "synthesizes geoproximity routing with coordinates correctly" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:geo_custom_location, {
        zone_id: test_zone_id,
        name: "api.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "custom-location",
        geoproximity_routing_policy: {
          coordinates: {
            latitude: "37.7749",
            longitude: "-122.4194"
          },
          bias: -25
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "geo_custom_location")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("api.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["set_identifier"]).to eq("custom-location")
    
    # Check geoproximity routing policy block with coordinates
    policy = record_config["geoproximity_routing_policy"]
    expect(policy).not_to be_nil
    expect(policy["bias"]).to eq(-25)
    
    coordinates = policy["coordinates"]
    expect(coordinates).not_to be_nil
    expect(coordinates["latitude"]).to eq("37.7749")
    expect(coordinates["longitude"]).to eq("-122.4194")
  end

  # Test alias record without evaluate_target_health (should default to false)
  it "synthesizes alias record with default evaluate_target_health" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:cdn_alias, {
        zone_id: test_zone_id,
        name: "cdn.example.com",
        type: "A",
        alias: {
          name: "d123456789.cloudfront.net",
          zone_id: "Z2FDTNDATAQYW2",
          evaluate_target_health: false
        }
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "cdn_alias")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("cdn.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config).not_to have_key("ttl")
    expect(record_config).not_to have_key("records")
    
    # Check alias block with default evaluate_target_health
    alias_config = record_config["alias"]
    expect(alias_config).not_to be_nil
    expect(alias_config["name"]).to eq("d123456789.cloudfront.net")
    expect(alias_config["zone_id"]).to eq("Z2FDTNDATAQYW2")
    expect(alias_config["evaluate_target_health"]).to eq(false)
  end

  # Test comprehensive record with all optional fields
  it "synthesizes record with all optional configurations" do
    terraform_output = synthesizer.synthesize do
      include Pangea::Resources::AWS
      
      aws_route53_record(:comprehensive, {
        zone_id: test_zone_id,
        name: "comprehensive.example.com",
        type: "A",
        ttl: 600,
        records: ["203.0.113.1", "203.0.113.2"],
        set_identifier: "comprehensive-test",
        weighted_routing_policy: { weight: 100 },
        health_check_id: "abcd1234-5678-90ef-ghij-klmnopqrstuv",
        multivalue_answer: false,
        allow_overwrite: true
      })
    end
    
    json_output = JSON.parse(terraform_output)
    record_config = json_output.dig("resource", "aws_route53_record", "comprehensive")
    
    expect(record_config["zone_id"]).to eq(test_zone_id)
    expect(record_config["name"]).to eq("comprehensive.example.com")
    expect(record_config["type"]).to eq("A")
    expect(record_config["ttl"]).to eq(600)
    expect(record_config["records"]).to eq(["203.0.113.1", "203.0.113.2"])
    expect(record_config["set_identifier"]).to eq("comprehensive-test")
    expect(record_config["health_check_id"]).to eq("abcd1234-5678-90ef-ghij-klmnopqrstuv")
    expect(record_config["multivalue_answer"]).to eq(false)
    expect(record_config["allow_overwrite"]).to eq(true)
    
    # Check weighted routing policy
    policy = record_config["weighted_routing_policy"]
    expect(policy).not_to be_nil
    expect(policy["weight"]).to eq(100)
  end
end