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

# Load aws_route53_zone resource and types for testing
require 'pangea/resources/aws_route53_zone/resource'
require 'pangea/resources/aws_route53_zone/types'

RSpec.describe "aws_route53_zone resource function" do
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
  
  describe "Route53ZoneAttributes validation" do
    it "accepts minimal public zone configuration" do
      attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "example.com"
      })
      
      expect(attrs.name).to eq("example.com")
      expect(attrs.force_destroy).to eq(false)
      expect(attrs.vpc).to be_empty
      expect(attrs.tags).to be_empty
    end
    
    it "accepts private zone with VPC configuration" do
      attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "internal.company.com",
        vpc: [{ vpc_id: "vpc-12345678" }],
        comment: "Internal services zone"
      })
      
      expect(attrs.name).to eq("internal.company.com")
      expect(attrs.vpc.first[:vpc_id]).to eq("vpc-12345678")
      expect(attrs.comment).to eq("Internal services zone")
    end
    
    it "validates domain name format" do
      invalid_domains = [
        ".example.com",      # Starts with dot
        "example.com.",      # Ends with dot
        "",                  # Empty string
        "a" * 254,          # Too long (over 253 chars)
        "example..com",      # Double dots
        "exam ple.com"       # Contains space
      ]
      
      invalid_domains.each do |invalid_domain|
        expect {
          Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
            name: invalid_domain
          })
        }.to raise_error(Dry::Struct::Error)
      end
    end
    
    it "validates DNS label requirements" do
      invalid_labels = [
        "-example.com",      # Label starts with hyphen
        "example-.com",      # Label ends with hyphen
        "exa_mple.com",      # Underscore in label (should warn, not fail)
        "a" * 64 + ".com"    # Label too long (over 63 chars)
      ]
      
      invalid_labels[0..2].each do |invalid_domain|
        expect {
          Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
            name: invalid_domain
          })
        }.to raise_error(Dry::Struct::Error)
      end
    end
    
    it "accepts valid domain formats" do
      valid_domains = [
        "example.com",
        "sub.example.com",
        "deep.sub.example.com",
        "test-domain.com",
        "123.com",
        "a.b",
        "x" * 63 + ".com"    # Maximum label length
      ]
      
      valid_domains.each do |valid_domain|
        attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
          name: valid_domain
        })
        expect(attrs.name).to eq(valid_domain)
      end
    end
    
    it "validates VPC ID format when provided" do
      invalid_vpc_ids = [
        "invalid-vpc",
        "vpc-short",
        "vpc-12345",        # Too short
        "vpc-123456789abcdefghij"  # Too long
      ]
      
      invalid_vpc_ids.each do |invalid_vpc_id|
        expect {
          Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
            name: "example.com",
            vpc: [{ vpc_id: invalid_vpc_id }]
          })
        }.to raise_error(Dry::Struct::Error, /Invalid VPC ID format/)
      end
    end
    
    it "accepts valid VPC ID formats" do
      valid_vpc_ids = [
        "vpc-12345678",          # 8 character ID
        "vpc-1234567890abcdef"   # 17 character ID
      ]
      
      valid_vpc_ids.each do |valid_vpc_id|
        attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
          name: "internal.example.com",
          vpc: [{ vpc_id: valid_vpc_id }]
        })
        expect(attrs.vpc.first[:vpc_id]).to eq(valid_vpc_id)
      end
    end
    
    it "validates delegation set ID format when provided" do
      invalid_delegation_ids = [
        "invalid-set-id",
        "delegation-123",
        "123-abc-def"
      ]
      
      invalid_delegation_ids.each do |invalid_id|
        expect {
          Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
            name: "example.com",
            delegation_set_id: invalid_id
          })
        }.to raise_error(Dry::Struct::Error, /Invalid delegation set ID format/)
      end
    end
    
    it "accepts valid delegation set ID format" do
      valid_delegation_ids = [
        "N1PA6795SAMPLE",
        "ABCDEFGHIJKLMNOP"
      ]
      
      valid_delegation_ids.each do |valid_id|
        attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
          name: "example.com",
          delegation_set_id: valid_id
        })
        expect(attrs.delegation_set_id).to eq(valid_id)
      end
    end
    
    it "detects zone type based on VPC configuration" do
      # Public zone (no VPCs)
      public_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "public.example.com"
      })
      expect(public_attrs.is_public?).to eq(true)
      expect(public_attrs.is_private?).to eq(false)
      expect(public_attrs.zone_type).to eq("public")
      
      # Private zone (with VPCs)
      private_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "private.example.com",
        vpc: [{ vpc_id: "vpc-12345678" }]
      })
      expect(private_attrs.is_private?).to eq(true)
      expect(private_attrs.is_public?).to eq(false)
      expect(private_attrs.zone_type).to eq("private")
    end
    
    it "analyzes domain structure" do
      # Root domain
      root_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "example.com"
      })
      expect(root_attrs.root_domain?).to eq(true)
      expect(root_attrs.subdomain?).to eq(false)
      expect(root_attrs.domain_parts).to eq(["example", "com"])
      expect(root_attrs.top_level_domain).to eq("com")
      expect(root_attrs.parent_domain).to be_nil
      
      # Subdomain
      sub_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "api.v2.example.com"
      })
      expect(sub_attrs.root_domain?).to eq(false)
      expect(sub_attrs.subdomain?).to eq(true)
      expect(sub_attrs.domain_parts).to eq(["api", "v2", "example", "com"])
      expect(sub_attrs.parent_domain).to eq("v2.example.com")
    end
    
    it "detects AWS service domains" do
      aws_domains = [
        "my-service.amazonaws.com",
        "internal.aws.amazon.com"
      ]
      
      aws_domains.each do |aws_domain|
        attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
          name: aws_domain
        })
        expect(attrs.aws_service_domain?).to eq(true)
      end
      
      non_aws_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "example.com"
      })
      expect(non_aws_attrs.aws_service_domain?).to eq(false)
    end
    
    it "counts VPCs correctly" do
      single_vpc_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "single.example.com",
        vpc: [{ vpc_id: "vpc-12345678" }]
      })
      expect(single_vpc_attrs.vpc_count).to eq(1)
      
      multi_vpc_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "multi.example.com",
        vpc: [
          { vpc_id: "vpc-12345678", vpc_region: "us-east-1" },
          { vpc_id: "vpc-87654321", vpc_region: "us-west-2" }
        ]
      })
      expect(multi_vpc_attrs.vpc_count).to eq(2)
    end
    
    it "provides configuration warnings" do
      # Force destroy warning
      force_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "example.com",
        force_destroy: true
      })
      warnings = force_attrs.validate_configuration
      expect(warnings).to include(/force_destroy is enabled/)
      
      # Domain with underscores warning
      underscore_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "test_domain.com"
      })
      warnings = underscore_attrs.validate_configuration
      expect(warnings).to include(/contains underscores/)
      
      # Very long domain warning
      long_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "very-" + "long-" * 40 + "domain.com"  # Over 200 chars
      })
      warnings = long_attrs.validate_configuration
      expect(warnings).to include(/Very long domain name/)
    end
    
    it "estimates monthly cost" do
      attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "example.com"
      })
      cost = attrs.estimated_monthly_cost
      expect(cost).to include("$0.5/month")
      expect(cost).to include("per million queries")
    end
  end
  
  describe "aws_route53_zone function behavior" do
    it "creates a zone with minimal attributes" do
      ref = test_instance.aws_route53_zone(:test_zone, {
        name: "example.com"
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.type).to eq('aws_route53_zone')
      expect(ref.name).to eq(:test_zone)
    end
    
    it "creates a public zone with comment" do
      ref = test_instance.aws_route53_zone(:public_zone, {
        name: "public.example.com",
        comment: "Public facing website zone",
        tags: {
          Environment: "production",
          Purpose: "website"
        }
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("public.example.com")
      expect(attrs[:comment]).to eq("Public facing website zone")
      expect(attrs[:tags][:Environment]).to eq("production")
    end
    
    it "creates a private zone with VPC association" do
      ref = test_instance.aws_route53_zone(:private_zone, {
        name: "internal.company.com",
        vpc: [{ 
          vpc_id: "vpc-12345678",
          vpc_region: "us-east-1"
        }],
        comment: "Internal services zone"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("internal.company.com")
      expect(attrs[:vpc].first[:vpc_id]).to eq("vpc-12345678")
      expect(attrs[:vpc].first[:vpc_region]).to eq("us-east-1")
    end
    
    it "creates a multi-VPC private zone" do
      ref = test_instance.aws_route53_zone(:multi_vpc_zone, {
        name: "shared.internal.com",
        vpc: [
          { vpc_id: "vpc-12345678", vpc_region: "us-east-1" },
          { vpc_id: "vpc-87654321", vpc_region: "us-west-2" }
        ]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:vpc].length).to eq(2)
      expect(attrs[:vpc][0][:vpc_id]).to eq("vpc-12345678")
      expect(attrs[:vpc][1][:vpc_id]).to eq("vpc-87654321")
    end
    
    it "creates a development zone with force destroy" do
      ref = test_instance.aws_route53_zone(:dev_zone, {
        name: "dev.example.com",
        force_destroy: true,
        comment: "Development environment zone"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:force_destroy]).to eq(true)
    end
    
    it "creates a zone with delegation set" do
      ref = test_instance.aws_route53_zone(:delegated_zone, {
        name: "delegated.example.com",
        delegation_set_id: "N1PA6795SAMPLE"
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:delegation_set_id]).to eq("N1PA6795SAMPLE")
    end
    
    it "provides all expected outputs" do
      ref = test_instance.aws_route53_zone(:test_zone, {
        name: "example.com"
      })
      
      expected_outputs = [:id, :zone_id, :arn, :name, :name_servers, 
                         :primary_name_server, :comment, :tags_all]
      
      expected_outputs.each do |output|
        expect(ref.outputs).to have_key(output)
        expect(ref.outputs[output]).to include("${aws_route53_zone.test_zone.")
      end
    end
    
    it "provides computed properties for public zones" do
      ref = test_instance.aws_route53_zone(:public_zone, {
        name: "api.v1.example.com"
      })
      
      expect(ref.is_public?).to eq(true)
      expect(ref.is_private?).to eq(false)
      expect(ref.zone_type).to eq("public")
      expect(ref.vpc_count).to eq(0)
      expect(ref.subdomain?).to eq(true)
      expect(ref.root_domain?).to eq(false)
      expect(ref.parent_domain).to eq("v1.example.com")
      expect(ref.top_level_domain).to eq("com")
    end
    
    it "provides computed properties for private zones" do
      ref = test_instance.aws_route53_zone(:private_zone, {
        name: "internal.company.com",
        vpc: [
          { vpc_id: "vpc-12345678" },
          { vpc_id: "vpc-87654321" }
        ]
      })
      
      expect(ref.is_private?).to eq(true)
      expect(ref.is_public?).to eq(false)
      expect(ref.zone_type).to eq("private")
      expect(ref.vpc_count).to eq(2)
    end
  end
  
  describe "Route53ZoneConfigs module usage" do
    it "creates public zone configuration" do
      config = Pangea::Resources::AWS::Types::Route53ZoneConfigs.public_zone("example.com")
      ref = test_instance.aws_route53_zone(:public_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("example.com")
      expect(attrs[:force_destroy]).to eq(false)
      expect(attrs[:comment]).to include("Public hosted zone")
    end
    
    it "creates private zone configuration" do
      config = Pangea::Resources::AWS::Types::Route53ZoneConfigs.private_zone(
        "internal.company.com", 
        "vpc-12345678",
        vpc_region: "us-east-1"
      )
      ref = test_instance.aws_route53_zone(:private_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:vpc].first[:vpc_id]).to eq("vpc-12345678")
      expect(attrs[:vpc].first[:vpc_region]).to eq("us-east-1")
    end
    
    it "creates multi-VPC configuration" do
      vpc_configs = [
        { vpc_id: "vpc-12345678", vpc_region: "us-east-1" },
        { vpc_id: "vpc-87654321", vpc_region: "us-west-2" }
      ]
      
      config = Pangea::Resources::AWS::Types::Route53ZoneConfigs.multi_vpc_private_zone(
        "shared.internal.com",
        vpc_configs
      )
      ref = test_instance.aws_route53_zone(:multi_vpc_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:vpc].length).to eq(2)
    end
    
    it "creates development zone configuration" do
      config = Pangea::Resources::AWS::Types::Route53ZoneConfigs.development_zone(
        "dev.example.com",
        is_private: true,
        vpc_id: "vpc-12345678"
      )
      ref = test_instance.aws_route53_zone(:dev_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:force_destroy]).to eq(true)
      expect(attrs[:vpc].first[:vpc_id]).to eq("vpc-12345678")
    end
    
    it "creates corporate internal zone configuration" do
      vpc_configs = [
        { vpc_id: "vpc-12345678", vpc_region: "us-east-1" },
        { vpc_id: "vpc-87654321", vpc_region: "us-west-2" }
      ]
      
      config = Pangea::Resources::AWS::Types::Route53ZoneConfigs.corporate_internal_zone(
        "corp.internal",
        vpc_configs
      )
      ref = test_instance.aws_route53_zone(:corp_config, config)
      
      attrs = ref.resource_attributes
      expect(attrs[:name]).to eq("corp.internal")
      expect(attrs[:vpc].length).to eq(2)
      expect(attrs[:comment]).to include("Corporate internal")
    end
  end
  
  describe "resource reference integration" do
    it "provides terraform interpolation syntax for outputs" do
      ref = test_instance.aws_route53_zone(:test_zone, {
        name: "example.com"
      })
      
      expect(ref.outputs[:id]).to eq("${aws_route53_zone.test_zone.id}")
      expect(ref.outputs[:zone_id]).to eq("${aws_route53_zone.test_zone.zone_id}")
      expect(ref.outputs[:arn]).to eq("${aws_route53_zone.test_zone.arn}")
      expect(ref.outputs[:name_servers]).to eq("${aws_route53_zone.test_zone.name_servers}")
    end
    
    it "can be used with VPC references" do
      # This would typically use a ResourceReference from aws_vpc
      vpc_id = "${aws_vpc.main.id}"  # Simulated VPC reference
      
      ref = test_instance.aws_route53_zone(:vpc_zone, {
        name: "internal.example.com",
        vpc: [{ vpc_id: vpc_id }]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:vpc].first[:vpc_id]).to eq(vpc_id)
    end
  end
  
  describe "error conditions and edge cases" do
    it "handles string keys in attributes" do
      ref = test_instance.aws_route53_zone(:string_keys, {
        "name" => "string-test.com",
        "comment" => "String key test",
        "force_destroy" => true
      })
      
      expect(ref.resource_attributes[:name]).to eq("string-test.com")
      expect(ref.resource_attributes[:comment]).to eq("String key test")
      expect(ref.resource_attributes[:force_destroy]).to eq(true)
    end
    
    it "generates default comments for zones without comments" do
      # Public zone default comment
      public_ref = test_instance.aws_route53_zone(:public_auto_comment, {
        name: "auto.example.com"
      })
      expect(public_ref.resource_attributes[:comment]).to include("Public hosted zone")
      
      # Private zone default comment
      private_ref = test_instance.aws_route53_zone(:private_auto_comment, {
        name: "internal.auto.com",
        vpc: [{ vpc_id: "vpc-12345678" }]
      })
      expect(private_ref.resource_attributes[:comment]).to include("Private hosted zone")
    end
    
    it "handles complex domain hierarchies" do
      complex_domains = [
        "api.v2.production.company.com",
        "service.region.env.internal",
        "deep.very.deep.structure.example.org"
      ]
      
      complex_domains.each do |domain|
        attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
          name: domain
        })
        
        expect(attrs.subdomain?).to eq(true)
        expect(attrs.domain_parts.length).to be > 2
      end
    end
    
    it "handles VPC configurations without regions" do
      ref = test_instance.aws_route53_zone(:no_region, {
        name: "no-region.internal.com",
        vpc: [{ vpc_id: "vpc-12345678" }]  # No vpc_region specified
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:vpc].first[:vpc_id]).to eq("vpc-12345678")
      expect(attrs[:vpc].first).not_to have_key(:vpc_region)
    end
  end
  
  describe "domain validation edge cases" do
    it "validates single character labels" do
      attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "a.b"
      })
      expect(attrs.name).to eq("a.b")
    end
    
    it "validates maximum label length" do
      max_label = "a" * 63
      attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "#{max_label}.com"
      })
      expect(attrs.name).to eq("#{max_label}.com")
    end
    
    it "validates numeric domains" do
      numeric_domains = [
        "123.com",
        "456.789.com",
        "1.2.3.com"
      ]
      
      numeric_domains.each do |domain|
        attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
          name: domain
        })
        expect(attrs.name).to eq(domain)
      end
    end
    
    it "validates international domain patterns" do
      # Note: This tests ASCII-only validation - full IDN support would require additional logic
      ascii_international = [
        "example.co.uk",
        "test.com.au",
        "site.org.nz"
      ]
      
      ascii_international.each do |domain|
        attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
          name: domain
        })
        expect(attrs.name).to eq(domain)
      end
    end
  end
  
  describe "VPC integration patterns" do
    it "validates VPC ID edge cases" do
      # Minimum length VPC ID
      min_vpc_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "min.example.com",
        vpc: [{ vpc_id: "vpc-12345678" }]  # 8 chars after vpc-
      })
      expect(min_vpc_attrs.vpc.first[:vpc_id]).to eq("vpc-12345678")
      
      # Maximum length VPC ID
      max_vpc_attrs = Pangea::Resources::AWS::Types::Route53ZoneAttributes.new({
        name: "max.example.com",
        vpc: [{ vpc_id: "vpc-1234567890abcdef1" }]  # 17 chars after vpc-
      })
      expect(max_vpc_attrs.vpc.first[:vpc_id]).to eq("vpc-1234567890abcdef1")
    end
    
    it "handles mixed VPC configuration formats" do
      ref = test_instance.aws_route53_zone(:mixed_vpc, {
        name: "mixed.internal.com",
        vpc: [
          { vpc_id: "vpc-12345678" },  # No region
          { vpc_id: "vpc-87654321", vpc_region: "us-west-2" }  # With region
        ]
      })
      
      attrs = ref.resource_attributes
      expect(attrs[:vpc][0]).to have_key(:vpc_id)
      expect(attrs[:vpc][0]).not_to have_key(:vpc_region)
      expect(attrs[:vpc][1]).to have_key(:vpc_region)
    end
  end
end