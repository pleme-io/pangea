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


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Health check configuration for target group
        class TargetGroupHealthCheck < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :enabled, Resources::Types::Bool.default(true)
          attribute :interval, Resources::Types::Integer.default(30).constrained(gteq: 5, lteq: 300)
          attribute :path, Resources::Types::String.default('/')
          attribute :port, Resources::Types::String.default('traffic-port')
          attribute :protocol, Resources::Types::String.default('HTTP').enum('HTTP', 'HTTPS', 'TCP', 'TLS', 'UDP', 'TCP_UDP', 'GENEVE')
          attribute :timeout, Resources::Types::Integer.default(5).constrained(gteq: 2, lteq: 120)
          attribute :healthy_threshold, Resources::Types::Integer.default(5).constrained(gteq: 2, lteq: 10)
          attribute :unhealthy_threshold, Resources::Types::Integer.default(2).constrained(gteq: 2, lteq: 10)
          attribute :matcher, Resources::Types::String.default('200')
          
          # Validate timeout is less than interval
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            if attrs[:timeout] && attrs[:interval] && attrs[:timeout] >= attrs[:interval]
              raise Dry::Struct::Error, "Health check timeout (#{attrs[:timeout]}) must be less than interval (#{attrs[:interval]})"
            end
            
            super(attrs)
          end
          
          def to_h
            {
              enabled: enabled,
              interval: interval,
              path: path,
              port: port,
              protocol: protocol,
              timeout: timeout,
              healthy_threshold: healthy_threshold,
              unhealthy_threshold: unhealthy_threshold,
              matcher: matcher
            }
          end
        end
        
        # Stickiness configuration
        class TargetGroupStickiness < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :enabled, Resources::Types::Bool.default(false)
          attribute :type, Resources::Types::String.default('lb_cookie').enum('lb_cookie', 'app_cookie')
          attribute :duration, Resources::Types::Integer.default(86400).constrained(gteq: 1, lteq: 604800)
          attribute :cookie_name, Resources::Types::String.optional.default(nil)
          
          # Validate app_cookie requires cookie_name
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            if attrs[:type] == 'app_cookie' && !attrs[:cookie_name]
              raise Dry::Struct::Error, "cookie_name is required when stickiness type is 'app_cookie'"
            end
            
            super(attrs)
          end
          
          def to_h
            hash = {
              enabled: enabled,
              type: type
            }
            
            hash[:duration] = duration if type == 'lb_cookie'
            hash[:cookie_name] = cookie_name if cookie_name
            
            hash
          end
        end
        
        # Target group resource attributes with validation
        class TargetGroupAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :port, Resources::Types::Port
          attribute :protocol, Resources::Types::String.enum('HTTP', 'HTTPS', 'TCP', 'TLS', 'UDP', 'TCP_UDP', 'GENEVE')
          attribute :vpc_id, Resources::Types::String
          
          # Optional attributes
          attribute :name, Resources::Types::String.optional.default(nil)
          attribute :name_prefix, Resources::Types::String.optional.default(nil)
          attribute :target_type, Resources::Types::String.default('instance').enum('instance', 'ip', 'lambda', 'alb')
          attribute :deregistration_delay, Resources::Types::Integer.default(300).constrained(gteq: 0, lteq: 3600)
          attribute :slow_start, Resources::Types::Integer.default(0).constrained(gteq: 0, lteq: 900)
          attribute :proxy_protocol_v2, Resources::Types::Bool.default(false)
          attribute :preserve_client_ip, Resources::Types::Bool.optional.default(nil)
          attribute :ip_address_type, Resources::Types::String.default('ipv4').enum('ipv4', 'ipv6')
          attribute :protocol_version, Resources::Types::String.optional.default(nil).enum('HTTP1', 'HTTP2', 'GRPC')
          
          # Health check configuration
          attribute :health_check, TargetGroupHealthCheck.optional.default(nil)
          
          # Stickiness configuration
          attribute :stickiness, TargetGroupStickiness.optional.default(nil)
          
          # Tags
          attribute :tags, Resources::Types::AwsTags
          
          # Validate configuration consistency
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Name/name_prefix exclusivity
            if attrs[:name] && attrs[:name_prefix]
              raise Dry::Struct::Error, "Cannot specify both 'name' and 'name_prefix'"
            end
            
            # Protocol-specific validations
            protocol = attrs[:protocol]
            
            # GENEVE requires UDP and specific port
            if protocol == 'GENEVE' && attrs[:port] != 6081
              raise Dry::Struct::Error, "GENEVE protocol requires port 6081"
            end
            
            # Protocol version only valid for certain protocols
            if attrs[:protocol_version] && !%w[HTTP HTTPS].include?(protocol)
              raise Dry::Struct::Error, "protocol_version can only be set for HTTP/HTTPS protocols"
            end
            
            # Stickiness only valid for ALB protocols
            if attrs[:stickiness] && attrs[:stickiness][:enabled] && !%w[HTTP HTTPS].include?(protocol)
              raise Dry::Struct::Error, "Stickiness can only be enabled for HTTP/HTTPS target groups"
            end
            
            # Health check path only valid for HTTP/HTTPS
            if attrs[:health_check] && attrs[:health_check][:path] != '/' && !%w[HTTP HTTPS].include?(protocol)
              raise Dry::Struct::Error, "Health check path can only be set for HTTP/HTTPS target groups"
            end
            
            super(attrs)
          end
          
          # Computed properties
          def supports_stickiness?
            %w[HTTP HTTPS].include?(protocol)
          end
          
          def supports_health_check_path?
            %w[HTTP HTTPS].include?(protocol)
          end
          
          def is_network_load_balancer?
            %w[TCP TLS UDP TCP_UDP].include?(protocol)
          end
          
          def to_h
            hash = {
              port: port,
              protocol: protocol,
              vpc_id: vpc_id,
              target_type: target_type,
              deregistration_delay: deregistration_delay,
              ip_address_type: ip_address_type,
              tags: tags
            }
            
            # Optional attributes
            hash[:name] = name if name
            hash[:name_prefix] = name_prefix if name_prefix
            hash[:slow_start] = slow_start if slow_start > 0
            hash[:proxy_protocol_v2] = proxy_protocol_v2 if proxy_protocol_v2
            hash[:preserve_client_ip] = preserve_client_ip unless preserve_client_ip.nil?
            hash[:protocol_version] = protocol_version if protocol_version
            hash[:health_check] = health_check.to_h if health_check
            hash[:stickiness] = stickiness.to_h if stickiness
            
            hash.compact
          end
        end
      end
    end
  end
end