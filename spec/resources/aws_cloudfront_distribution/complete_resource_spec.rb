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

# Load aws_cloudfront_distribution resource and types for testing
require 'pangea/resources/aws_cloudfront_distribution/resource'
require 'pangea/resources/aws_cloudfront_distribution/types'

RSpec.describe "aws_cloudfront_distribution resource function" do
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
  
  # Test data
  let(:s3_origin_domain) { "my-bucket.s3.amazonaws.com" }
  let(:custom_origin_domain) { "api.example.com" }
  let(:acm_certificate_arn) { "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012" }
  let(:web_acl_id) { "arn:aws:wafv2:us-east-1:123456789012:global/webacl/ExampleWebACL/473e64fd-f30b-4765-81a0-62ad96dd167a" }
  
  describe "CloudFrontDistributionAttributes validation" do
    it "accepts minimal S3 origin configuration" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{
          domain_name: s3_origin_domain,
          origin_id: "s3-origin",
          s3_origin_config: {
            origin_access_control_id: "E123456789012"
          }
        }],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "redirect-to-https"
        },
        comment: "Test S3 distribution",
        enabled: true
      })
      
      expect(distribution.origin.first[:domain_name]).to eq(s3_origin_domain)
      expect(distribution.origin.first[:s3_origin_config][:origin_access_control_id]).to eq("E123456789012")
      expect(distribution.default_cache_behavior[:target_origin_id]).to eq("s3-origin")
    end
    
    it "accepts custom origin configuration" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{
          domain_name: custom_origin_domain,
          origin_id: "api-origin",
          custom_origin_config: {
            http_port: 80,
            https_port: 443,
            origin_protocol_policy: "https-only",
            origin_ssl_protocols: ["TLSv1.2"]
          }
        }],
        default_cache_behavior: {
          target_origin_id: "api-origin",
          viewer_protocol_policy: "https-only"
        },
        comment: "Test API distribution",
        enabled: true
      })
      
      expect(distribution.origin.first[:custom_origin_config][:origin_protocol_policy]).to eq("https-only")
      expect(distribution.origin.first[:custom_origin_config][:origin_ssl_protocols]).to eq(["TLSv1.2"])
    end
    
    it "validates origin reference consistency" do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
          origin: [{
            domain_name: s3_origin_domain,
            origin_id: "s3-origin"
          }],
          default_cache_behavior: {
            target_origin_id: "non-existent-origin",
            viewer_protocol_policy: "redirect-to-https"
          },
          enabled: true
        })
      }.to raise_error(Dry::Struct::Error, /Default cache behavior references non-existent origin/)
    end
    
    it "validates unique origin IDs" do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
          origin: [
            { domain_name: s3_origin_domain, origin_id: "duplicate" },
            { domain_name: custom_origin_domain, origin_id: "duplicate" }
          ],
          default_cache_behavior: {
            target_origin_id: "duplicate",
            viewer_protocol_policy: "redirect-to-https"
          },
          enabled: true
        })
      }.to raise_error(Dry::Struct::Error, /Origin IDs must be unique/)
    end
    
    it "accepts multiple origins with different configurations" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [
          {
            domain_name: s3_origin_domain,
            origin_id: "s3-origin",
            s3_origin_config: {
              origin_access_control_id: "E123456789012"
            }
          },
          {
            domain_name: custom_origin_domain,
            origin_id: "api-origin",
            origin_path: "/api/v1",
            custom_origin_config: {
              origin_protocol_policy: "https-only",
              origin_ssl_protocols: ["TLSv1.2"]
            },
            custom_header: [
              { name: "X-Custom-Header", value: "custom-value" }
            ]
          }
        ],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "redirect-to-https"
        },
        enabled: true
      })
      
      expect(distribution.origin).to have(2).items
      expect(distribution.s3_origins_count).to eq(1)
      expect(distribution.custom_origins_count).to eq(1)
    end
    
    it "accepts origin shield configuration" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{
          domain_name: custom_origin_domain,
          origin_id: "api-origin",
          origin_shield: {
            enabled: true,
            origin_shield_region: "us-east-1"
          },
          custom_origin_config: {
            origin_protocol_policy: "https-only"
          }
        }],
        default_cache_behavior: {
          target_origin_id: "api-origin"
        },
        enabled: true
      })
      
      expect(distribution.has_origin_shield?).to eq(true)
      expect(distribution.origin.first[:origin_shield][:origin_shield_region]).to eq("us-east-1")
    end
    
    it "accepts ordered cache behaviors" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [
          { domain_name: s3_origin_domain, origin_id: "s3-origin" },
          { domain_name: custom_origin_domain, origin_id: "api-origin", custom_origin_config: { origin_protocol_policy: "https-only" } }
        ],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "redirect-to-https"
        },
        ordered_cache_behavior: [
          {
            path_pattern: "/api/*",
            target_origin_id: "api-origin",
            viewer_protocol_policy: "https-only",
            allowed_methods: ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
          },
          {
            path_pattern: "/admin/*",
            target_origin_id: "api-origin",
            viewer_protocol_policy: "https-only",
            compress: true
          }
        ],
        enabled: true
      })
      
      expect(distribution.ordered_cache_behavior).to have(2).items
      expect(distribution.total_behaviors_count).to eq(3) # default + 2 ordered
      expect(distribution.ordered_cache_behavior.first[:path_pattern]).to eq("/api/*")
    end
    
    it "validates ordered cache behavior origin references" do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
          origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
          default_cache_behavior: { target_origin_id: "s3-origin" },
          ordered_cache_behavior: [{
            path_pattern: "/api/*",
            target_origin_id: "non-existent"
          }],
          enabled: true
        })
      }.to raise_error(Dry::Struct::Error, /Ordered cache behavior 0 references non-existent origin/)
    end
    
    it "accepts Lambda@Edge associations" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          lambda_function_association: [{
            event_type: "viewer-request",
            lambda_arn: "arn:aws:lambda:us-east-1:123456789012:function:my-function:1",
            include_body: false
          }]
        },
        enabled: true
      })
      
      expect(distribution.has_lambda_at_edge?).to eq(true)
      lambda_assoc = distribution.default_cache_behavior[:lambda_function_association].first
      expect(lambda_assoc[:event_type]).to eq("viewer-request")
      expect(lambda_assoc[:lambda_arn]).to include("us-east-1")
    end
    
    it "validates Lambda@Edge ARN format" do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
          origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
          default_cache_behavior: {
            target_origin_id: "s3-origin",
            lambda_function_association: [{
              event_type: "viewer-request",
              lambda_arn: "arn:aws:lambda:us-west-2:123456789012:function:my-function:1" # Wrong region
            }]
          },
          enabled: true
        })
      }.to raise_error(Dry::Struct::Error, /Lambda@Edge function ARN must be from us-east-1/)
    end
    
    it "accepts CloudFront Functions associations" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          function_association: [{
            event_type: "viewer-request",
            function_arn: "arn:aws:cloudfront::123456789012:function/my-function"
          }]
        },
        enabled: true
      })
      
      expect(distribution.has_cloudfront_functions?).to eq(true)
      func_assoc = distribution.default_cache_behavior[:function_association].first
      expect(func_assoc[:event_type]).to eq("viewer-request")
    end
    
    it "accepts custom error responses" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
        default_cache_behavior: { target_origin_id: "s3-origin" },
        custom_error_response: [
          {
            error_code: 404,
            response_code: 200,
            response_page_path: "/404.html",
            error_caching_min_ttl: 300
          },
          {
            error_code: 500,
            response_code: 500,
            response_page_path: "/500.html"
          }
        ],
        enabled: true
      })
      
      expect(distribution.has_custom_error_pages?).to eq(true)
      expect(distribution.custom_error_response).to have(2).items
    end
    
    it "validates unique error codes" do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
          origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
          default_cache_behavior: { target_origin_id: "s3-origin" },
          custom_error_response: [
            { error_code: 404, response_page_path: "/404.html" },
            { error_code: 404, response_page_path: "/other-404.html" }
          ],
          enabled: true
        })
      }.to raise_error(Dry::Struct::Error, /Custom error response codes must be unique/)
    end
    
    it "accepts geographic restrictions" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
        default_cache_behavior: { target_origin_id: "s3-origin" },
        restrictions: {
          geo_restriction: {
            restriction_type: "whitelist",
            locations: ["US", "CA", "GB"]
          }
        },
        enabled: true
      })
      
      expect(distribution.has_geographic_restrictions?).to eq(true)
      geo_restriction = distribution.restrictions[:geo_restriction]
      expect(geo_restriction[:restriction_type]).to eq("whitelist")
      expect(geo_restriction[:locations]).to include("US", "CA", "GB")
    end
    
    it "validates geographic restrictions require locations" do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
          origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
          default_cache_behavior: { target_origin_id: "s3-origin" },
          restrictions: {
            geo_restriction: {
              restriction_type: "blacklist",
              locations: []
            }
          },
          enabled: true
        })
      }.to raise_error(Dry::Struct::Error, /Geographic restrictions require location codes/)
    end
    
    it "accepts ACM SSL certificate configuration" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
        default_cache_behavior: { target_origin_id: "s3-origin" },
        aliases: ["www.example.com", "example.com"],
        viewer_certificate: {
          acm_certificate_arn: acm_certificate_arn,
          ssl_support_method: "sni-only",
          minimum_protocol_version: "TLSv1.2_2021"
        },
        enabled: true
      })
      
      expect(distribution.has_custom_ssl?).to eq(true)
      expect(distribution.has_custom_domain?).to eq(true)
      expect(distribution.primary_domain).to eq("www.example.com")
    end
    
    it "validates SSL certificate requirements for aliases" do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
          origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
          default_cache_behavior: { target_origin_id: "s3-origin" },
          aliases: ["example.com"],
          viewer_certificate: {},
          enabled: true
        })
      }.to raise_error(Dry::Struct::Error, /Custom aliases require a custom SSL certificate/)
    end
    
    it "validates CloudFront default certificate cannot be used with aliases" do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
          origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
          default_cache_behavior: { target_origin_id: "s3-origin" },
          aliases: ["example.com"],
          viewer_certificate: {
            cloudfront_default_certificate: true
          },
          enabled: true
        })
      }.to raise_error(Dry::Struct::Error, /Cannot use CloudFront default certificate with custom aliases/)
    end
    
    it "validates only one SSL certificate source" do
      expect {
        Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
          origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
          default_cache_behavior: { target_origin_id: "s3-origin" },
          viewer_certificate: {
            acm_certificate_arn: acm_certificate_arn,
            iam_certificate_id: "ASCA123456789012345"
          },
          enabled: true
        })
      }.to raise_error(Dry::Struct::Error, /Only one SSL certificate source can be specified/)
    end
    
    it "accepts Web ACL association" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
        default_cache_behavior: { target_origin_id: "s3-origin" },
        web_acl_id: web_acl_id,
        enabled: true
      })
      
      expect(distribution.web_acl_id).to eq(web_acl_id)
    end
    
    it "calculates security profile correctly" do
      # Basic profile
      basic_distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
        default_cache_behavior: { 
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "allow-all"
        },
        enabled: true
      })
      expect(basic_distribution.security_profile).to eq('basic')
      
      # Enhanced profile
      enhanced_distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
        default_cache_behavior: { 
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "https-only"
        },
        viewer_certificate: {
          acm_certificate_arn: acm_certificate_arn
        },
        aliases: ["example.com"],
        enabled: true
      })
      expect(enhanced_distribution.security_profile).to eq('enhanced')
      
      # Maximum profile
      maximum_distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
        default_cache_behavior: { 
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "https-only"
        },
        viewer_certificate: {
          acm_certificate_arn: acm_certificate_arn
        },
        aliases: ["example.com"],
        web_acl_id: web_acl_id,
        restrictions: {
          geo_restriction: {
            restriction_type: "whitelist",
            locations: ["US"]
          }
        },
        enabled: true
      })
      expect(maximum_distribution.security_profile).to eq('maximum')
    end
    
    it "accepts different price classes" do
      ['PriceClass_All', 'PriceClass_200', 'PriceClass_100'].each do |price_class|
        distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
          origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
          default_cache_behavior: { target_origin_id: "s3-origin" },
          price_class: price_class,
          enabled: true
        })
        
        expect(distribution.price_class).to eq(price_class)
        case price_class
        when 'PriceClass_100'
          expect(distribution.estimated_cost_tier).to eq('low')
        when 'PriceClass_200'
          expect(distribution.estimated_cost_tier).to eq('medium')
        else
          expect(distribution.estimated_cost_tier).to eq('high')
        end
      end
    end
    
    it "accepts different HTTP versions" do
      distribution = Pangea::Resources::AWS::Types::CloudFrontDistributionAttributes.new({
        origin: [{ domain_name: s3_origin_domain, origin_id: "s3-origin" }],
        default_cache_behavior: { target_origin_id: "s3-origin" },
        http_version: "http2",
        enabled: true
      })
      
      expect(distribution.supports_http2?).to eq(true)
      expect(distribution.ipv6_enabled?).to eq(true)
    end
  end
  
  describe "aws_cloudfront_distribution function" do
    it "creates basic S3 distribution" do
      result = test_instance.aws_cloudfront_distribution(:s3_website, {
        origin: [{
          domain_name: s3_origin_domain,
          origin_id: "s3-origin",
          s3_origin_config: {
            origin_access_control_id: "E123456789012"
          }
        }],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "redirect-to-https"
        },
        comment: "S3 website distribution",
        enabled: true
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_cloudfront_distribution')
      expect(result.name).to eq(:s3_website)
      expect(result.domain_name).to eq("${aws_cloudfront_distribution.s3_website.domain_name}")
    end
    
    it "creates distribution with custom origins and multiple behaviors" do
      result = test_instance.aws_cloudfront_distribution(:multi_origin, {
        origin: [
          {
            domain_name: s3_origin_domain,
            origin_id: "s3-origin",
            s3_origin_config: {
              origin_access_control_id: "E123456789012"
            }
          },
          {
            domain_name: custom_origin_domain,
            origin_id: "api-origin",
            origin_path: "/v1",
            custom_origin_config: {
              origin_protocol_policy: "https-only",
              origin_ssl_protocols: ["TLSv1.2"]
            },
            custom_header: [
              { name: "X-Forwarded-Host", value: "api.example.com" }
            ]
          }
        ],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "redirect-to-https",
          compress: true
        },
        ordered_cache_behavior: [
          {
            path_pattern: "/api/*",
            target_origin_id: "api-origin",
            viewer_protocol_policy: "https-only",
            allowed_methods: ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"],
            cached_methods: ["GET", "HEAD", "OPTIONS"]
          }
        ],
        comment: "Multi-origin distribution",
        enabled: true
      })
      
      expect(result.resource_attributes[:origin]).to have(2).items
      expect(result.resource_attributes[:ordered_cache_behavior]).to have(1).item
      expect(result.total_origins_count).to eq(2)
      expect(result.total_behaviors_count).to eq(2)
      expect(result.s3_origins_count).to eq(1)
      expect(result.custom_origins_count).to eq(1)
    end
    
    it "creates distribution with Lambda@Edge and CloudFront Functions" do
      result = test_instance.aws_cloudfront_distribution(:edge_computing, {
        origin: [{
          domain_name: s3_origin_domain,
          origin_id: "s3-origin"
        }],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "https-only",
          lambda_function_association: [{
            event_type: "origin-request",
            lambda_arn: "arn:aws:lambda:us-east-1:123456789012:function:origin-selector:1",
            include_body: false
          }],
          function_association: [{
            event_type: "viewer-request",
            function_arn: "arn:aws:cloudfront::123456789012:function/security-headers"
          }]
        },
        comment: "Edge computing distribution",
        enabled: true
      })
      
      expect(result.has_lambda_at_edge?).to eq(true)
      expect(result.has_cloudfront_functions?).to eq(true)
    end
    
    it "creates distribution with custom SSL and aliases" do
      result = test_instance.aws_cloudfront_distribution(:custom_domain, {
        origin: [{
          domain_name: s3_origin_domain,
          origin_id: "s3-origin"
        }],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "https-only"
        },
        aliases: ["www.example.com", "example.com"],
        viewer_certificate: {
          acm_certificate_arn: acm_certificate_arn,
          ssl_support_method: "sni-only",
          minimum_protocol_version: "TLSv1.2_2021"
        },
        comment: "Custom domain distribution",
        enabled: true
      })
      
      expect(result.has_custom_ssl?).to eq(true)
      expect(result.has_custom_domain?).to eq(true)
      expect(result.primary_domain).to eq("www.example.com")
      expect(result.resource_attributes[:aliases]).to include("www.example.com", "example.com")
    end
    
    it "creates distribution with geographic restrictions and WAF" do
      result = test_instance.aws_cloudfront_distribution(:geo_restricted, {
        origin: [{
          domain_name: s3_origin_domain,
          origin_id: "s3-origin"
        }],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "https-only"
        },
        restrictions: {
          geo_restriction: {
            restriction_type: "whitelist",
            locations: ["US", "CA", "MX"]
          }
        },
        web_acl_id: web_acl_id,
        comment: "Geo-restricted distribution",
        enabled: true
      })
      
      expect(result.has_geographic_restrictions?).to eq(true)
      expect(result.security_profile).to eq("maximum")
    end
    
    it "creates distribution with custom error pages" do
      result = test_instance.aws_cloudfront_distribution(:custom_errors, {
        origin: [{
          domain_name: s3_origin_domain,
          origin_id: "s3-origin"
        }],
        default_cache_behavior: {
          target_origin_id: "s3-origin"
        },
        custom_error_response: [
          {
            error_code: 404,
            response_code: 200,
            response_page_path: "/404.html",
            error_caching_min_ttl: 300
          },
          {
            error_code: 403,
            response_code: 200,
            response_page_path: "/403.html",
            error_caching_min_ttl: 300
          }
        ],
        comment: "Distribution with custom error pages",
        enabled: true
      })
      
      expect(result.has_custom_error_pages?).to eq(true)
      expect(result.resource_attributes[:custom_error_response]).to have(2).items
    end
    
    it "creates distribution with origin shield" do
      result = test_instance.aws_cloudfront_distribution(:origin_shield, {
        origin: [{
          domain_name: custom_origin_domain,
          origin_id: "api-origin",
          origin_shield: {
            enabled: true,
            origin_shield_region: "us-east-1"
          },
          custom_origin_config: {
            origin_protocol_policy: "https-only"
          }
        }],
        default_cache_behavior: {
          target_origin_id: "api-origin",
          viewer_protocol_policy: "https-only"
        },
        comment: "Distribution with Origin Shield",
        enabled: true
      })
      
      expect(result.has_origin_shield?).to eq(true)
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_cloudfront_distribution(:test, {
        origin: [{
          domain_name: s3_origin_domain,
          origin_id: "s3-origin"
        }],
        default_cache_behavior: {
          target_origin_id: "s3-origin"
        },
        enabled: true
      })
      
      expect(result.id).to eq("${aws_cloudfront_distribution.test.id}")
      expect(result.arn).to eq("${aws_cloudfront_distribution.test.arn}")
      expect(result.domain_name).to eq("${aws_cloudfront_distribution.test.domain_name}")
      expect(result.hosted_zone_id).to eq("${aws_cloudfront_distribution.test.hosted_zone_id}")
      expect(result.etag).to eq("${aws_cloudfront_distribution.test.etag}")
      expect(result.status).to eq("${aws_cloudfront_distribution.test.status}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_cloudfront_distribution(:computed_test, {
        origin: [
          {
            domain_name: s3_origin_domain,
            origin_id: "s3-origin",
            s3_origin_config: {
              origin_access_control_id: "E123456789012"
            }
          },
          {
            domain_name: custom_origin_domain,
            origin_id: "api-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only"
            }
          }
        ],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "https-only"
        },
        ordered_cache_behavior: [
          {
            path_pattern: "/api/*",
            target_origin_id: "api-origin"
          }
        ],
        aliases: ["example.com"],
        viewer_certificate: {
          acm_certificate_arn: acm_certificate_arn
        },
        http_version: "http2",
        is_ipv6_enabled: true,
        price_class: "PriceClass_200",
        enabled: true
      })
      
      expect(result.total_origins_count).to eq(2)
      expect(result.total_behaviors_count).to eq(2)
      expect(result.s3_origins_count).to eq(1)
      expect(result.custom_origins_count).to eq(1)
      expect(result.has_custom_ssl?).to eq(true)
      expect(result.has_custom_domain?).to eq(true)
      expect(result.supports_http2?).to eq(true)
      expect(result.ipv6_enabled?).to eq(true)
      expect(result.estimated_cost_tier).to eq("medium")
      expect(result.primary_domain).to eq("example.com")
      expect(result.security_profile).to eq("enhanced")
    end
  end
  
  describe "distribution patterns" do
    it "creates global web application distribution" do
      result = test_instance.aws_cloudfront_distribution(:global_webapp, {
        origin: [
          {
            domain_name: "us-app.example.com",
            origin_id: "us-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only",
              origin_ssl_protocols: ["TLSv1.2"]
            },
            custom_header: [
              { name: "X-CloudFront-Region", value: "us-east-1" }
            ]
          },
          {
            domain_name: "eu-app.example.com", 
            origin_id: "eu-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only"
            }
          }
        ],
        default_cache_behavior: {
          target_origin_id: "us-origin",
          viewer_protocol_policy: "https-only",
          compress: true
        },
        ordered_cache_behavior: [
          {
            path_pattern: "/eu/*",
            target_origin_id: "eu-origin",
            viewer_protocol_policy: "https-only"
          }
        ],
        aliases: ["app.example.com"],
        viewer_certificate: {
          acm_certificate_arn: acm_certificate_arn,
          ssl_support_method: "sni-only"
        },
        comment: "Global web application with regional origins",
        enabled: true
      })
      
      expect(result.total_origins_count).to eq(2)
      expect(result.has_custom_ssl?).to eq(true)
      expect(result.security_profile).to eq("enhanced")
    end
    
    it "creates API-first distribution with edge functions" do
      result = test_instance.aws_cloudfront_distribution(:api_first, {
        origin: [{
          domain_name: "api.example.com",
          origin_id: "api-origin", 
          custom_origin_config: {
            origin_protocol_policy: "https-only"
          }
        }],
        default_cache_behavior: {
          target_origin_id: "api-origin",
          viewer_protocol_policy: "https-only",
          allowed_methods: ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"],
          cached_methods: ["GET", "HEAD"],
          lambda_function_association: [{
            event_type: "viewer-request",
            lambda_arn: "arn:aws:lambda:us-east-1:123456789012:function:auth-check:1"
          }],
          function_association: [{
            event_type: "viewer-response",
            function_arn: "arn:aws:cloudfront::123456789012:function/cors-headers"
          }]
        },
        aliases: ["api.example.com"],
        viewer_certificate: {
          acm_certificate_arn: acm_certificate_arn
        },
        comment: "API-first distribution with edge computing",
        enabled: true
      })
      
      expect(result.has_lambda_at_edge?).to eq(true)
      expect(result.has_cloudfront_functions?).to eq(true)
    end
    
    it "creates static website with SPA routing" do
      result = test_instance.aws_cloudfront_distribution(:spa_website, {
        origin: [{
          domain_name: "my-spa-bucket.s3.amazonaws.com",
          origin_id: "s3-origin",
          s3_origin_config: {
            origin_access_control_id: "E123456789012"
          }
        }],
        default_cache_behavior: {
          target_origin_id: "s3-origin",
          viewer_protocol_policy: "redirect-to-https",
          compress: true
        },
        custom_error_response: [
          {
            error_code: 404,
            response_code: 200,
            response_page_path: "/index.html"
          },
          {
            error_code: 403,
            response_code: 200, 
            response_page_path: "/index.html"
          }
        ],
        default_root_object: "index.html",
        aliases: ["spa.example.com"],
        viewer_certificate: {
          acm_certificate_arn: acm_certificate_arn
        },
        comment: "SPA website with client-side routing",
        enabled: true
      })
      
      expect(result.has_custom_error_pages?).to eq(true)
      expect(result.resource_attributes[:default_root_object]).to eq("index.html")
    end
  end
end