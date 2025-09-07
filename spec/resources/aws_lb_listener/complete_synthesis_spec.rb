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

# Require the AWS lb listener module
require 'pangea/resources/aws_lb_listener/resource'
require 'pangea/resources/aws_lb_listener/types'

RSpec.describe "aws_lb_listener synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }

  # Extend the synthesizer with our AWS module for resource access
  before do
    synthesizer.extend(Pangea::Resources::AWS)
  end

  describe "basic listener synthesis" do
    it "synthesizes minimal HTTP listener" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:http_listener, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
          port: 80,
          protocol: "HTTP",
          default_action: [{
            type: "forward",
            target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
          }],
          tags: {}
        })
        
        synthesis
      end
      
      expect(result[:resource][:aws_lb_listener][:http_listener]).to include(
        load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
        port: 80,
        protocol: "HTTP"
      )
      
      # Verify default_action structure
      actions = result[:resource][:aws_lb_listener][:http_listener][:default_action]
      expect(actions).to be_an(Array)
      expect(actions.first).to include(
        type: "forward",
        target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
      )
    end
    
    it "synthesizes HTTPS listener with SSL" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:https_listener, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
          port: 443,
          protocol: "HTTPS",
          ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
          certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
          alpn_policy: "HTTP2Preferred",
          default_action: [{
            type: "forward",
            target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
          }],
          tags: {
            Name: "https-listener",
            Protocol: "HTTPS"
          }
        })
        
        synthesis
      end
      
      expect(result[:resource][:aws_lb_listener][:https_listener]).to include(
        protocol: "HTTPS",
        ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
        certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
        alpn_policy: "HTTP2Preferred"
      )
      
      expect(result[:resource][:aws_lb_listener][:https_listener][:tags]).to include(
        Name: "https-listener",
        Protocol: "HTTPS"
      )
    end
  end
  
  describe "action configurations synthesis" do
    it "synthesizes redirect action" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:redirect_listener, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
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
        
        synthesis
      end
      
      actions = result[:resource][:aws_lb_listener][:redirect_listener][:default_action]
      expect(actions.first[:type]).to eq("redirect")
      expect(actions.first[:redirect]).to include(
        protocol: "HTTPS",
        port: "443",
        status_code: "HTTP_301"
      )
    end
    
    it "synthesizes weighted forward action" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:weighted_listener, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
          port: 80,
          protocol: "HTTP",
          default_action: [{
            type: "forward",
            forward: {
              target_groups: [
                { arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/blue/123", weight: 80 },
                { arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/green/456", weight: 20 }
              ],
              stickiness: {
                enabled: true,
                duration: 3600
              }
            }
          }],
          tags: {}
        })
        
        synthesis
      end
      
      forward_config = result[:resource][:aws_lb_listener][:weighted_listener][:default_action].first[:forward]
      expect(forward_config[:target_groups]).to have(2).items
      expect(forward_config[:target_groups].first).to include(
        arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/blue/123",
        weight: 80
      )
      expect(forward_config[:stickiness]).to include(
        enabled: true,
        duration: 3600
      )
    end
    
    it "synthesizes fixed response action" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:fixed_response_listener, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
          port: 80,
          protocol: "HTTP",
          default_action: [{
            type: "fixed-response",
            fixed_response: {
              content_type: "text/html",
              message_body: "<html><body><h1>Service Unavailable</h1></body></html>",
              status_code: "503"
            }
          }],
          tags: {}
        })
        
        synthesis
      end
      
      fixed_response = result[:resource][:aws_lb_listener][:fixed_response_listener][:default_action].first[:fixed_response]
      expect(fixed_response).to include(
        content_type: "text/html",
        message_body: "<html><body><h1>Service Unavailable</h1></body></html>",
        status_code: "503"
      )
    end
    
    it "synthesizes authenticate-cognito action" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:cognito_auth_listener, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
          port: 443,
          protocol: "HTTPS",
          ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
          certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
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
            target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
          }],
          tags: {}
        })
        
        synthesis
      end
      
      actions = result[:resource][:aws_lb_listener][:cognito_auth_listener][:default_action]
      expect(actions).to have(2).items
      
      auth_action = actions.first
      expect(auth_action[:type]).to eq("authenticate-cognito")
      expect(auth_action[:order]).to eq(1)
      expect(auth_action[:authenticate_cognito]).to include(
        user_pool_arn: "arn:aws:cognito-idp:us-east-1:123456789012:userpool/us-east-1_Example",
        user_pool_client_id: "example-client-id",
        user_pool_domain: "auth.example.com"
      )
    end
    
    it "synthesizes authenticate-oidc action" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:oidc_auth_listener, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
          port: 443,
          protocol: "HTTPS",
          ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
          certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
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
              },
              scope: "openid profile email"
            }
          }, {
            type: "forward",
            order: 2,
            target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
          }],
          tags: {}
        })
        
        synthesis
      end
      
      oidc_action = result[:resource][:aws_lb_listener][:oidc_auth_listener][:default_action].first
      expect(oidc_action[:type]).to eq("authenticate-oidc")
      expect(oidc_action[:authenticate_oidc]).to include(
        authorization_endpoint: "https://auth.example.com/oauth2/authorize",
        client_id: "my-client-id",
        issuer: "https://auth.example.com"
      )
      
      # Check extra params synthesis
      expect(oidc_action[:authenticate_oidc][:authentication_request_extra_params]).to include(
        prompt: "login",
        display: "page"
      )
    end
  end
  
  describe "protocol-specific synthesis" do
    it "synthesizes TCP listener for NLB" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:tcp_listener, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/my-nlb/50dc6c495c0c9188",
          port: 6379,
          protocol: "TCP",
          default_action: [{
            type: "forward",
            target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
          }],
          tags: {
            Name: "redis-listener",
            Protocol: "TCP"
          }
        })
        
        synthesis
      end
      
      expect(result[:resource][:aws_lb_listener][:tcp_listener]).to include(
        load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/my-nlb/50dc6c495c0c9188",
        port: 6379,
        protocol: "TCP"
      )
      
      # TCP listeners should not have SSL configuration
      expect(result[:resource][:aws_lb_listener][:tcp_listener]).not_to have_key(:ssl_policy)
      expect(result[:resource][:aws_lb_listener][:tcp_listener]).not_to have_key(:certificate_arn)
    end
    
    it "synthesizes TLS listener for NLB" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:tls_listener, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/my-nlb/50dc6c495c0c9188",
          port: 6380,
          protocol: "TLS",
          ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
          certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
          default_action: [{
            type: "forward",
            target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
          }],
          tags: {}
        })
        
        synthesis
      end
      
      expect(result[:resource][:aws_lb_listener][:tls_listener]).to include(
        protocol: "TLS",
        ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
        certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
      )
    end
    
    it "synthesizes UDP listener for NLB" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:udp_listener, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/net/my-nlb/50dc6c495c0c9188",
          port: 514,
          protocol: "UDP",
          default_action: [{
            type: "forward",
            target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
          }],
          tags: {
            Name: "syslog-listener",
            Protocol: "UDP"
          }
        })
        
        synthesis
      end
      
      expect(result[:resource][:aws_lb_listener][:udp_listener]).to include(
        protocol: "UDP",
        port: 514
      )
    end
  end
  
  describe "complex patterns synthesis" do
    it "synthesizes blue-green deployment listener" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:blue_green_deploy, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
          port: 80,
          protocol: "HTTP",
          default_action: [{
            type: "forward",
            forward: {
              target_groups: [
                { 
                  arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/blue-env/123",
                  weight: 100
                },
                { 
                  arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/green-env/456",
                  weight: 0
                }
              ]
            }
          }],
          tags: {
            Pattern: "blue-green",
            ActiveEnvironment: "blue"
          }
        })
        
        synthesis
      end
      
      forward_config = result[:resource][:aws_lb_listener][:blue_green_deploy][:default_action].first[:forward]
      expect(forward_config[:target_groups]).to have(2).items
      
      # Blue environment at 100% traffic
      expect(forward_config[:target_groups].first[:weight]).to eq(100)
      # Green environment at 0% traffic
      expect(forward_config[:target_groups].last[:weight]).to eq(0)
    end
    
    it "synthesizes HTTP to HTTPS redirect pattern" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:http_to_https_redirect, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
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
          tags: {
            Purpose: "https-redirect",
            Pattern: "security"
          }
        })
        
        synthesis
      end
      
      redirect = result[:resource][:aws_lb_listener][:http_to_https_redirect][:default_action].first[:redirect]
      expect(redirect).to include(
        protocol: "HTTPS",
        port: "443",
        status_code: "HTTP_301"
      )
    end
    
    it "synthesizes maintenance mode listener" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:maintenance_mode, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
          port: 80,
          protocol: "HTTP",
          default_action: [{
            type: "fixed-response",
            fixed_response: {
              content_type: "text/html",
              message_body: "<!DOCTYPE html><html><head><title>Maintenance</title></head><body><h1>Site Under Maintenance</h1><p>We'll be back soon!</p></body></html>",
              status_code: "503"
            }
          }],
          tags: {
            Mode: "maintenance",
            Temporary: "true"
          }
        })
        
        synthesis
      end
      
      fixed_response = result[:resource][:aws_lb_listener][:maintenance_mode][:default_action].first[:fixed_response]
      expect(fixed_response[:status_code]).to eq("503")
      expect(fixed_response[:content_type]).to eq("text/html")
    end
    
    it "synthesizes API gateway pattern with authentication" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:api_gateway, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
          port: 443,
          protocol: "HTTPS",
          ssl_policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10",
          certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
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
              scope: "openid profile email",
              on_unauthenticated_request: "deny"
            }
          }, {
            type: "forward",
            order: 2,
            target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/api-backends/73e2d6bc24d8a067"
          }],
          tags: {
            Purpose: "api-gateway",
            Security: "oauth2",
            Protocol: "HTTP2"
          }
        })
        
        synthesis
      end
      
      listener = result[:resource][:aws_lb_listener][:api_gateway]
      expect(listener[:alpn_policy]).to eq("HTTP2Preferred")
      expect(listener[:ssl_policy]).to eq("ELBSecurityPolicy-FS-1-2-Res-2020-10")
      
      actions = listener[:default_action]
      expect(actions.first[:authenticate_oidc][:on_unauthenticated_request]).to eq("deny")
    end
  end
  
  describe "tag synthesis" do
    it "synthesizes comprehensive tags" do
      result = synthesizer.instance_eval do
        aws_lb_listener(:tagged_listener, {
          load_balancer_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/50dc6c495c0c9188",
          port: 443,
          protocol: "HTTPS",
          ssl_policy: "ELBSecurityPolicy-TLS-1-2-2017-01",
          certificate_arn: "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
          default_action: [{
            type: "forward",
            target_group_arn: "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
          }],
          tags: {
            Name: "production-https-listener",
            Environment: "production",
            Application: "web-app",
            Team: "platform",
            CostCenter: "engineering",
            Compliance: "pci-dss",
            Protocol: "HTTPS",
            Port: "443"
          }
        })
        
        synthesis
      end
      
      tags = result[:resource][:aws_lb_listener][:tagged_listener][:tags]
      expect(tags).to include(
        Name: "production-https-listener",
        Environment: "production",
        Application: "web-app",
        Team: "platform",
        CostCenter: "engineering",
        Compliance: "pci-dss"
      )
    end
  end
end