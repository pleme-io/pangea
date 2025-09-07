# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker User Profile name validation
        SageMakerUserProfileName = String.constrained(
          min_size: 1,
          max_size: 63,
          format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
        )
        
        # SageMaker User Profile attributes with comprehensive ML user management
        class SageMakerUserProfileAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :domain_id, Resources::Types::String
          attribute :user_profile_name, SageMakerUserProfileName
          
          # Optional user-specific settings (inherits from domain if not specified)
          attribute :single_sign_on_user_identifier, Resources::Types::String.optional
          attribute :single_sign_on_user_value, Resources::Types::String.optional
          attribute :user_settings, Resources::Types::Hash.schema(
            execution_role?: String.optional,
            security_groups?: Array.of(String).optional,
            sharing_settings?: Hash.schema(
              notebook_output_option?: String.enum('Allowed', 'Disabled').optional,
              s3_output_path?: String.optional,
              s3_kms_key_id?: String.optional
            ).optional,
            jupyter_server_app_settings?: Hash.schema(
              default_resource_spec?: Hash.schema(
                instance_type?: String.optional,
                lifecycle_config_arn?: String.optional,
                sage_maker_image_arn?: String.optional,
                sage_maker_image_version_arn?: String.optional
              ).optional,
              lifecycle_config_arns?: Array.of(String).optional,
              code_repositories?: Array.of(
                Hash.schema(
                  repository_url: String.constrained(format: /\Ahttps:\/\/github\.com\//),
                  default_branch?: String.default('main')
                )
              ).optional
            ).optional,
            kernel_gateway_app_settings?: Hash.schema(
              default_resource_spec?: Hash.schema(
                instance_type?: String.optional,
                lifecycle_config_arn?: String.optional,
                sage_maker_image_arn?: String.optional,
                sage_maker_image_version_arn?: String.optional
              ).optional,
              lifecycle_config_arns?: Array.of(String).optional,
              custom_images?: Array.of(
                Hash.schema(
                  app_image_config_name: String,
                  image_name: String,
                  image_version_number?: Integer.optional
                )
              ).optional
            ).optional,
            tensor_board_app_settings?: Hash.schema(
              default_resource_spec?: Hash.schema(
                instance_type?: String.optional,
                lifecycle_config_arn?: String.optional,
                sage_maker_image_arn?: String.optional,
                sage_maker_image_version_arn?: String.optional
              ).optional
            ).optional,
            r_studio_server_pro_app_settings?: Hash.schema(
              access_status?: String.enum('ENABLED', 'DISABLED').optional,
              user_group?: String.enum('R_STUDIO_ADMIN', 'R_STUDIO_USER').optional
            ).optional,
            canvas_app_settings?: Hash.schema(
              time_series_forecasting_settings?: Hash.schema(
                status?: String.enum('ENABLED', 'DISABLED').optional,
                amazon_forecast_role_arn?: String.optional
              ).optional,
              model_register_settings?: Hash.schema(
                status?: String.enum('ENABLED', 'DISABLED').optional,
                cross_account_model_register_role_arn?: String.optional
              ).optional,
              workspace_settings?: Hash.schema(
                s3_artifact_path?: String.optional,
                s3_kms_key_id?: String.optional
              ).optional,
              identity_provider_oauth_settings?: Array.of(
                Hash.schema(
                  data_source_name?: String.enum('SalesForce', 'Slack').optional,
                  status?: String.enum('ENABLED', 'DISABLED').optional,
                  secret_arn?: String.optional
                )
              ).optional,
              direct_deploy_settings?: Hash.schema(
                status?: String.enum('ENABLED', 'DISABLED').optional
              ).optional,
              kendra_settings?: Hash.schema(
                status?: String.enum('ENABLED', 'DISABLED').optional
              ).optional,
              generative_ai_settings?: Hash.schema(
                amazon_bedrock_role_arn?: String.optional
              ).optional
            ).optional,
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
            custom_file_system_configs?: Array.of(
              Hash.schema(
                efs_file_system_config?: Hash.schema(
                  file_system_id: String,
                  file_system_path?: String.default("/")
                ).optional
              )
            ).optional
          ).optional
          attribute :tags, Resources::Types::AwsTags
          
          # Custom validation for SageMaker User Profile
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate domain_id format
            if attrs[:domain_id]
              unless attrs[:domain_id] =~ /\Ad-[a-z0-9]{13}\z/
                raise Dry::Struct::Error, "domain_id must be a valid SageMaker domain ID (format: d-xxxxxxxxxxxxx)"
              end
            end
            
            # Validate SSO settings consistency
            sso_identifier = attrs[:single_sign_on_user_identifier]
            sso_value = attrs[:single_sign_on_user_value]
            
            if sso_identifier && sso_value.nil?
              raise Dry::Struct::Error, "single_sign_on_user_value is required when single_sign_on_user_identifier is specified"
            end
            
            if sso_value && sso_identifier.nil?
              raise Dry::Struct::Error, "single_sign_on_user_identifier is required when single_sign_on_user_value is specified"
            end
            
            # Validate execution role format if specified
            if attrs.dig(:user_settings, :execution_role)
              execution_role = attrs[:user_settings][:execution_role]
              unless execution_role =~ /\Aarn:aws:iam::\d{12}:role\//
                raise Dry::Struct::Error, "execution_role must be a valid IAM role ARN"
              end
            end
            
            # Validate storage settings consistency
            if attrs.dig(:user_settings, :space_storage_settings, :default_ebs_storage_settings)
              storage = attrs[:user_settings][:space_storage_settings][:default_ebs_storage_settings]
              default_size = storage[:default_ebs_volume_size_in_gb]
              max_size = storage[:maximum_ebs_volume_size_in_gb]
              
              if default_size && max_size && default_size > max_size
                raise Dry::Struct::Error, "default_ebs_volume_size_in_gb cannot be larger than maximum_ebs_volume_size_in_gb"
              end
            end
            
            # Validate POSIX user config
            if attrs.dig(:user_settings, :custom_posix_user_config)
              posix_config = attrs[:user_settings][:custom_posix_user_config]
              uid = posix_config[:uid]
              gid = posix_config[:gid]
              
              # Validate UID/GID are in non-system range
              if uid && uid < 1001
                raise Dry::Struct::Error, "POSIX UID must be >= 1001 (non-system user range)"
              end
              
              if gid && gid < 1001  
                raise Dry::Struct::Error, "POSIX GID must be >= 1001 (non-system group range)"
              end
            end
            
            # Validate Canvas OAuth settings
            if attrs.dig(:user_settings, :canvas_app_settings, :identity_provider_oauth_settings)
              oauth_settings = attrs[:user_settings][:canvas_app_settings][:identity_provider_oauth_settings]
              oauth_settings.each do |setting|
                if setting[:status] == 'ENABLED' && setting[:secret_arn].nil?
                  raise Dry::Struct::Error, "secret_arn is required when OAuth identity provider is ENABLED"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties
          def estimated_monthly_cost
            base_cost = 0.0 # User profiles are free, costs come from compute usage
            
            # Estimate based on default instance types and storage
            compute_cost = 20.0  # Estimated for basic notebook usage
            storage_cost = get_storage_cost
            
            base_cost + compute_cost + storage_cost
          end
          
          def get_storage_cost
            if user_settings&.dig(:space_storage_settings, :default_ebs_storage_settings)
              storage_gb = user_settings[:space_storage_settings][:default_ebs_storage_settings][:default_ebs_volume_size_in_gb] || 10
              storage_gb * 0.10 # $0.10 per GB per month for EBS
            else
              1.0 # Default EFS storage cost
            end
          end
          
          def has_sso_integration?
            !single_sign_on_user_identifier.nil?
          end
          
          def has_custom_execution_role?
            !user_settings&.dig(:execution_role).nil?
          end
          
          def has_custom_posix_config?
            !user_settings&.dig(:custom_posix_user_config).nil?
          end
          
          def has_efs_integration?
            user_settings&.dig(:custom_file_system_configs)&.any? { |config| config[:efs_file_system_config] }
          end
          
          def canvas_enabled?
            user_settings&.dig(:canvas_app_settings) != nil
          end
          
          def r_studio_enabled?
            user_settings&.dig(:r_studio_server_pro_app_settings) != nil
          end
          
          def notebook_sharing_disabled?
            user_settings&.dig(:sharing_settings, :notebook_output_option) == 'Disabled'
          end
          
          def uses_custom_storage?
            user_settings&.dig(:space_storage_settings, :default_ebs_storage_settings) != nil
          end
          
          def default_storage_size_gb
            user_settings&.dig(:space_storage_settings, :default_ebs_storage_settings, :default_ebs_volume_size_in_gb) || 5
          end
          
          def max_storage_size_gb
            user_settings&.dig(:space_storage_settings, :default_ebs_storage_settings, :maximum_ebs_volume_size_in_gb) || 16384
          end
          
          # Security and compliance assessment
          def security_score
            score = 0
            score += 20 if has_custom_execution_role?
            score += 15 if notebook_sharing_disabled?
            score += 10 if has_custom_posix_config?
            score += 15 if has_sso_integration?
            score += 10 if user_settings&.dig(:sharing_settings, :s3_kms_key_id)
            score += 10 if canvas_enabled? && user_settings.dig(:canvas_app_settings, :workspace_settings, :s3_kms_key_id)
            score += 5 if uses_custom_storage?
            
            [score, 100].min
          end
          
          def compliance_status
            issues = []
            issues << "No custom execution role specified" unless has_custom_execution_role?
            issues << "Notebook sharing is enabled" unless notebook_sharing_disabled?
            issues << "No SSO integration configured" unless has_sso_integration?
            issues << "No KMS encryption for shared outputs" unless user_settings&.dig(:sharing_settings, :s3_kms_key_id)
            issues << "Canvas workspace not encrypted with KMS" if canvas_enabled? && !user_settings.dig(:canvas_app_settings, :workspace_settings, :s3_kms_key_id)
            
            {
              status: issues.empty? ? 'compliant' : 'needs_attention',
              issues: issues
            }
          end
          
          # User capability summary
          def enabled_applications
            apps = ['jupyter-server'] # Always available
            apps << 'kernel-gateway' if user_settings&.dig(:kernel_gateway_app_settings)
            apps << 'tensor-board' if user_settings&.dig(:tensor_board_app_settings)
            apps << 'r-studio-server-pro' if r_studio_enabled?
            apps << 'canvas' if canvas_enabled?
            apps
          end
          
          def profile_summary
            {
              user_profile_name: user_profile_name,
              domain_id: domain_id,
              sso_integrated: has_sso_integration?,
              enabled_applications: enabled_applications,
              storage_size_gb: default_storage_size_gb,
              security_score: security_score,
              estimated_monthly_cost: estimated_monthly_cost
            }
          end
        end
      end
    end
  end
end