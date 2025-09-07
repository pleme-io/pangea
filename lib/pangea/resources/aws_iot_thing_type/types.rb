# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AWS IoT Thing Type resources
      class IotThingTypeAttributes < Dry::Struct
        # Thing type name (required)
        attribute :thing_type_name, Resources::Types::IotThingTypeName
        
        # Thing type properties (optional)
        attribute :thing_type_properties, Resources::Types::IotThingTypeProperties.optional
        
        # Tags (optional)
        attribute :tags, Resources::Types::AwsTags.default({})
        
        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          # Validate searchable attributes don't exceed limit
          if attrs.thing_type_properties&.dig(:searchable_attributes)
            searchable = attrs.thing_type_properties[:searchable_attributes]
            if searchable.length > 3
              raise Dry::Struct::Error, "Thing type cannot have more than 3 searchable attributes"
            end
          end
          
          attrs
        end
        
        # Check if thing type has description
        def has_description?
          thing_type_properties&.dig(:description) && !thing_type_properties[:description].empty?
        end
        
        # Get description or default
        def description_text
          thing_type_properties&.dig(:description) || "IoT Thing Type: #{thing_type_name}"
        end
        
        # Check if thing type has searchable attributes
        def has_searchable_attributes?
          thing_type_properties&.dig(:searchable_attributes) && 
            thing_type_properties[:searchable_attributes].any?
        end
        
        # Get searchable attributes list
        def searchable_attributes_list
          thing_type_properties&.dig(:searchable_attributes) || []
        end
        
        # Count searchable attributes
        def searchable_attribute_count
          searchable_attributes_list.length
        end
        
        # Generate thing type ARN pattern
        def thing_type_arn_pattern(region, account_id)
          "arn:aws:iot:#{region}:#{account_id}:thingtype/#{thing_type_name}"
        end
        
        # Check if optimized for fleet indexing
        def fleet_indexing_optimized?
          has_searchable_attributes? && has_description?
        end
        
        # Get recommended attributes for things of this type
        def recommended_thing_attributes
          recommendations = []
          
          # Basic device information
          recommendations.concat(%w[model manufacturer serial_number firmware_version])
          
          # Location and deployment
          recommendations.concat(%w[location installation_date]) if !searchable_attributes_list.include?('location')
          
          # Operational data
          recommendations.concat(%w[last_maintenance next_maintenance status])
          
          # Include searchable attributes as recommended
          recommendations.concat(searchable_attributes_list)
          
          recommendations.uniq.sort
        end
        
        # Security and compliance recommendations
        def security_recommendations
          recommendations = []
          
          recommendations << "Add description for better organization" unless has_description?
          recommendations << "Define searchable attributes for fleet indexing" unless has_searchable_attributes?
          
          # Check for common naming patterns
          unless thing_type_name.match?(/\A[A-Z][a-zA-Z0-9_]*\z/)
            recommendations << "Use PascalCase naming convention for thing types"
          end
          
          # Recommend descriptive naming
          if thing_type_name.length < 5
            recommendations << "Consider more descriptive thing type names"
          end
          
          recommendations
        end
        
        # Generate example thing configuration for this type
        def example_thing_configuration
          example_attrs = {}
          
          # Add recommended attributes with example values
          recommended_thing_attributes.each do |attr|
            case attr
            when 'model'
              example_attrs[:model] = "#{thing_type_name}_v1"
            when 'manufacturer'
              example_attrs[:manufacturer] = "ACME Corp"
            when 'serial_number'
              example_attrs[:serial_number] = "SN001234"
            when 'firmware_version'
              example_attrs[:firmware_version] = "1.0.0"
            when 'location'
              example_attrs[:location] = "facility_01"
            when 'installation_date'
              example_attrs[:installation_date] = "2024-01-01"
            when 'status'
              example_attrs[:status] = "active"
            else
              example_attrs[attr.to_sym] = "example_value"
            end
          end
          
          {
            thing_name: "#{thing_type_name.downcase.gsub(/[^a-z0-9]/, '_')}_001",
            thing_type_name: thing_type_name,
            attribute_payload: {
              attributes: example_attrs
            }
          }
        end
        
        # IAM permissions required for this thing type
        def required_permissions
          permissions = [
            "iot:CreateThingType",
            "iot:DescribeThingType",
            "iot:DeleteThingType",
            "iot:ListThingTypes"
          ]
          
          if has_searchable_attributes?
            permissions.concat([
              "iot:SearchIndex",
              "iot:GetIndexingConfiguration"
            ])
          end
          
          permissions << "iot:ListTagsForResource" if tags.any?
          
          permissions.uniq.sort
        end
        
        # Estimated cost impact (qualitative)
        def cost_impact_analysis
          impact = {}
          
          # Base thing type has minimal cost
          impact[:thing_type_cost] = "minimal"
          
          # Fleet indexing costs
          if has_searchable_attributes?
            impact[:indexing_cost] = "low_to_medium"
            impact[:indexing_note] = "Searchable attributes enable fleet indexing (charges apply per indexed thing)"
          else
            impact[:indexing_cost] = "none"
          end
          
          # Things created with this type
          impact[:per_thing_cost] = "standard"
          impact[:per_thing_note] = "Each thing created with this type follows standard IoT Core pricing"
          
          impact
        end
        
        # Validate compatibility with existing thing types
        def compatibility_check(other_type_name)
          checks = {}
          
          # Name similarity check
          similarity_threshold = 0.7
          name_similarity = calculate_similarity(thing_type_name.downcase, other_type_name.downcase)
          
          if name_similarity > similarity_threshold
            checks[:name_conflict] = "high"
            checks[:name_warning] = "Thing type names are very similar, consider unique naming"
          else
            checks[:name_conflict] = "none"
          end
          
          checks
        end
        
        private
        
        # Simple string similarity calculation
        def calculate_similarity(str1, str2)
          return 1.0 if str1 == str2
          
          max_length = [str1.length, str2.length].max
          return 0.0 if max_length == 0
          
          # Simple character-based similarity
          common_chars = 0
          str1.each_char.with_index do |char, i|
            common_chars += 1 if i < str2.length && str2[i] == char
          end
          
          common_chars.to_f / max_length
        end
      end
    end
      end
    end
  end
end