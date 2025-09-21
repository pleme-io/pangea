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


require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS Key Pair resources
      class KeyPairAttributes < Dry::Struct
        # The name for the key pair (required)
        attribute :key_name, Resources::Types::String.optional
        
        # Creates a unique name beginning with the specified prefix (optional)
        attribute :key_name_prefix, Resources::Types::String.optional
        
        # The public key material (required)
        attribute :public_key, Resources::Types::String
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({}.freeze)

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Either key_name or key_name_prefix must be specified, but not both
          if attrs.key_name && attrs.key_name_prefix
            raise Dry::Struct::Error, "Cannot specify both 'key_name' and 'key_name_prefix'"
          end
          
          unless attrs.key_name || attrs.key_name_prefix
            raise Dry::Struct::Error, "Must specify either 'key_name' or 'key_name_prefix'"
          end
          
          # Validate key_name format (AWS requirements)
          if attrs.key_name && !valid_key_name?(attrs.key_name)
            raise Dry::Struct::Error, "Invalid key_name format. Must be 1-255 characters, alphanumeric, spaces, dashes, and underscores only"
          end
          
          # Validate key_name_prefix format
          if attrs.key_name_prefix && !valid_key_name?(attrs.key_name_prefix)
            raise Dry::Struct::Error, "Invalid key_name_prefix format. Must be 1-255 characters, alphanumeric, spaces, dashes, and underscores only"
          end
          
          # Validate public key format
          unless valid_public_key_format?(attrs.public_key)
            raise Dry::Struct::Error, "Invalid public key format. Must be a valid SSH public key"
          end
          
          attrs
        end

        # Check if using key name prefix
        def uses_prefix?
          !key_name_prefix.nil?
        end
        
        # Check if using explicit key name
        def uses_explicit_name?
          !key_name.nil?
        end
        
        # Get the effective key identifier
        def key_identifier
          key_name || key_name_prefix
        end
        
        # Determine the key type from public key
        def key_type
          case public_key
          when /^ssh-rsa\s/
            :rsa
          when /^ssh-dss\s/
            :dsa
          when /^ecdsa-sha2-nistp\d+\s/
            :ecdsa
          when /^ssh-ed25519\s/
            :ed25519
          else
            :unknown
          end
        end
        
        # Check if key is RSA
        def rsa_key?
          key_type == :rsa
        end
        
        # Check if key is ECDSA
        def ecdsa_key?
          key_type == :ecdsa
        end
        
        # Check if key is Ed25519
        def ed25519_key?
          key_type == :ed25519
        end
        
        # Estimate key size for RSA keys
        def estimated_key_size
          return nil unless rsa_key?
          
          # Basic estimation based on public key length
          # This is approximate as actual parsing would require OpenSSL
          key_data = public_key.split[1]
          case key_data.length
          when 200..400
            1024
          when 400..600
            2048
          when 600..800
            3072
          when 800..1200
            4096
          else
            nil
          end
        end

        private

        # Validate AWS key pair name format
        def self.valid_key_name?(name)
          return false if name.nil? || name.empty?
          return false if name.length > 255
          
          # AWS allows alphanumeric characters, spaces, dashes, and underscores
          name.match?(/\A[a-zA-Z0-9\s\-_]+\z/)
        end
        
        # Validate SSH public key format
        def self.valid_public_key_format?(public_key)
          return false if public_key.nil? || public_key.strip.empty?
          
          # Basic SSH public key format validation
          # Format: <key-type> <key-data> [comment]
          parts = public_key.strip.split(/\s+/)
          return false if parts.length < 2
          
          key_type = parts[0]
          key_data = parts[1]
          
          # Check supported key types
          supported_types = %w[ssh-rsa ssh-dss ecdsa-sha2-nistp256 ecdsa-sha2-nistp384 ecdsa-sha2-nistp521 ssh-ed25519]
          return false unless supported_types.include?(key_type)
          
          # Key data should be base64
          return false unless key_data.match?(/\A[A-Za-z0-9+\/]+=*\z/)
          
          # Minimum reasonable length for key data
          return false if key_data.length < 50
          
          true
        end
      end
    end
      end
    end
  end
end