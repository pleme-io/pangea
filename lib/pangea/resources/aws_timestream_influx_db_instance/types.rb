# frozen_string_literal: true

require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
      # Type-safe attributes for AwsTimestreamInfluxDbInstance resources
      # Provides a Timestream for InfluxDB instance resource.
      class TimestreamInfluxDbInstanceAttributes < Dry::Struct
        attribute :allocated_storage, Resources::Types::Integer
        attribute :bucket, Resources::Types::String.optional
        attribute :db_instance_type, Resources::Types::String
        attribute :db_name, Resources::Types::String
        attribute :db_parameter_group_identifier, Resources::Types::String.optional
        attribute :deployment_type, Resources::Types::String.optional
        attribute :log_delivery_configuration, Resources::Types::Array.of(Types::Hash).default([].freeze).optional
        attribute :name, Resources::Types::String
        attribute :organization, Resources::Types::String.optional
        attribute :password, Resources::Types::String
        attribute :publicly_accessible, Resources::Types::Bool.optional
        attribute :username, Resources::Types::String
        attribute :vpc_security_group_ids, Resources::Types::Array.of(Types::String).default([].freeze).optional
        attribute :vpc_subnet_ids, Resources::Types::Array.of(Types::String).default([].freeze).optional
        
        # Tags to apply to the resource
        attribute :tags, Resources::Types::AwsTags.default({})

        # Custom validation
        def self.new(attributes = {})
          attrs = super(attributes)
          
          
          
          
          attrs
        end
        
        # TODO: Add computed properties specific to aws_timestream_influx_db_instance

      end
    end
      end
    end
  end
end