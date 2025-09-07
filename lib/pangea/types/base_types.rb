require 'ipaddr'

module Pangea
  module Types
    module BaseTypes
      def self.register_all(registry)
        # CIDR Block Type
        registry.register :cidr_block, String do
          format /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}\z/
          validation { |v| IPAddr.new(v) rescue false }
        end
        
        # Port Type
        registry.register :port, Integer do
          range 1, 65535
        end
        
        # Protocol Type
        registry.register :protocol, String do
          enum %w[tcp udp icmp all]
        end
        
        # IP Address Type
        registry.register :ip_address, String do
          format /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\z/
          validation { |v| IPAddr.new(v) rescue false }
        end
        
        # Domain Name Type
        registry.register :domain_name, String do
          format /\A[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9\-]{0,61}[a-z0-9])?)*\z/i
          max_length 253
        end
      end
    end
  end
end