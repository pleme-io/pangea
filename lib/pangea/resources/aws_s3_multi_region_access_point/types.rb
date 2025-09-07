# frozen_string_literal: true

require 'dry-struct'

module Pangea
  module Resources
    module AWS
      module S3MultiRegionAccessPoint
        # Common types for S3 Multi-Region Access Point configurations
        class Types < Dry::Types::Module
          include Dry.Types()

          # S3 Multi-Region Access Point Name constraint  
          MultiRegionAccessPointName = String.constrained(
            min_size: 3, 
            max_size: 50,
            format: /\A[a-z0-9\-]+\z/
          )
          
          # AWS Region constraint
          AwsRegion = String.constrained(
            format: /\A[a-z]{2}-[a-z]+-\d\z/
          )
          
          # Region Configuration for Multi-Region Access Point
          RegionConfiguration = Hash.schema({
            bucket: String,
            region: AwsRegion,
            bucket_account_id?: String.constrained(format: /\A\d{12}\z/)
          })
          
          # Public Access Block Configuration
          PublicAccessBlockConfiguration = Hash.schema({
            block_public_acls?: Bool,
            block_public_policy?: Bool,
            ignore_public_acls?: Bool,
            restrict_public_buckets?: Bool
          })
        end

        # S3 Multi-Region Access Point attributes with comprehensive validation
        class S3MultiRegionAccessPointAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :details, Hash.schema({
            name: MultiRegionAccessPointName,
            public_access_block_configuration?: PublicAccessBlockConfiguration.default({}),
            region: Array.of(RegionConfiguration).constrained(min_size: 1, max_size: 20)
          })
          
          # Optional attributes
          attribute? :account_id, String.constrained(format: /\A\d{12}\z/).optional
          
          # Computed properties
          def access_point_name
            details[:name]
          end
          
          def regions
            details[:region]
          end
          
          def region_count
            regions.length
          end
          
          def has_public_access_block?
            details[:public_access_block_configuration].any?
          end
          
          def cross_account_buckets?
            regions.any? { |region| region[:bucket_account_id] }
          end
          
          def bucket_names
            regions.map { |region| region[:bucket] }
          end
          
          def region_names
            regions.map { |region| region[:region] }
          end
        end
      end
    end
  end
end