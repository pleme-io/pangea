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
      # Type-safe attributes for AWS IoT Thing resources
      class IotThingAttributes < Dry::Struct
        # Thing name (required)
        attribute :thing_name, Resources::Types::IotThingName
        
        # Thing type name (optional)
        attribute :thing_type_name, Resources::Types::IotThingTypeName.optional
        
        # Attribute payload (optional key-value pairs)
        attribute :attribute_payload, Resources::Types::Hash.schema(
          attributes?: Types::IotThingAttributes.optional,
          merge?: Types::Bool.optional
        ).default({ attributes: {}, merge: false }.freeze)
        
        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate attribute payload merge behavior
          if attrs.attribute_payload[:merge] && (!attrs.attribute_payload[:attributes] || attrs.attribute_payload[:attributes].empty?)
            raise Dry::Struct::Error, "Cannot set merge: true without providing attributes"
          end
          
          attrs
        end
        
        # Get total attribute count
        def attribute_count
          return 0 unless attribute_payload[:attributes]
          attribute_payload[:attributes].keys.length
        end
        
        # Check if thing has a specific attribute
        def has_attribute?(key)
          return false unless attribute_payload[:attributes]
          attribute_payload[:attributes].key?(key.to_sym) || attribute_payload[:attributes].key?(key.to_s)
        end
        
        # Get attribute value
        def get_attribute(key)
          return nil unless attribute_payload[:attributes]
          attribute_payload[:attributes][key.to_sym] || attribute_payload[:attributes][key.to_s]
        end
        
        # Check if thing has a type
        def has_type?
          !thing_type_name.nil?
        end
        
        # Generate thing ARN (computed)
        def thing_arn_pattern(region, account_id)
          "arn:aws:iot:#{region}:#{account_id}:thing/#{thing_name}"
        end
        
        # Estimate storage usage in bytes
        def estimated_storage_bytes
          base_size = thing_name.bytesize
          base_size += thing_type_name.bytesize if thing_type_name
          
          if attribute_payload[:attributes]
            attribute_size = attribute_payload[:attributes].map do |k, v|
              k.to_s.bytesize + v.to_s.bytesize
            end.sum
            base_size += attribute_size
          end
          
          base_size
        end
        
        # Check if thing can be used for fleet indexing
        def fleet_indexing_ready?
          # Things with attributes are better for fleet indexing
          attribute_count > 0 || has_type?
        end
        
        # Security recommendations
        def security_recommendations
          recommendations = []
          
          recommendations << "Consider creating a thing type for better organization" unless has_type?
          recommendations << "Add meaningful attributes for fleet indexing" if attribute_count == 0
          recommendations << "Use consistent naming convention for thing names" unless thing_name.match?(/\A[a-zA-Z][a-zA-Z0-9_-]*\z/)
          
          if attribute_payload[:attributes]
            # Check for potentially sensitive attribute names
            sensitive_patterns = %w[password secret key token credential]
            sensitive_attrs = attribute_payload[:attributes].keys.select do |key|
              sensitive_patterns.any? { |pattern| key.to_s.downcase.include?(pattern) }
            end
            
            unless sensitive_attrs.empty?
              recommendations << "Avoid storing sensitive data in thing attributes: #{sensitive_attrs.join(', ')}"
            end
          end
          
          recommendations
        end
        
        # Generate thing principal permissions needed
        def required_permissions
          permissions = [
            "iot:UpdateThing",
            "iot:DescribeThing",
            "iot:DeleteThing"
          ]
          
          permissions << "iot:ListThingPrincipals" if has_type?
          permissions << "iot:UpdateThingAttribute" if attribute_count > 0
          
          permissions
        end
      end
    end
      end
    end
  end
end