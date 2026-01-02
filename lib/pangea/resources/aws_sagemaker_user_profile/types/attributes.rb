# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        SageMakerUserProfileName = String.constrained(
          min_size: 1, max_size: 63, format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
        )

        class SageMakerUserProfileAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :domain_id, Resources::Types::String
          attribute :user_profile_name, SageMakerUserProfileName
          attribute :single_sign_on_user_identifier, Resources::Types::String.optional
          attribute :single_sign_on_user_value, Resources::Types::String.optional
          attribute :user_settings, Resources::Types::Hash.schema(
            execution_role?: String.optional,
            security_groups?: Array.of(String).optional,
            sharing_settings?: Hash.schema(
              notebook_output_option?: String.enum('Allowed', 'Disabled').optional,
              s3_output_path?: String.optional, s3_kms_key_id?: String.optional
            ).optional,
            jupyter_server_app_settings?: Hash.optional,
            kernel_gateway_app_settings?: Hash.optional,
            tensor_board_app_settings?: Hash.optional,
            r_studio_server_pro_app_settings?: Hash.schema(
              access_status?: String.enum('ENABLED', 'DISABLED').optional,
              user_group?: String.enum('R_STUDIO_ADMIN', 'R_STUDIO_USER').optional
            ).optional,
            canvas_app_settings?: Hash.optional,
            space_storage_settings?: Hash.schema(
              default_ebs_storage_settings?: Hash.schema(
                default_ebs_volume_size_in_gb: Integer.constrained(gteq: 5, lteq: 16384),
                maximum_ebs_volume_size_in_gb: Integer.constrained(gteq: 5, lteq: 16384)
              ).optional
            ).optional,
            default_landing_uri?: String.optional,
            studio_web_portal?: String.enum('ENABLED', 'DISABLED').optional,
            custom_posix_user_config?: Hash.schema(
              uid: Integer.constrained(gteq: 1001, lteq: 4000000),
              gid: Integer.constrained(gteq: 1001, lteq: 4000000)
            ).optional,
            custom_file_system_configs?: Array.optional
          ).optional
          attribute :tags, Resources::Types::AwsTags

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            Validators.validate_domain_id(attrs)
            Validators.validate_sso_settings(attrs)
            Validators.validate_execution_role(attrs)
            Validators.validate_storage_settings(attrs)
            Validators.validate_posix_config(attrs)
            Validators.validate_canvas_oauth(attrs)
            super(attrs)
          end
        end
      end
    end
  end
end
