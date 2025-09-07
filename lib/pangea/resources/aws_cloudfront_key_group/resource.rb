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
require 'pangea/resources/aws_cloudfront_key_group/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS CloudFront Key Group with type-safe attributes
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] CloudFront key group attributes
      # @return [ResourceReference] Reference object with outputs and computed properties
      def aws_cloudfront_key_group(name, attributes = {})
        # Validate attributes using dry-struct
        key_group_attrs = Types::CloudFrontKeyGroupAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_cloudfront_key_group, name) do
          name key_group_attrs.name
          comment key_group_attrs.comment if key_group_attrs.comment
          
          items key_group_attrs.items
        end
        
        # Return resource reference with available outputs
        ResourceReference.new(
          type: 'aws_cloudfront_key_group',
          name: name,
          resource_attributes: key_group_attrs.to_h,
          outputs: {
            id: "${aws_cloudfront_key_group.#{name}.id}",
            name: "${aws_cloudfront_key_group.#{name}.name}",
            comment: "${aws_cloudfront_key_group.#{name}.comment}",
            items: "${aws_cloudfront_key_group.#{name}.items}",
            etag: "${aws_cloudfront_key_group.#{name}.etag}"
          },
          computed_properties: {
            key_count: key_group_attrs.key_count,
            single_key: key_group_attrs.single_key?,
            multiple_keys: key_group_attrs.multiple_keys?,
            security_level: key_group_attrs.security_level,
            production_ready: key_group_attrs.production_ready?,
            rotation_capable: key_group_attrs.rotation_capable?,
            configuration_warnings: key_group_attrs.validate_configuration,
            estimated_monthly_cost: key_group_attrs.estimated_monthly_cost
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)