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

# Load aws_lb_listener resource and types for testing
require 'pangea/resources/aws_lb_listener/resource'
require 'pangea/resources/aws_lb_listener/types'

RSpec.describe "aws_lb_listener resource function" do
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
  
  # Test load balancer and target group ARNs
  let(:alb_arn) { "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188" }
  let(:nlb_arn) { "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/my-nlb/50dc6c495c0c9188" }
  let(:target_group_arn) { "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/73e2d6bc24d8a067" }
  let(:certificate_arn) { "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012" }
  
  describe "LoadBalancerListenerAttributes validation" do
    it "accepts minimal HTTP listener configuration" do
      listener = Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
        load_balancer_arn: alb_arn,
        port: 80,
        protocol: "HTTP",
        default_action: [{
          type: "forward",
          target_group_arn: target_group_arn
        }],
        tags: {}
      })
      
      expect(listener.load_balancer_arn).to eq(alb_arn)
      expect(listener.port).to eq(80)
      expect(listener.protocol).to eq("HTTP")
      expect(listener.default_action).to have(1).item
    end
    
    it "accepts HTTPS listener with SSL configuration" do
      listener = Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
        load_balancer_arn: alb_arn,
        port: 443,
        protocol: "HTTPS",
        ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
        certificate_arn: certificate_arn,
        alpn_policy: "HTTP2Preferred",
        default_action: [{
          type: "forward",
          target_group_arn: target_group_arn
        }],
        tags: {
          Name: "https-listener",
          Environment: "production"
        }
      })
      
      expect(listener.protocol).to eq("HTTPS")
      expect(listener.ssl_policy).to eq("ELBSecurityPolicy-TLS-1-2-2017-01")
      expect(listener.certificate_arn).to eq(certificate_arn)
      expect(listener.alpn_policy).to eq("HTTP2Preferred")
    end
    
    it "validates HTTPS requires SSL policy" do
      expect {
        Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
          load_balancer_arn: alb_arn,
          port: 443,
          protocol: "HTTPS",
          # Missing ssl_policy
          certificate_arn: certificate_arn,
          default_action: [{
            type: "forward",
            target_group_arn: target_group_arn
          }],
          tags: {}
        })
      }.to raise_error(Dry::Struct::Error, /ssl_policy is required for HTTPS listeners/)
    end
    
    it "validates HTTPS requires certificate" do
      expect {
        Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
          load_balancer_arn: alb_arn,
          port: 443,
          protocol: "HTTPS",
          ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
          # Missing certificate_arn
          default_action: [{
            type: "forward",
            target_group_arn: target_group_arn
          }],
          tags: {}
        })
      }.to raise_error(Dry::Struct::Error, /certificate_arn is required for HTTPS listeners/)
    end
    
    it "validates SSL config not allowed for HTTP" do
      expect {
        Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
          load_balancer_arn: alb_arn,
          port: 80,
          protocol: "HTTP",
          ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",  # Not allowed for HTTP
          default_action: [{
            type: "forward",
            target_group_arn: target_group_arn
          }],
          tags: {}
        })
      }.to raise_error(Dry::Struct::Error, /ssl_policy and certificate_arn can only be specified for HTTPS\/TLS listeners/)
    end
    
    it "validates port range" do
      expect {
        Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
          load_balancer_arn: alb_arn,
          port: 70000,  # Invalid port
          protocol: "HTTP",
          default_action: [{
            type: "forward",
            target_group_arn: target_group_arn
          }],
          tags: {}
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates at least one default action" do
      expect {
        Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
          load_balancer_arn: alb_arn,
          port: 80,
          protocol: "HTTP",
          default_action: [],  # Empty actions
          tags: {}
        })
      }.to raise_error(Dry::Types::ConstraintError)
    end
    
    it "validates forward action requires target or forward config" do
      expect {
        Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
          load_balancer_arn: alb_arn,
          port: 80,
          protocol: "HTTP",
          default_action: [{
            type: "forward"
            # Missing both target_group_arn and forward
          }],
          tags: {}
        })
      }.to raise_error(Dry::Struct::Error, /forward action requires either target_group_arn or forward configuration/)
    end
    
    it "accepts weighted forward action" do
      listener = Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
        load_balancer_arn: alb_arn,
        port: 80,
        protocol: "HTTP",
        default_action: [{
          type: "forward",
          forward: {
            target_groups: [
              { arn: target_group_arn, weight: 80 },
              { arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/other/123456789012", weight: 20 }
            ],
            stickiness: {
              enabled: true,
              duration: 3600
            }
          }
        }],
        tags: {}
      })
      
      expect(listener.default_action.first[:forward][:target_groups]).to have(2).items
    end
    
    it "accepts redirect action" do
      listener = Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
        load_balancer_arn: alb_arn,
        port: 80,
        protocol: "HTTP",
        default_action: [{
          type: "redirect",
          redirect: {
            protocol: "HTTPS",
            port: "443",
            status_code: "HTTP_301"
          }
        }],
        tags: {}
      })
      
      expect(listener.default_action.first[:type]).to eq("redirect")
    end
    
    it "accepts fixed response action" do
      listener = Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
        load_balancer_arn: alb_arn,
        port: 80,
        protocol: "HTTP",
        default_action: [{
          type: "fixed-response",
          fixed_response: {
            content_type: "text/plain",
            message_body: "Service Unavailable",
            status_code: "503"
          }
        }],
        tags: {}
      })
      
      expect(listener.default_action.first[:type]).to eq("fixed-response")
    end
    
    it "accepts authenticate-cognito action" do
      listener = Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
        load_balancer_arn: alb_arn,
        port: 443,
        protocol: "HTTPS",
        ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
        certificate_arn: certificate_arn,
        default_action: [{
          type: "authenticate-cognito",
          order: 1,
          authenticate_cognito: {
            user_pool_arn: "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_Example",
            user_pool_client_id: "example-client-id",
            user_pool_domain: "auth.example.com"
          }
        }, {
          type: "forward",
          order: 2,
          target_group_arn: target_group_arn
        }],
        tags: {}
      })
      
      expect(listener.default_action).to have(2).items
      expect(listener.default_action.first[:type]).to eq("authenticate-cognito")
    end
    
    it "accepts authenticate-oidc action" do
      listener = Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new({
        load_balancer_arn: alb_arn,
        port: 443,
        protocol: "HTTPS",
        ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
        certificate_arn: certificate_arn,
        default_action: [{
          type: "authenticate-oidc",
          order: 1,
          authenticate_oidc: {
            authorization_endpoint: "https://auth.example.com/oauth2/authorize",
            client_id: "example-client-id",
            client_secret: "example-client-secret",
            issuer: "https://auth.example.com",
            token_endpoint: "https://auth.example.com/oauth2/token",
            user_info_endpoint: "https://auth.example.com/oauth2/userinfo"
          }
        }, {
          type: "forward",
          order: 2,
          target_group_arn: target_group_arn
        }],
        tags: {}
      })
      
      expect(listener.default_action).to have(2).items
      expect(listener.default_action.first[:type]).to eq("authenticate-oidc")
    end
    
    it "accepts multiple protocols" do
      protocols = ["HTTP", "HTTPS", "TCP", "TLS", "UDP", "TCP_UDP", "GENEVE"]
      
      protocols.each do |protocol|
        attrs = {
          load_balancer_arn: protocol == "GENEVE" ? "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/gwy/my-gwlb/123" : nlb_arn,
          port: protocol == "HTTPS" ? 443 : 80,
          protocol: protocol,
          default_action: [{
            type: "forward",
            target_group_arn: target_group_arn
          }],
          tags: {}
        }
        
        # Add SSL config for secure protocols
        if ["HTTPS", "TLS"].include?(protocol)
          attrs[:ssl_policy] = "ELBSecurityPolicy-TLS-1-2-2017-01"
          attrs[:certificate_arn] = certificate_arn
        end
        
        listener = Pangea::Resources::AWS::Types::LoadBalancerListenerAttributes.new(attrs)
        expect(listener.protocol).to eq(protocol)
      end
    end
  end
  
  describe "aws_lb_listener function" do
    it "creates basic HTTP listener" do
      result = test_instance.aws_lb_listener(:http_listener, {
        load_balancer_arn: alb_arn,
        port: 80,
        protocol: "HTTP",
        default_action: [{
          type: "forward",
          target_group_arn: target_group_arn
        }],
        tags: {}
      })
      
      expect(result).to be_a(Pangea::Resources::ResourceReference)
      expect(result.type).to eq('aws_lb_listener')
      expect(result.name).to eq(:http_listener)
      expect(result.port).to eq("${aws_lb_listener.http_listener.port}")
    end
    
    it "creates HTTPS listener with SSL" do
      result = test_instance.aws_lb_listener(:https_listener, {
        load_balancer_arn: alb_arn,
        port: 443,
        protocol: "HTTPS",
        ssl_policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10",
        certificate_arn: certificate_arn,
        alpn_policy: "HTTP2Preferred",
        default_action: [{
          type: "forward",
          target_group_arn: target_group_arn
        }],
        tags: {
          Name: "secure-listener",
          Protocol: "HTTPS"
        }
      })
      
      expect(result.resource_attributes[:protocol]).to eq("HTTPS")
      expect(result.resource_attributes[:ssl_policy]).to eq("ELBSecurityPolicy-FS-1-2-Res-2020-10")
      expect(result.resource_attributes[:alpn_policy]).to eq("HTTP2Preferred")
      expect(result.is_secure?).to eq(true)
      expect(result.requires_ssl?).to eq(true)
    end
    
    it "creates listener with redirect action" do
      result = test_instance.aws_lb_listener(:redirect_listener, {
        load_balancer_arn: alb_arn,
        port: 80,
        protocol: "HTTP",
        default_action: [{
          type: "redirect",
          redirect: {
            protocol: "HTTPS",
            port: "443",
            host: "#{host}",
            path: "/#{path}",
            query: "#{query}",
            status_code: "HTTP_301"
          }
        }],
        tags: {}
      })
      
      expect(result.resource_attributes[:default_action].first[:type]).to eq("redirect")
      expect(result.is_http_based?).to eq(true)
      expect(result.supports_rules?).to eq(true)
    end
    
    it "creates listener with weighted target groups" do
      result = test_instance.aws_lb_listener(:weighted_listener, {
        load_balancer_arn: alb_arn,
        port: 80,
        protocol: "HTTP",
        default_action: [{
          type: "forward",
          forward: {
            target_groups: [
              { arn: target_group_arn, weight: 70 },
              { arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/blue/123", weight: 30 }
            ],
            stickiness: {
              enabled: true,
              duration: 3600
            }
          }
        }],
        tags: {}
      })
      
      expect(result.has_weighted_routing?).to eq(true)
      expect(result.action_count).to eq(1)
    end
    
    it "creates listener with authentication" do
      result = test_instance.aws_lb_listener(:auth_listener, {
        load_balancer_arn: alb_arn,
        port: 443,
        protocol: "HTTPS",
        ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
        certificate_arn: certificate_arn,
        default_action: [{
          type: "authenticate-cognito",
          order: 1,
          authenticate_cognito: {
            user_pool_arn: "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_Example",
            user_pool_client_id: "example-client-id",
            user_pool_domain: "auth.example.com",
            session_cookie_name: "AWSELBAuthSessionCookie",
            session_timeout: 86400,
            on_unauthenticated_request: "authenticate"
          }
        }, {
          type: "forward",
          order: 2,
          target_group_arn: target_group_arn
        }],
        tags: {}
      })
      
      expect(result.has_authentication?).to eq(true)
      expect(result.action_count).to eq(2)
    end
    
    it "creates TCP listener for NLB" do
      result = test_instance.aws_lb_listener(:tcp_listener, {
        load_balancer_arn: nlb_arn,
        port: 6379,
        protocol: "TCP",
        default_action: [{
          type: "forward",
          target_group_arn: target_group_arn
        }],
        tags: {
          Name: "redis-listener",
          Protocol: "TCP"
        }
      })
      
      expect(result.resource_attributes[:protocol]).to eq("TCP")
      expect(result.is_tcp_based?).to eq(true)
      expect(result.supports_rules?).to eq(false)
    end
    
    it "creates TLS listener for NLB" do
      result = test_instance.aws_lb_listener(:tls_listener, {
        load_balancer_arn: nlb_arn,
        port: 6380,
        protocol: "TLS",
        ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
        certificate_arn: certificate_arn,
        default_action: [{
          type: "forward",
          target_group_arn: target_group_arn
        }],
        tags: {}
      })
      
      expect(result.resource_attributes[:protocol]).to eq("TLS")
      expect(result.is_secure?).to eq(true)
      expect(result.is_tcp_based?).to eq(true)
    end
    
    it "creates listener with fixed response" do
      result = test_instance.aws_lb_listener(:maintenance_listener, {
        load_balancer_arn: alb_arn,
        port: 80,
        protocol: "HTTP",
        default_action: [{
          type: "fixed-response",
          fixed_response: {
            content_type: "text/html",
            message_body: "<html><body><h1>Under Maintenance</h1></body></html>",
            status_code: "503"
          }
        }],
        tags: {
          Purpose: "maintenance"
        }
      })
      
      expect(result.resource_attributes[:default_action].first[:type]).to eq("fixed-response")
    end
    
    it "creates listener with OIDC authentication" do
      result = test_instance.aws_lb_listener(:oidc_listener, {
        load_balancer_arn: alb_arn,
        port: 443,
        protocol: "HTTPS",
        ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
        certificate_arn: certificate_arn,
        default_action: [{
          type: "authenticate-oidc",
          order: 1,
          authenticate_oidc: {
            authorization_endpoint: "https://auth.example.com/oauth2/authorize",
            client_id: "my-client-id",
            client_secret: "my-client-secret",
            issuer: "https://auth.example.com",
            token_endpoint: "https://auth.example.com/oauth2/token",
            user_info_endpoint: "https://auth.example.com/oauth2/userinfo",
            authentication_request_extra_params: {
              prompt: "login",
              display: "page"
            }
          }
        }, {
          type: "forward",
          order: 2,
          target_group_arn: target_group_arn
        }],
        tags: {}
      })
      
      expect(result.has_authentication?).to eq(true)
    end
    
    it "provides correct outputs" do
      result = test_instance.aws_lb_listener(:test, {
        load_balancer_arn: alb_arn,
        port: 80,
        protocol: "HTTP",
        default_action: [{
          type: "forward",
          target_group_arn: target_group_arn
        }],
        tags: {}
      })
      
      expect(result.id).to eq("${aws_lb_listener.test.id}")
      expect(result.arn).to eq("${aws_lb_listener.test.arn}")
      expect(result.load_balancer_arn).to eq("${aws_lb_listener.test.load_balancer_arn}")
      expect(result.port).to eq("${aws_lb_listener.test.port}")
      expect(result.protocol).to eq("${aws_lb_listener.test.protocol}")
      expect(result.ssl_policy).to eq("${aws_lb_listener.test.ssl_policy}")
      expect(result.certificate_arn).to eq("${aws_lb_listener.test.certificate_arn}")
    end
    
    it "provides computed properties" do
      result = test_instance.aws_lb_listener(:test, {
        load_balancer_arn: alb_arn,
        port: 443,
        protocol: "HTTPS",
        ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
        certificate_arn: certificate_arn,
        default_action: [{
          type: "forward",
          forward: {
            target_groups: [
              { arn: target_group_arn, weight: 100 }
            ]
          }
        }],
        tags: {}
      })
      
      expect(result.is_secure?).to eq(true)
      expect(result.requires_ssl?).to eq(true)
      expect(result.is_http_based?).to eq(true)
      expect(result.is_tcp_based?).to eq(false)
      expect(result.supports_rules?).to eq(true)
      expect(result.action_count).to eq(1)
      expect(result.has_authentication?).to eq(false)
      expect(result.has_weighted_routing?).to eq(true)
    end
  end
  
  describe "listener patterns" do
    it "creates HTTP to HTTPS redirect listener" do
      result = test_instance.aws_lb_listener(:http_redirect, {
        load_balancer_arn: alb_arn,
        port: 80,
        protocol: "HTTP",
        default_action: [{
          type: "redirect",
          redirect: {
            protocol: "HTTPS",
            port: "443",
            status_code: "HTTP_301"
          }
        }],
        tags: {
          Purpose: "https-redirect",
          Pattern: "security"
        }
      })
      
      redirect = result.resource_attributes[:default_action].first[:redirect]
      expect(redirect[:protocol]).to eq("HTTPS")
      expect(redirect[:status_code]).to eq("HTTP_301")
    end
    
    it "creates blue-green deployment listener" do
      result = test_instance.aws_lb_listener(:blue_green, {
        load_balancer_arn: alb_arn,
        port: 80,
        protocol: "HTTP",
        default_action: [{
          type: "forward",
          forward: {
            target_groups: [
              { arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/blue/123", weight: 100 },
              { arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/green/456", weight: 0 }
            ]
          }
        }],
        tags: {
          Pattern: "blue-green",
          ActiveEnvironment: "blue"
        }
      })
      
      expect(result.has_weighted_routing?).to eq(true)
    end
    
    it "creates API gateway listener with auth" do
      result = test_instance.aws_lb_listener(:api_gateway, {
        load_balancer_arn: alb_arn,
        port: 443,
        protocol: "HTTPS",
        ssl_policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10",
        certificate_arn: certificate_arn,
        alpn_policy: "HTTP2Preferred",
        default_action: [{
          type: "authenticate-oidc",
          order: 1,
          authenticate_oidc: {
            authorization_endpoint: "https://auth.api.example.com/oauth2/authorize",
            client_id: "api-client",
            client_secret: "api-secret",
            issuer: "https://auth.api.example.com",
            token_endpoint: "https://auth.api.example.com/oauth2/token",
            user_info_endpoint: "https://auth.api.example.com/oauth2/userinfo",
            scope: "openid profile email"
          }
        }, {
          type: "forward",
          order: 2,
          target_group_arn: target_group_arn
        }],
        tags: {
          Purpose: "api-gateway",
          Security: "oauth2"
        }
      })
      
      expect(result.has_authentication?).to eq(true)
      expect(result.is_secure?).to eq(true)
    end
  end
end