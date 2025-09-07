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
require 'terraform-synthesizer'

# Require the AWS CloudFront distribution module
require 'pangea/resources/aws_cloudfront_distribution/resource'
require 'pangea/resources/aws_cloudfront_distribution/types'

RSpec.describe "aws_cloudfront_distribution synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }

  # Extend the synthesizer with our AWS module for resource access
  before do
    synthesizer.extend(Pangea::Resources::AWS)
  end

  describe "basic distribution synthesis" do
    it "synthesizes minimal S3 distribution" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:s3_basic, {
          origin: [{
            domain_name: "my-bucket.s3.amazonaws.com",
            origin_id: "s3-origin",
            s3_origin_config: {
              origin_access_control_id: "E123456789012"
            }
          }],
          default_cache_behavior: {
            target_origin_id: "s3-origin",
            viewer_protocol_policy: "redirect-to-https"
          },
          comment: "Basic S3 distribution",
          enabled: true
        })
        
        synthesis
      end
      
      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_cloudfront_distribution")
      expect(result["resource"]["aws_cloudfront_distribution"]).to have_key("s3_basic")
      
      distribution = result["resource"]["aws_cloudfront_distribution"]["s3_basic"]
      expect(distribution["comment"]).to eq("Basic S3 distribution")
      expect(distribution["enabled"]).to eq(true)
      expect(distribution["origin"]).to be_an(Array)
      expect(distribution["origin"].first["domain_name"]).to eq("my-bucket.s3.amazonaws.com")
      expect(distribution["default_cache_behavior"]["target_origin_id"]).to eq("s3-origin")
    end
    
    it "synthesizes custom origin distribution" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:custom_origin, {
          origin: [{
            domain_name: "api.example.com",
            origin_id: "api-origin",
            origin_path: "/v1",
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
          comment: "Custom origin distribution",
          enabled: true
        })
        
        synthesis
      end
      
      distribution = result["resource"]["aws_cloudfront_distribution"]["custom_origin"]
      origin = distribution["origin"].first
      
      expect(origin["domain_name"]).to eq("api.example.com")
      expect(origin["origin_path"]).to eq("/v1")
      expect(origin["custom_origin_config"]["origin_protocol_policy"]).to eq("https-only")
      expect(origin["custom_origin_config"]["origin_ssl_protocols"]).to eq(["TLSv1.2"])
    end
  end
  
  describe "multi-origin synthesis" do
    it "synthesizes distribution with multiple origins" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:multi_origin, {
          origin: [
            {
              domain_name: "static.example.com",
              origin_id: "static-origin",
              s3_origin_config: {
                origin_access_control_id: "E123456789012"
              }
            },
            {
              domain_name: "api.example.com",
              origin_id: "api-origin",
              custom_origin_config: {
                origin_protocol_policy: "https-only"
              },
              custom_header: [
                { name: "X-Custom-Header", value: "custom-value" }
              ]
            }
          ],
          default_cache_behavior: {
            target_origin_id: "static-origin",
            viewer_protocol_policy: "redirect-to-https"
          },
          ordered_cache_behavior: [
            {
              path_pattern: "/api/*",
              target_origin_id: "api-origin",
              viewer_protocol_policy: "https-only",
              allowed_methods: ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
            }
          ],
          comment: "Multi-origin distribution",
          enabled: true
        })
        
        synthesis
      end
      
      distribution = result["resource"]["aws_cloudfront_distribution"]["multi_origin"]
      
      expect(distribution["origin"]).to have(2).items
      expect(distribution["ordered_cache_behavior"]).to have(1).item
      
      static_origin = distribution["origin"].find { |o| o["origin_id"] == "static-origin" }
      api_origin = distribution["origin"].find { |o| o["origin_id"] == "api-origin" }
      
      expect(static_origin["s3_origin_config"]).to be_present
      expect(api_origin["custom_origin_config"]).to be_present
      expect(api_origin["custom_header"]).to have(1).item
      
      ordered_behavior = distribution["ordered_cache_behavior"].first
      expect(ordered_behavior["path_pattern"]).to eq("/api/*")
      expect(ordered_behavior["target_origin_id"]).to eq("api-origin")
    end
  end
  
  describe "edge computing synthesis" do
    it "synthesizes Lambda@Edge associations" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:lambda_edge, {
          origin: [{
            domain_name: "example.com",
            origin_id: "web-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only"
            }
          }],
          default_cache_behavior: {
            target_origin_id: "web-origin",
            viewer_protocol_policy: "https-only",
            lambda_function_association: [
              {
                event_type: "viewer-request",
                lambda_arn: "arn:aws:lambda:us-east-1:123456789012:function:auth:1",
                include_body: false
              },
              {
                event_type: "origin-response",
                lambda_arn: "arn:aws:lambda:us-east-1:123456789012:function:headers:2",
                include_body: true
              }
            ]
          },
          comment: "Lambda@Edge distribution",
          enabled: true
        })
        
        synthesis
      end
      
      behavior = result["resource"]["aws_cloudfront_distribution"]["lambda_edge"]["default_cache_behavior"]
      lambda_assocs = behavior["lambda_function_association"]
      
      expect(lambda_assocs).to have(2).items
      
      viewer_request = lambda_assocs.find { |a| a["event_type"] == "viewer-request" }
      origin_response = lambda_assocs.find { |a| a["event_type"] == "origin-response" }
      
      expect(viewer_request["lambda_arn"]).to include("function:auth:1")
      expect(viewer_request["include_body"]).to eq(false)
      expect(origin_response["include_body"]).to eq(true)
    end
    
    it "synthesizes CloudFront Functions associations" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:cloudfront_functions, {
          origin: [{
            domain_name: "example.com",
            origin_id: "web-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only"
            }
          }],
          default_cache_behavior: {
            target_origin_id: "web-origin",
            viewer_protocol_policy: "https-only",
            function_association: [{
              event_type: "viewer-request",
              function_arn: "arn:aws:cloudfront::123456789012:function/security-headers"
            }]
          },
          comment: "CloudFront Functions distribution",
          enabled: true
        })
        
        synthesis
      end
      
      behavior = result["resource"]["aws_cloudfront_distribution"]["cloudfront_functions"]["default_cache_behavior"]
      func_assocs = behavior["function_association"]
      
      expect(func_assocs).to have(1).item
      expect(func_assocs.first["event_type"]).to eq("viewer-request")
      expect(func_assocs.first["function_arn"]).to include("cloudfront")
    end
  end
  
  describe "SSL and domain synthesis" do
    it "synthesizes ACM SSL certificate configuration" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:ssl_acm, {
          origin: [{
            domain_name: "example.com",
            origin_id: "web-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only"
            }
          }],
          default_cache_behavior: {
            target_origin_id: "web-origin",
            viewer_protocol_policy: "https-only"
          },
          aliases: ["www.example.com", "example.com"],
          viewer_certificate: {
            acm_certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
            ssl_support_method: "sni-only",
            minimum_protocol_version: "TLSv1.2_2021"
          },
          comment: "SSL distribution with ACM certificate",
          enabled: true
        })
        
        synthesis
      end
      
      distribution = result["resource"]["aws_cloudfront_distribution"]["ssl_acm"]
      
      expect(distribution["aliases"]).to eq(["www.example.com", "example.com"])
      
      viewer_cert = distribution["viewer_certificate"]
      expect(viewer_cert["acm_certificate_arn"]).to include("acm:us-east-1")
      expect(viewer_cert["ssl_support_method"]).to eq("sni-only")
      expect(viewer_cert["minimum_protocol_version"]).to eq("TLSv1.2_2021")
    end
    
    it "synthesizes CloudFront default certificate" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:default_ssl, {
          origin: [{
            domain_name: "example.com",
            origin_id: "web-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only"
            }
          }],
          default_cache_behavior: {
            target_origin_id: "web-origin"
          },
          viewer_certificate: {
            cloudfront_default_certificate: true
          },
          comment: "Distribution with default SSL",
          enabled: true
        })
        
        synthesis
      end
      
      viewer_cert = result["resource"]["aws_cloudfront_distribution"]["default_ssl"]["viewer_certificate"]
      expect(viewer_cert["cloudfront_default_certificate"]).to eq(true)
    end
  end
  
  describe "advanced features synthesis" do
    it "synthesizes geographic restrictions" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:geo_restricted, {
          origin: [{
            domain_name: "example.com",
            origin_id: "web-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only"
            }
          }],
          default_cache_behavior: {
            target_origin_id: "web-origin"
          },
          restrictions: {
            geo_restriction: {
              restriction_type: "whitelist",
              locations: ["US", "CA", "GB"]
            }
          },
          comment: "Geo-restricted distribution",
          enabled: true
        })
        
        synthesis
      end
      
      restrictions = result["resource"]["aws_cloudfront_distribution"]["geo_restricted"]["restrictions"]
      geo_restriction = restrictions["geo_restriction"]
      
      expect(geo_restriction["restriction_type"]).to eq("whitelist")
      expect(geo_restriction["locations"]).to eq(["US", "CA", "GB"])
    end
    
    it "synthesizes custom error responses" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:custom_errors, {
          origin: [{
            domain_name: "example.com",
            origin_id: "web-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only"
            }
          }],
          default_cache_behavior: {
            target_origin_id: "web-origin"
          },
          custom_error_response: [
            {
              error_code: 404,
              response_code: 200,
              response_page_path: "/404.html",
              error_caching_min_ttl: 300
            },
            {
              error_code: 500,
              response_page_path: "/500.html"
            }
          ],
          comment: "Distribution with custom error pages",
          enabled: true
        })
        
        synthesis
      end
      
      custom_errors = result["resource"]["aws_cloudfront_distribution"]["custom_errors"]["custom_error_response"]
      
      expect(custom_errors).to have(2).items
      
      error_404 = custom_errors.find { |e| e["error_code"] == 404 }
      error_500 = custom_errors.find { |e| e["error_code"] == 500 }
      
      expect(error_404["response_code"]).to eq(200)
      expect(error_404["response_page_path"]).to eq("/404.html")
      expect(error_404["error_caching_min_ttl"]).to eq(300)
      expect(error_500["response_page_path"]).to eq("/500.html")
    end
    
    it "synthesizes origin shield configuration" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:origin_shield, {
          origin: [{
            domain_name: "api.example.com",
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
          comment: "Distribution with Origin Shield",
          enabled: true
        })
        
        synthesis
      end
      
      origin = result["resource"]["aws_cloudfront_distribution"]["origin_shield"]["origin"].first
      shield_config = origin["origin_shield"]
      
      expect(shield_config["enabled"]).to eq(true)
      expect(shield_config["origin_shield_region"]).to eq("us-east-1")
    end
    
    it "synthesizes Web ACL association" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:waf_protected, {
          origin: [{
            domain_name: "example.com",
            origin_id: "web-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only"
            }
          }],
          default_cache_behavior: {
            target_origin_id: "web-origin"
          },
          web_acl_id: "arn:aws:wafv2:us-east-1:123456789012:global/webacl/ExampleWebACL/473e64fd-f30b-4765-81a0-62ad96dd167a",
          comment: "WAF-protected distribution",
          enabled: true
        })
        
        synthesis
      end
      
      distribution = result["resource"]["aws_cloudfront_distribution"]["waf_protected"]
      expect(distribution["web_acl_id"]).to include("wafv2")
    end
  end
  
  describe "performance and optimization synthesis" do
    it "synthesizes compression and caching settings" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:optimized, {
          origin: [{
            domain_name: "example.com",
            origin_id: "web-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only"
            }
          }],
          default_cache_behavior: {
            target_origin_id: "web-origin",
            viewer_protocol_policy: "https-only",
            compress: true,
            allowed_methods: ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"],
            cached_methods: ["GET", "HEAD", "OPTIONS"],
            cache_policy_id: "658327ea-f89d-4fab-a63d-7e88639e58f6",
            origin_request_policy_id: "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
          },
          http_version: "http2",
          is_ipv6_enabled: true,
          price_class: "PriceClass_All",
          comment: "Optimized distribution",
          enabled: true
        })
        
        synthesis
      end
      
      distribution = result["resource"]["aws_cloudfront_distribution"]["optimized"]
      behavior = distribution["default_cache_behavior"]
      
      expect(behavior["compress"]).to eq(true)
      expect(behavior["allowed_methods"]).to include("DELETE", "POST", "PUT")
      expect(behavior["cached_methods"]).to include("OPTIONS")
      expect(behavior["cache_policy_id"]).to be_present
      expect(behavior["origin_request_policy_id"]).to be_present
      
      expect(distribution["http_version"]).to eq("http2")
      expect(distribution["is_ipv6_enabled"]).to eq(true)
      expect(distribution["price_class"]).to eq("PriceClass_All")
    end
    
    it "synthesizes different price classes" do
      ["PriceClass_100", "PriceClass_200", "PriceClass_All"].each do |price_class|
        result = synthesizer.instance_eval do
          aws_cloudfront_distribution(:"price_#{price_class.downcase}", {
            origin: [{
              domain_name: "example.com",
              origin_id: "web-origin",
              custom_origin_config: {
                origin_protocol_policy: "https-only"
              }
            }],
            default_cache_behavior: {
              target_origin_id: "web-origin"
            },
            price_class: price_class,
            comment: "Distribution with #{price_class}",
            enabled: true
          })
          
          synthesis
        end
        
        distribution = result["resource"]["aws_cloudfront_distribution"]["price_#{price_class.downcase}"]
        expect(distribution["price_class"]).to eq(price_class)
      end
    end
  end
  
  describe "real-world patterns synthesis" do
    it "synthesizes SPA website distribution" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:spa_website, {
          origin: [{
            domain_name: "my-spa.s3.amazonaws.com",
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
          aliases: ["app.example.com"],
          viewer_certificate: {
            acm_certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
            ssl_support_method: "sni-only"
          },
          comment: "SPA website distribution",
          enabled: true
        })
        
        synthesis
      end
      
      distribution = result["resource"]["aws_cloudfront_distribution"]["spa_website"]
      
      expect(distribution["default_root_object"]).to eq("index.html")
      expect(distribution["custom_error_response"]).to have(2).items
      expect(distribution["aliases"]).to eq(["app.example.com"])
      
      # Check that both 404 and 403 redirect to index.html for SPA routing
      distribution["custom_error_response"].each do |error|
        expect(error["response_code"]).to eq(200)
        expect(error["response_page_path"]).to eq("/index.html")
      end
    end
    
    it "synthesizes API distribution with authentication" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:api_distribution, {
          origin: [{
            domain_name: "api.example.com",
            origin_id: "api-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only",
              origin_ssl_protocols: ["TLSv1.2"]
            },
            custom_header: [
              { name: "X-API-Key", value: "secret-api-key" }
            ]
          }],
          default_cache_behavior: {
            target_origin_id: "api-origin",
            viewer_protocol_policy: "https-only",
            allowed_methods: ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"],
            cached_methods: ["GET", "HEAD"],
            lambda_function_association: [{
              event_type: "viewer-request",
              lambda_arn: "arn:aws:lambda:us-east-1:123456789012:function:api-auth:1"
            }]
          },
          aliases: ["api.example.com"],
          viewer_certificate: {
            acm_certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
          },
          comment: "API distribution with authentication",
          enabled: true
        })
        
        synthesis
      end
      
      distribution = result["resource"]["aws_cloudfront_distribution"]["api_distribution"]
      origin = distribution["origin"].first
      behavior = distribution["default_cache_behavior"]
      
      expect(origin["custom_header"]).to have(1).item
      expect(origin["custom_header"].first["name"]).to eq("X-API-Key")
      expect(behavior["allowed_methods"]).to include("POST", "PUT", "DELETE")
      expect(behavior["lambda_function_association"]).to have(1).item
    end
    
    it "synthesizes global content distribution" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:global_content, {
          origin: [
            {
              domain_name: "us-content.s3.amazonaws.com",
              origin_id: "us-content",
              s3_origin_config: {
                origin_access_control_id: "E123456789012"
              }
            },
            {
              domain_name: "eu-content.s3.eu-west-1.amazonaws.com",
              origin_id: "eu-content",
              s3_origin_config: {
                origin_access_control_id: "E123456789013"
              }
            }
          ],
          default_cache_behavior: {
            target_origin_id: "us-content",
            viewer_protocol_policy: "https-only",
            compress: true
          },
          ordered_cache_behavior: [
            {
              path_pattern: "/eu/*",
              target_origin_id: "eu-content",
              viewer_protocol_policy: "https-only",
              compress: true
            }
          ],
          aliases: ["content.example.com"],
          viewer_certificate: {
            acm_certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
          },
          restrictions: {
            geo_restriction: {
              restriction_type: "none"
            }
          },
          comment: "Global content distribution",
          enabled: true
        })
        
        synthesis
      end
      
      distribution = result["resource"]["aws_cloudfront_distribution"]["global_content"]
      
      expect(distribution["origin"]).to have(2).items
      expect(distribution["ordered_cache_behavior"]).to have(1).item
      expect(distribution["ordered_cache_behavior"].first["path_pattern"]).to eq("/eu/*")
    end
  end
  
  describe "tag synthesis" do
    it "synthesizes comprehensive tags" do
      result = synthesizer.instance_eval do
        aws_cloudfront_distribution(:tagged_distribution, {
          origin: [{
            domain_name: "example.com",
            origin_id: "web-origin",
            custom_origin_config: {
              origin_protocol_policy: "https-only"
            }
          }],
          default_cache_behavior: {
            target_origin_id: "web-origin"
          },
          tags: {
            Name: "production-cdn",
            Environment: "production",
            Application: "web-app",
            Team: "platform",
            CostCenter: "engineering",
            Project: "global-expansion",
            Security: "public-facing",
            Backup: "daily"
          },
          comment: "Production CDN with comprehensive tags",
          enabled: true
        })
        
        synthesis
      end
      
      tags = result["resource"]["aws_cloudfront_distribution"]["tagged_distribution"]["tags"]
      expect(tags).to include(
        Name: "production-cdn",
        Environment: "production",
        Application: "web-app",
        Team: "platform"
      )
    end
  end
end