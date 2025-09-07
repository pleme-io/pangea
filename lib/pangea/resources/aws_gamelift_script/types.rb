# frozen_string_literal: true

require "dry-struct"

module Pangea
  module Resources
    module AwsGameliftScript
      module Types
        include Dry::Types()

        # S3 location configuration for script storage
        class S3Location < Dry::Struct
          attribute :bucket, String
          attribute :key, String
          attribute? :object_version, String
          attribute? :role_arn, String
        end

        class Attributes < Dry::Struct
          attribute :name, String
          attribute? :version, String
          attribute? :storage_location, S3Location
          attribute? :zip_file, String
          attribute? :tags, Hash.map(String, String)
        end

        class Reference < Dry::Struct
          attribute :id, String
          attribute :arn, String
          attribute :name, String
          attribute :creation_time, String
          attribute :size_on_disk, String
          attribute :version, String
        end
      end
    end
  end
end