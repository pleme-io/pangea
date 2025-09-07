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
require 'pangea/resources/aws_media_store_container/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS MediaStore Container with type-safe attributes
      def aws_media_store_container(name, attributes = {})
        container_attrs = Types::MediaStoreContainerAttributes.new(attributes)
        
        resource(:aws_media_store_container, name) do
          name container_attrs.name
          
          if container_attrs.tags.any?
            tags do
              container_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_media_store_container',
          name: name,
          resource_attributes: container_attrs.to_h,
          outputs: {
            arn: "${aws_media_store_container.#{name}.arn}",
            endpoint: "${aws_media_store_container.#{name}.endpoint}",
            name: "${aws_media_store_container.#{name}.name}"
          },
          computed: {
            name_valid: container_attrs.name_valid?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)