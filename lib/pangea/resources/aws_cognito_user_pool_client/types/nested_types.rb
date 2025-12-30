# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        # Token validity units configuration
        class CognitoUserPoolClientTokenValidityUnits < Dry::Struct
          attribute :access_token, Resources::Types::String.enum('seconds', 'minutes', 'hours', 'days').default('hours')
          attribute :id_token, Resources::Types::String.enum('seconds', 'minutes', 'hours', 'days').default('hours')
          attribute :refresh_token, Resources::Types::String.enum('seconds', 'minutes', 'hours', 'days').default('days')
        end

        # Analytics configuration for user pool client
        class CognitoUserPoolClientAnalyticsConfiguration < Dry::Struct
          attribute :application_arn, Resources::Types::String.optional
          attribute :application_id, Resources::Types::String.optional
          attribute :external_id, Resources::Types::String.optional
          attribute :role_arn, Resources::Types::String.optional
          attribute :user_data_shared, Resources::Types::Bool.optional
        end
      end
    end
  end
end
