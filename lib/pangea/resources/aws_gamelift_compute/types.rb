# frozen_string_literal: true

require "dry-struct"

module Pangea
  module Resources
    module AwsGameliftCompute
      module Types
        include Dry::Types()

        class Attributes < Dry::Struct
          attribute :compute_name, String
          attribute :fleet_id, String
          attribute? :ip_address, String
          attribute? :dns_name, String
          attribute? :compute_arn, String
          attribute? :certificate_path, String
        end

        class Reference < Dry::Struct
          attribute :id, String
          attribute :compute_name, String
          attribute :compute_arn, String
          attribute :fleet_id, String
          attribute :fleet_arn, String
          attribute :ip_address, String
          attribute :dns_name, String
          attribute :compute_status, String
          attribute :location, String
          attribute :creation_time, String
          attribute :operating_system, String
          attribute :type, String
        end
      end
    end
  end
end