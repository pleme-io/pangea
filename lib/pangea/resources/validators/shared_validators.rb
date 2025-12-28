# frozen_string_literal: true
# Copyright 2025 The Pangea Authors

require 'base64'
require 'json'
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

module Pangea
  module Resources
    module Validators
      # Shared validation methods for resource attributes
      #
      # Provides reusable validation logic that can be used across
      # different providers and resource types.
      #
      # @example Using in a dry-struct type
      #   CidrBlock = String.constructor { |value|
      #     SharedValidators.valid_cidr!(value)
      #   }
      #
      module SharedValidators
        class ValidationError < StandardError; end

        module_function

        # Validate CIDR block format
        #
        # @param value [String] The CIDR block to validate
        # @return [String] The validated value
        # @raise [ValidationError] If validation fails
        def valid_cidr!(value)
          unless value.match?(%r{\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}\z})
            raise ValidationError, "Invalid CIDR format: #{value}"
          end

          ip, prefix = value.split('/')
          octets = ip.split('.').map(&:to_i)
          prefix_int = prefix.to_i

          unless octets.all? { |o| (0..255).include?(o) }
            raise ValidationError, "Invalid IP address in CIDR: #{value}"
          end

          unless (0..32).include?(prefix_int)
            raise ValidationError, "Invalid prefix length (0-32): #{value}"
          end

          value
        end

        # Validate port number
        #
        # @param value [Integer] The port number
        # @return [Integer] The validated port
        # @raise [ValidationError] If port is out of range
        def valid_port!(value)
          unless value.is_a?(Integer) && (0..65535).include?(value)
            raise ValidationError, "Port must be 0-65535, got: #{value}"
          end
          value
        end

        # Validate port range
        #
        # @param from_port [Integer] Start of range
        # @param to_port [Integer] End of range
        # @raise [ValidationError] If range is invalid
        def valid_port_range!(from_port, to_port)
          valid_port!(from_port)
          valid_port!(to_port)
          if from_port > to_port
            raise ValidationError, "from_port (#{from_port}) cannot exceed to_port (#{to_port})"
          end
          true
        end

        # Validate AWS region format
        #
        # @param value [String] The region string
        # @return [String] The validated region
        def valid_aws_region!(value)
          unless value.match?(/\A[a-z]{2}-[a-z]+-\d\z/)
            raise ValidationError, "Invalid AWS region format: #{value}"
          end
          value
        end

        # Validate AWS availability zone format
        #
        # @param value [String] The AZ string
        # @return [String] The validated AZ
        def valid_aws_az!(value)
          unless value.match?(/\A[a-z]{2}-[a-z]+-\d[a-z]\z/)
            raise ValidationError, "Invalid AWS AZ format: #{value}"
          end
          value
        end

        # Validate domain name format
        #
        # @param value [String] The domain name
        # @param allow_wildcard [Boolean] Whether wildcards are allowed
        # @return [String] The validated domain
        def valid_domain!(value, allow_wildcard: false)
          pattern = if allow_wildcard
                      /\A(\*\.)?(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)*[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/i
                    else
                      /\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)*[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\z/i
                    end

          unless value.match?(pattern)
            raise ValidationError, "Invalid domain name: #{value}"
          end
          value
        end

        # Validate email format
        #
        # @param value [String] The email address
        # @return [String] The validated email
        def valid_email!(value)
          unless value.match?(/\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)
            raise ValidationError, "Invalid email format: #{value}"
          end
          value
        end

        # Validate Terraform interpolation or literal value
        #
        # @param value [String] The value to check
        # @return [Boolean] True if it's a Terraform interpolation
        def terraform_interpolation?(value)
          value.is_a?(String) && value.match?(/\A\$\{.+\}\z/)
        end

        # Validate hex string of specific length
        #
        # @param value [String] The hex string
        # @param length [Integer] Expected length
        # @param allow_interpolation [Boolean] Allow Terraform interpolations
        # @return [String] The validated value
        def valid_hex!(value, length:, allow_interpolation: true)
          return value if allow_interpolation && terraform_interpolation?(value)

          unless value.match?(/\A[a-f0-9]{#{length}}\z/i)
            raise ValidationError, "Expected #{length}-char hex string: #{value}"
          end
          value
        end

        # Validate AWS ARN format
        #
        # @param value [String] The ARN string
        # @param service [String, nil] Optional service name to validate
        # @return [String] The validated ARN
        def valid_arn!(value, service: nil)
          pattern = if service
                      /\Aarn:aws:#{Regexp.escape(service)}:[a-z0-9-]*:\d{12}:.+\z/
                    else
                      /\Aarn:aws:[a-z0-9-]+:[a-z0-9-]*:\d{12}:.+\z/
                    end

          unless value.match?(pattern)
            raise ValidationError, "Invalid ARN format: #{value}"
          end
          value
        end

        # Validate JSON string
        #
        # @param value [String] The JSON string
        # @return [String] The validated JSON
        def valid_json!(value)
          JSON.parse(value)
          value
        rescue JSON::ParserError
          raise ValidationError, "Invalid JSON: #{value[0..50]}..."
        end

        # Validate base64 encoded string
        #
        # @param value [String] The base64 string
        # @return [String] The validated string
        def valid_base64!(value)
          unless value.match?(/\A[A-Za-z0-9+\/]*={0,2}\z/)
            raise ValidationError, "Invalid base64 format"
          end
          begin
            Base64.strict_decode64(value)
            value
          rescue ArgumentError
            raise ValidationError, "Invalid base64 encoding"
          end
        end
      end
    end
  end
end
