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
      # Type-safe attributes for AWS CloudFront Origin Access Control resources
      class CloudFrontOriginAccessControlAttributes < Dry::Struct
        transform_keys(&:to_sym)

        # Name for the origin access control
        attribute :name, Resources::Types::String

        # Description of the origin access control
        attribute :description, Resources::Types::String.default('')

        # Origin type (s3 is the only supported type currently)
        attribute :origin_access_control_origin_type, Resources::Types::String.enum('s3').default('s3')

        # Signing behavior for the origin access control
        attribute :signing_behavior, Resources::Types::String.enum('always', 'never', 'no-override').default('always')

        # Signing protocol for the origin access control
        attribute :signing_protocol, Resources::Types::String.enum('sigv4').default('sigv4')

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)

          # Validate name format
          if attrs.name.length < 1 || attrs.name.length > 64
            raise Dry::Struct::Error, "Name must be between 1 and 64 characters"
          end

          # Basic name pattern validation
          unless attrs.name.match?(/^[a-zA-Z0-9._-]+$/)
            raise Dry::Struct::Error, "Name can only contain alphanumeric characters, periods, underscores, and hyphens"
          end

          attrs
        end

        # Helper methods
        def s3_origin_type?
          origin_access_control_origin_type == 's3'
        end

        def always_signs?
          signing_behavior == 'always'
        end

        def never_signs?
          signing_behavior == 'never'
        end

        def no_override_signing?
          signing_behavior == 'no-override'
        end

        def uses_sigv4?
          signing_protocol == 'sigv4'
        end

        def has_description?
          description.present?
        end

        def security_level
          case signing_behavior
          when 'always'
            'high'
          when 'no-override'
            'medium'
          else
            'low'
          end
        end
      end
    end
      end
    end
  end
end