# frozen_string_literal: true

require 'dry-struct'

module Pangea
  module Resources
    module AWS
      module S3BucketAccelerateConfiguration
        # Common types for S3 Bucket Accelerate Configuration
        class Types < Dry::Types::Module
          include Dry.Types()

          # Transfer acceleration status
          AccelerationStatus = String.enum('Enabled', 'Suspended')
          
          # S3 Bucket Name constraint
          BucketName = String.constrained(
            min_size: 3,
            max_size: 63,
            format: /\A[a-z0-9\-\.]+\z/
          )
        end

        # S3 Bucket Accelerate Configuration attributes
        class S3BucketAccelerateConfigurationAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :bucket, BucketName
          attribute :status, AccelerationStatus
          
          # Optional attributes
          attribute? :expected_bucket_owner, String.constrained(format: /\A\d{12}\z/).optional
          
          # Computed properties
          def acceleration_enabled?
            status == 'Enabled'
          end
          
          def acceleration_suspended?
            status == 'Suspended'
          end
          
          def cross_account_bucket?
            !expected_bucket_owner.nil?
          end
        end
      end
    end
  end
end