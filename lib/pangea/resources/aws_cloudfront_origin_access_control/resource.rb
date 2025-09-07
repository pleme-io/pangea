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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_cloudfront_origin_access_control/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudFront Origin Access Control with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudFront Origin Access Control attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cloudfront_origin_access_control(name, attributes = {})
        # Validate attributes using dry-struct
        oac_attrs = Types::CloudFrontOriginAccessControlAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudfront_origin_access_control, name) do
          name oac_attrs.name
          description oac_attrs.description if oac_attrs.description.present?
          origin_access_control_origin_type oac_attrs.origin_access_control_origin_type
          signing_behavior oac_attrs.signing_behavior
          signing_protocol oac_attrs.signing_protocol
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudfront_origin_access_control',
          name: name,
          resource_attributes: oac_attrs.to_h,
          outputs: {
            id: "${aws_cloudfront_origin_access_control.#{name}.id}",
            etag: "${aws_cloudfront_origin_access_control.#{name}.etag}"
          },
          computed: {
            s3_origin_type: oac_attrs.s3_origin_type?,
            always_signs: oac_attrs.always_signs?,
            never_signs: oac_attrs.never_signs?,
            no_override_signing: oac_attrs.no_override_signing?,
            uses_sigv4: oac_attrs.uses_sigv4?,
            has_description: oac_attrs.has_description?,
            security_level: oac_attrs.security_level
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)