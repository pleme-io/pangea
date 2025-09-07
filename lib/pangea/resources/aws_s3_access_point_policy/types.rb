# frozen_string_literal: true

require 'dry-struct'

module Pangea
  module Resources
    module AWS
      module S3AccessPointPolicy
        # Common types for S3 Access Point Policy configurations
        class Types < Dry::Types::Module
          include Dry.Types()

          # S3 Access Point ARN constraint
          AccessPointArn = String.constrained(
            format: /\Aarn:aws:s3:[a-z0-9\-]*:[0-9]{12}:accesspoint\/[a-z0-9\-]+\z/
          )
        end

        # S3 Access Point Policy attributes with comprehensive validation
        class S3AccessPointPolicyAttributes < Dry::Struct
          include Types[self]
          
          # Required attributes
          attribute :access_point_arn, AccessPointArn
          attribute :policy, String
          
          # Computed properties
          def policy_document
            JSON.parse(policy) rescue nil
          end
          
          def has_valid_json?
            !policy_document.nil?
          end
          
          def access_point_name
            access_point_arn.split('/')[-1]
          end
          
          def account_id
            access_point_arn.split(':')[4]
          end
          
          def region
            access_point_arn.split(':')[3]
          end
        end
      end
    end
  end
end