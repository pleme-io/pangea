# frozen_string_literal: true

require 'dry-struct'

module Pangea
  module Resources
    module AWS
      module S3AccessPoint
        # Common types for S3 Access Point configurations
        class Types < Dry::Types::Module
          include Dry.Types()

          # S3 Access Point Account Owner ID constraint
          AccessPointAccountId = String.constrained(format: /\A\d{12}\z/)
          
          # S3 Access Point Name constraint  
          AccessPointName = String.constrained(min_size: 3, max_size: 63, format: /\A[a-z0-9\-]+\z/)
          
          # S3 Access Point Network Origin
          NetworkOrigin = String.enum('Internet', 'VPC')
          
          # VPC Configuration for Access Point
          VpcConfiguration = Hash.schema({
            vpc_id: String
          })
          
          # Public Access Block Configuration
          PublicAccessBlockConfiguration = Hash.schema({
            block_public_acls?: Bool,
            block_public_policy?: Bool,
            ignore_public_acls?: Bool,
            restrict_public_buckets?: Bool
          })
        end

        # S3 Access Point attributes with comprehensive validation
        class S3AccessPointAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :account_id, AccessPointAccountId
          attribute :bucket, String
          attribute :name, AccessPointName
          
          # Optional attributes
          attribute? :bucket_account_id, AccessPointAccountId
          attribute? :network_origin, NetworkOrigin.default('Internet')
          attribute? :policy, String.optional
          attribute? :vpc_configuration, VpcConfiguration.optional
          attribute? :public_access_block_configuration, PublicAccessBlockConfiguration.default({})
          
          # Computed properties
          def vpc_access_point?
            network_origin == 'VPC'
          end
          
          def internet_access_point?
            network_origin == 'Internet'
          end
          
          def has_public_access_block?
            public_access_block_configuration.any?
          end
          
          def cross_account_access?
            bucket_account_id && bucket_account_id != account_id
          end
        end
      end
    end
  end
end