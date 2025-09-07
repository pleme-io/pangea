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

# Load aws_route53_record resource and types for testing
require 'pangea/resources/aws_route53_record/resource'
require 'pangea/resources/aws_route53_record/types'

RSpec.describe "aws_route53_record resource function" do
  # Create a test class that includes the AWS module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      # Mock the terraform-synthesizer resource method
      def resource(type, name)
        @resources ||= {}
        resource_data = { type: type, name: name, attributes: {} }
        
        yield if block_given?
        
        @resources["#{type}.#{name}"] = resource_data
        resource_data
      end
      
      # Method missing to capture terraform attributes
      def method_missing(method_name, *args, &block)
        # Don't capture certain methods that might interfere
        return super if [:expect, :be_a, :eq].include?(method_name)
        # For terraform-synthesizer attribute calls, just return the value
        args.first if args.any?
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  let(:test_zone_id) { "Z123456ABCDEFGH" }
  
  describe "Route53RecordAttributes validation" do
    it "accepts minimal A record configuration" do
      attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "www.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"]
      })
      
      expect(attrs.zone_id).to eq(test_zone_id)
      expect(attrs.name).to eq("www.example.com")
      expect(attrs.type).to eq("A")
      expect(attrs.ttl).to eq(300)
      expect(attrs.records).to eq(["203.0.113.1"])
    end
    
    it "accepts alias record configuration" do
      attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "app.example.com",
        type: "A",
        alias: {
          name: "app-lb-123456.us-east-1.elb.amazonaws.com",
          zone_id: "Z35SXDOTRQ7X7K",
          evaluate_target_health: true
        }
      })
      
      expect(attrs.alias[:name]).to eq("app-lb-123456.us-east-1.elb.amazonaws.com")
      expect(attrs.alias[:zone_id]).to eq("Z35SXDOTRQ7X7K")
      expect(attrs.alias[:evaluate_target_health]).to eq(true)
    end
    
    it "validates DNS record types" do
      valid_types = ["A", "AAAA", "CNAME", "MX", "NS", "PTR", "SOA", "SPF", "SRV", "TXT"]
      
      valid_types.each do |record_type|
        attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "test.example.com",
          type: record_type,
          ttl: 300,
          records: ["test-value"]
        })
        expect(attrs.type).to eq(record_type)
      end
      
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "test.example.com",
          type: "INVALID",
          ttl: 300,
          records: ["test-value"]
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates zone ID format" do
      invalid_zone_ids = [
        "invalid-zone",
        "z123456",          # Lowercase not allowed
        "Z123-456",         # Hyphens not standard
        ""                  # Empty string
      ]
      
      invalid_zone_ids.each do |invalid_zone_id|
        expect {
          Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
            zone_id: invalid_zone_id,
            name: "test.example.com",
            type: "A",
            ttl: 300,
            records: ["203.0.113.1"]
          })
        }.to raise_error(Dry::Struct::Error, /Invalid hosted zone ID format/)
      end
    end
    
    it "validates record name format" do
      invalid_names = [
        ".example.com",      # Starts with dot
        "example.com.",      # Ends with dot
        "",                  # Empty string
        "a" * 254,          # Too long
        "test..example.com", # Double dots
        "test .example.com"  # Contains space
      ]
      
      invalid_names.each do |invalid_name|
        expect {
          Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
            zone_id: test_zone_id,
            name: invalid_name,
            type: "A",
            ttl: 300,
            records: ["203.0.113.1"]
          })
        }.to raise_error(Dry::Struct::Error, /Invalid DNS record name format/)
      end
    end
    
    it "validates TTL constraints" do
      # Valid TTL range
      valid_attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "test.example.com",
        type: "A",
        ttl: 86400,  # 1 day
        records: ["203.0.113.1"]
      })
      expect(valid_attrs.ttl).to eq(86400)
      
      # Invalid TTL (negative)
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "test.example.com",
          type: "A",
          ttl: -1,
          records: ["203.0.113.1"]
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates A record IPv4 addresses" do
      valid_ips = ["203.0.113.1", "192.168.1.1", "10.0.0.1"]
      
      attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "test.example.com",
        type: "A",
        ttl: 300,
        records: valid_ips
      })
      expect(attrs.records).to eq(valid_ips)
      
      # Invalid IPv4 addresses
      invalid_ips = ["256.0.0.1", "192.168.1", "not-an-ip", "192.168.1.1.1"]
      
      invalid_ips.each do |invalid_ip|
        expect {
          Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
            zone_id: test_zone_id,
            name: "test.example.com",
            type: "A",
            ttl: 300,
            records: [invalid_ip]
          })
        }.to raise_error(Dry::Struct::Error, /must contain valid IPv4 addresses/)
      end
    end
    
    it "validates AAAA record IPv6 addresses" do
      valid_ipv6s = [
        "2001:db8:85a3::8a2e:370:7334",
        "2001:db8:85a3:0:0:8a2e:370:7334",
        "::1"
      ]
      
      valid_ipv6s.each do |ipv6|
        attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "ipv6.example.com",
          type: "AAAA",
          ttl: 300,
          records: [ipv6]
        })
        expect(attrs.records.first).to eq(ipv6)
      end
      
      # Invalid IPv6 addresses
      invalid_ipv6s = ["invalid-ipv6", "192.168.1.1", ""]
      
      invalid_ipv6s.each do |invalid_ipv6|
        expect {
          Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
            zone_id: test_zone_id,
            name: "ipv6.example.com",
            type: "AAAA",
            ttl: 300,
            records: [invalid_ipv6]
          })
        }.to raise_error(Dry::Struct::Error, /must contain valid IPv6 addresses/)
      end
    end
    
    it "validates CNAME record constraints" do
      # Valid CNAME with single target
      attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "www.example.com",
        type: "CNAME",
        ttl: 300,
        records: ["example.com"]
      })
      expect(attrs.records).to eq(["example.com"])
      
      # Invalid CNAME with multiple targets
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "www.example.com",
          type: "CNAME",
          ttl: 300,
          records: ["example.com", "backup.example.com"]
        })
      }.to raise_error(Dry::Struct::Error, /must have exactly one target/)
    end
    
    it "validates MX record format" do
      valid_mx_records = ["10 mail.example.com", "20 backup-mail.example.com"]
      
      attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "example.com",
        type: "MX",
        ttl: 300,
        records: valid_mx_records
      })
      expect(attrs.records).to eq(valid_mx_records)
      
      # Invalid MX record format
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "example.com",
          type: "MX",
          ttl: 300,
          records: ["invalid-mx-record"]
        })
      }.to raise_error(Dry::Struct::Error, /must be in format 'priority hostname'/)
    end
    
    it "validates SRV record format" do
      valid_srv = "10 20 443 target.example.com"
      
      attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "_https._tcp.example.com",
        type: "SRV",
        ttl: 300,
        records: [valid_srv]
      })
      expect(attrs.records).to eq([valid_srv])
      
      # Invalid SRV record format
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "_https._tcp.example.com",
          type: "SRV",
          ttl: 300,
          records: ["invalid srv record"]
        })
      }.to raise_error(Dry::Struct::Error, /must be in format 'priority weight port target'/)
    end
    
    it "validates mutual exclusivity of alias and regular records" do
      # Alias record cannot have TTL or records
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "alias.example.com",
          type: "A",
          alias: {
            name: "target.example.com",
            zone_id: test_zone_id
          },
          ttl: 300,  # Should not be allowed
          records: ["203.0.113.1"]
        })
      }.to raise_error(Dry::Struct::Error, /cannot have TTL or records values/)
    end
    
    it "validates non-alias records require TTL and records" do
      # Missing TTL
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "test.example.com",
          type: "A",
          records: ["203.0.113.1"]
          # Missing ttl
        })
      }.to raise_error(Dry::Struct::Error, /must have a TTL value/)
      
      # Missing records
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "test.example.com",
          type: "A",
          ttl: 300
          # Missing records
        })
      }.to raise_error(Dry::Struct::Error, /must have at least one record value/)
    end
    
    it "validates routing policy mutual exclusivity" do
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "conflict.example.com",
          type: "A",
          ttl: 300,
          records: ["203.0.113.1"],
          set_identifier: "test-set",
          weighted_routing_policy: { weight: 50 },
          latency_routing_policy: { region: "us-east-1" }  # Cannot have both
        })
      }.to raise_error(Dry::Struct::Error, /Only one routing policy can be specified/)
    end
    
    it "validates set_identifier required for routing policies" do
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "weighted.example.com",
          type: "A",
          ttl: 300,
          records: ["203.0.113.1"],
          weighted_routing_policy: { weight: 50 }
          # Missing set_identifier
        })
      }.to raise_error(Dry::Struct::Error, /set_identifier is required/)
    end
    
    it "validates health check ID format when provided" do
      valid_health_check_id = "12345678-1234-1234-1234-123456789012"
      
      attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "health.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        health_check_id: valid_health_check_id
      })
      expect(attrs.health_check_id).to eq(valid_health_check_id)
      
      # Invalid health check ID
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "health.example.com",
          type: "A",
          ttl: 300,
          records: ["203.0.113.1"],
          health_check_id: "invalid-health-check-id!"
        })
      }.to raise_error(Dry::Struct::Error, /Invalid health check ID format/)
    end
    
    it "detects record types and properties" do
      # Alias record
      alias_attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "alias.example.com",
        type: "A",
        alias: {
          name: "target.example.com",
          zone_id: test_zone_id
        }
      })
      expect(alias_attrs.is_alias_record?).to eq(true)
      expect(alias_attrs.is_simple_record?).to eq(true)  # No routing policies
      
      # Weighted record
      weighted_attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "weighted.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "weight-50",
        weighted_routing_policy: { weight: 50 }
      })
      expect(weighted_attrs.has_routing_policy?).to eq(true)
      expect(weighted_attrs.routing_policy_type).to eq("weighted")
      expect(weighted_attrs.is_simple_record?).to eq(false)
    end
    
    it "detects wildcard records" do
      wildcard_attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "*.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"]
      })
      
      expect(wildcard_attrs.is_wildcard_record?).to eq(true)
      expect(wildcard_attrs.domain_name).to eq("example.com")
      
      # Non-wildcard
      regular_attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "www.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"]
      })
      expect(regular_attrs.is_wildcard_record?).to eq(false)
    end
    
    it "calculates record count and cost estimation" do
      attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "multi.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1", "203.0.113.2", "203.0.113.3"]
      })
      
      expect(attrs.record_count).to eq(3)
      expect(attrs.estimated_query_cost_per_million).to eq(0.40)  # Base cost
      
      # Weighted record has higher cost
      weighted_attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "weighted.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "weight-100",
        weighted_routing_policy: { weight: 100 }
      })
      expect(weighted_attrs.estimated_query_cost_per_million).to eq(0.80)  # 2x cost
    end
  end
  
  describe "aws_route53_record function behavior" do
    it "creates a simple A record" do
      ref = test_instance.aws_route53_record(:www_record, {
        zone_id: test_zone_id,
        name: "www.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1", "203.0.113.2"]
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_route53_record')
      expect(ref.name).to eq(:www_record)
    end
    
    it "creates an alias record" do
      ref = test_instance.aws_route53_record(:app_alias, {
        zone_id: test_zone_id,
        name: "app.example.com",
        type: "A",
        alias: {
          name: "app-lb-123456.us-east-1.elb.amazonaws.com",
          zone_id: "Z35SXDOTRQ7X7K",
          evaluate_target_health: true
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:alias][:name]).to eq("app-lb-123456.us-east-1.elb.amazonaws.com")
      expect(ref.is_alias_record?).to eq(true)
    end
    
    it "creates CNAME record" do
      ref = test_instance.aws_route53_record(:cname_record, {
        zone_id: test_zone_id,
        name: "docs.example.com",
        type: "CNAME",
        ttl: 300,
        records: ["documentation.hosting.com"]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:type]).to eq("CNAME")
      expect(attrs[:records]).to eq(["documentation.hosting.com"])
    end
    
    it "creates MX record for email" do
      ref = test_instance.aws_route53_record(:mx_record, {
        zone_id: test_zone_id,
        name: "example.com",
        type: "MX",
        ttl: 300,
        records: ["10 mail.example.com", "20 backup.example.com"]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:type]).to eq("MX")
      expect(attrs[:records]).to include("10 mail.example.com")
    end
    
    it "creates TXT record for verification" do
      ref = test_instance.aws_route53_record(:txt_record, {
        zone_id: test_zone_id,
        name: "_dmarc.example.com",
        type: "TXT",
        ttl: 300,
        records: ["v=DMARC1; p=reject; rua=mailto:dmarc@example.com"]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:type]).to eq("TXT")
      expect(attrs[:records].first).to include("v=DMARC1")
    end
    
    it "creates weighted routing record" do
      ref = test_instance.aws_route53_record(:weighted_primary, {
        zone_id: test_zone_id,
        name: "app.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "primary-70",
        weighted_routing_policy: { weight: 70 }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:weighted_routing_policy][:weight]).to eq(70)
      expect(ref.routing_policy_type).to eq("weighted")
    end
    
    it "creates failover routing record" do
      ref = test_instance.aws_route53_record(:failover_primary, {
        zone_id: test_zone_id,
        name: "api.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "primary",
        failover_routing_policy: { type: "PRIMARY" },
        health_check_id: "12345678-1234-1234-1234-123456789012"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:failover_routing_policy][:type]).to eq("PRIMARY")
      expect(attrs[:health_check_id]).to eq("12345678-1234-1234-1234-123456789012")
    end
    
    it "creates latency-based routing record" do
      ref = test_instance.aws_route53_record(:latency_east, {
        zone_id: test_zone_id,
        name: "global.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "us-east-1",
        latency_routing_policy: { region: "us-east-1" }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:latency_routing_policy][:region]).to eq("us-east-1")
      expect(ref.routing_policy_type).to eq("latency")
    end
    
    it "creates geolocation routing record" do
      ref = test_instance.aws_route53_record(:geo_us, {
        zone_id: test_zone_id,
        name: "geo.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "us-users",
        geolocation_routing_policy: {
          country: "US"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:geolocation_routing_policy][:country]).to eq("US")
      expect(ref.routing_policy_type).to eq("geolocation")
    end
    
    it "creates multivalue answer record" do
      ref = test_instance.aws_route53_record(:multivalue_record, {
        zone_id: test_zone_id,
        name: "multi.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        multivalue_answer: true,
        health_check_id: "12345678-1234-1234-1234-123456789012"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:multivalue_answer]).to eq(true)
      expect(ref.routing_policy_type).to eq("multivalue")
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_route53_record(:test_record, {
        zone_id: test_zone_id,
        name: "test.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"]
      })
      
      expected_outputs = [:id, :name, :fqdn, :type, :zone_id, :records, :ttl]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_route53_record.test_record.")
      end
    end
    
    it "provides computed properties" do
      ref = test_instance.aws_route53_record(:computed_test, {
        zone_id: test_zone_id,
        name: "*.api.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1", "203.0.113.2"],
        set_identifier: "wildcard-weight",
        weighted_routing_policy: { weight: 80 }
      })
      
      expect(ref.is_wildcard_record?).to eq(true)
      expect(ref.domain_name).to eq("api.example.com")
      expect(ref.record_count).to eq(2)
      expect(ref.has_routing_policy?).to eq(true)
      expect(ref.routing_policy_type).to eq("weighted")
      expect(ref.estimated_query_cost_per_million).to eq(0.80)  # 2x cost
    end
  end
  
  describe "Route53RecordConfigs module usage" do
    it "creates A record configuration" do
      config = Pangea::Resources::AWS::Types::Route53RecordConfigs.a_record(
        test_zone_id,
        "api.example.com",
        ["203.0.113.1", "203.0.113.2"],
        ttl: 60
      )
      ref = test_instance.aws_route53_record(:a_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:type]).to eq("A")
      expect(attrs[:ttl]).to eq(60)
      expect(attrs[:records]).to eq(["203.0.113.1", "203.0.113.2"])
    end
    
    it "creates AAAA record configuration" do
      config = Pangea::Resources::AWS::Types::Route53RecordConfigs.aaaa_record(
        test_zone_id,
        "ipv6.example.com",
        "2001:db8:85a3::8a2e:370:7334"
      )
      ref = test_instance.aws_route53_record(:aaaa_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:type]).to eq("AAAA")
      expect(attrs[:records]).to eq(["2001:db8:85a3::8a2e:370:7334"])
    end
    
    it "creates CNAME record configuration" do
      config = Pangea::Resources::AWS::Types::Route53RecordConfigs.cname_record(
        test_zone_id,
        "www.example.com",
        "example.com"
      )
      ref = test_instance.aws_route53_record(:cname_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:type]).to eq("CNAME")
      expect(attrs[:records]).to eq(["example.com"])
    end
    
    it "creates MX record configuration" do
      mail_servers = ["10 mail.example.com", "20 backup.example.com"]
      config = Pangea::Resources::AWS::Types::Route53RecordConfigs.mx_record(
        test_zone_id,
        "example.com",
        mail_servers
      )
      ref = test_instance.aws_route53_record(:mx_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:type]).to eq("MX")
      expect(attrs[:records]).to eq(mail_servers)
    end
    
    it "creates TXT record configuration" do
      config = Pangea::Resources::AWS::Types::Route53RecordConfigs.txt_record(
        test_zone_id,
        "_dmarc.example.com",
        ["v=DMARC1; p=reject;", "spf include:_spf.google.com"]
      )
      ref = test_instance.aws_route53_record(:txt_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:type]).to eq("TXT")
      expect(attrs[:records]).to include("v=DMARC1; p=reject;")
    end
    
    it "creates alias record configuration" do
      config = Pangea::Resources::AWS::Types::Route53RecordConfigs.alias_record(
        test_zone_id,
        "app.example.com",
        "app-lb-123.us-east-1.elb.amazonaws.com",
        "Z35SXDOTRQ7X7K",
        evaluate_health: true
      )
      ref = test_instance.aws_route53_record(:alias_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:alias][:name]).to eq("app-lb-123.us-east-1.elb.amazonaws.com")
      expect(attrs[:alias][:evaluate_target_health]).to eq(true)
    end
    
    it "creates weighted routing configuration" do
      config = Pangea::Resources::AWS::Types::Route53RecordConfigs.weighted_record(
        test_zone_id,
        "balanced.example.com",
        "A",
        "203.0.113.1",
        75,
        "primary-75",
        health_check_id: "health-123"
      )
      ref = test_instance.aws_route53_record(:weighted_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:weighted_routing_policy][:weight]).to eq(75)
      expect(attrs[:set_identifier]).to eq("primary-75")
      expect(attrs[:health_check_id]).to eq("health-123")
    end
    
    it "creates failover routing configuration" do
      config = Pangea::Resources::AWS::Types::Route53RecordConfigs.failover_record(
        test_zone_id,
        "ha.example.com",
        "A",
        "203.0.113.1",
        "primary",
        "primary-endpoint",
        health_check_id: "health-primary"
      )
      ref = test_instance.aws_route53_record(:failover_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:failover_routing_policy][:type]).to eq("PRIMARY")
      expect(attrs[:set_identifier]).to eq("primary-endpoint")
    end
    
    it "creates geolocation routing configuration" do
      location = { country: "US", subdivision: "CA" }
      config = Pangea::Resources::AWS::Types::Route53RecordConfigs.geolocation_record(
        test_zone_id,
        "regional.example.com",
        "A",
        "203.0.113.1",
        location,
        "us-california"
      )
      ref = test_instance.aws_route53_record(:geo_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:geolocation_routing_policy][:country]).to eq("US")
      expect(attrs[:geolocation_routing_policy][:subdivision]).to eq("CA")
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_route53_record(:test_record, {
        zone_id: test_zone_id,
        name: "test.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"]
      })
      
      expect(ref.outputs[:id]).to eq("${aws_route53_record.test_record.id}")
      expect(ref.outputs[:fqdn]).to eq("${aws_route53_record.test_record.fqdn}")
      expect(ref.outputs[:name]).to eq("${aws_route53_record.test_record.name}")
      expect(ref.outputs[:records]).to eq("${aws_route53_record.test_record.records}")
    end
    
    it "can be used with zone references" do
      # This would typically use a ResourceReference from aws_route53_zone
      zone_id = "${aws_route53_zone.main.zone_id}"  # Simulated zone reference
      
      ref = test_instance.aws_route53_record(:zone_ref_record, {
        zone_id: zone_id,
        name: "dynamic.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:zone_id]).to eq(zone_id)
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles string keys in attributes" do
      ref = test_instance.aws_route53_record(:string_keys, {
        "zone_id" => test_zone_id,
        "name" => "string-test.example.com",
        "type" => "A",
        "ttl" => 300,
        "records" => ["203.0.113.1"]
      })
      
      expect(ref.resource_attributes[:zone_id]).to eq(test_zone_id)
      expect(ref.resource_attributes[:name]).to eq("string-test.example.com")
      expect(ref.resource_attributes[:type]).to eq("A")
    end
    
    it "validates all routing policy types correctly" do
      routing_policies = [
        { type: "weighted", policy: { weighted_routing_policy: { weight: 50 } } },
        { type: "latency", policy: { latency_routing_policy: { region: "us-east-1" } } },
        { type: "failover", policy: { failover_routing_policy: { type: "PRIMARY" } } },
        { type: "geolocation", policy: { geolocation_routing_policy: { country: "US" } } }
      ]
      
      routing_policies.each_with_index do |route_config, index|
        attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "policy#{index}.example.com",
          type: "A",
          ttl: 300,
          records: ["203.0.113.1"],
          set_identifier: "policy-#{index}",
          **route_config[:policy]
        })
        
        expect(attrs.routing_policy_type).to eq(route_config[:type])
      end
    end
    
    it "handles complex geolocation configurations" do
      geo_configs = [
        { continent: "EU" },
        { country: "US" },
        { country: "US", subdivision: "CA" },
        { country: "CA", subdivision: "ON" }
      ]
      
      geo_configs.each_with_index do |geo_config, index|
        attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "geo#{index}.example.com",
          type: "A",
          ttl: 300,
          records: ["203.0.113.1"],
          set_identifier: "geo-#{index}",
          geolocation_routing_policy: geo_config
        })
        
        expect(attrs.geolocation_routing_policy).to include(geo_config)
      end
    end
    
    it "validates weight constraints" do
      # Valid weight range (0-255)
      attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
        zone_id: test_zone_id,
        name: "weighted.example.com",
        type: "A",
        ttl: 300,
        records: ["203.0.113.1"],
        set_identifier: "weight-255",
        weighted_routing_policy: { weight: 255 }
      })
      expect(attrs.weighted_routing_policy[:weight]).to eq(255)
      
      # Invalid weight (over 255)
      expect {
        Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "invalid-weight.example.com",
          type: "A",
          ttl: 300,
          records: ["203.0.113.1"],
          set_identifier: "weight-256",
          weighted_routing_policy: { weight: 256 }
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end
  
  describe "DNS record type edge cases" do
    it "handles different IPv4 formats" do
      ipv4_formats = [
        "0.0.0.0",           # All zeros
        "255.255.255.255",   # All 255s
        "127.0.0.1",         # Localhost
        "192.168.1.1"        # Private IP
      ]
      
      ipv4_formats.each do |ip|
        attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "ipv4-test.example.com",
          type: "A",
          ttl: 300,
          records: [ip]
        })
        expect(attrs.records.first).to eq(ip)
      end
    end
    
    it "handles different MX priority values" do
      mx_priorities = [
        "0 mail.example.com",      # Minimum priority
        "10 primary.example.com",  # Common priority
        "65535 last.example.com"   # Maximum priority
      ]
      
      mx_priorities.each do |mx_record|
        attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "mx-test.example.com",
          type: "MX",
          ttl: 300,
          records: [mx_record]
        })
        expect(attrs.records.first).to eq(mx_record)
      end
    end
    
    it "handles SRV record variations" do
      srv_records = [
        "0 5 443 secure.example.com",
        "10 10 80 web.example.com",
        "20 0 22 ssh.example.com"  # Weight 0 (disabled)
      ]
      
      srv_records.each do |srv_record|
        attrs = Pangea::Resources::AWS::Types::Route53RecordAttributes.new({
          zone_id: test_zone_id,
          name: "_https._tcp.example.com",
          type: "SRV",
          ttl: 300,
          records: [srv_record]
        })
        expect(attrs.records.first).to eq(srv_record)
      end
    end
  end
end