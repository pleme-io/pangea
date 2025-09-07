# frozen_string_literal: true

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # SageMaker Domain execution role policy validation
        SageMakerDomainExecutionRole = String.constrained(
          format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9_+=,.@-]+\z/
        )
        
        # SageMaker Domain auth modes
        SageMakerDomainAuthMode = String.enum('SSO', 'IAM')
        
        # SageMaker Domain VPC-only mode
        SageMakerDomainVpcOnly = String.enum('Enabled', 'Disabled').default('Disabled')
        
        # SageMaker Domain app network access type
        SageMakerDomainAppNetworkAccessType = String.enum('PublicInternetOnly', 'VpcOnly').default('PublicInternetOnly')
        
        # SageMaker Domain app security group override
        SageMakerDomainAppSecurityGroupManagement = String.enum('Service', 'Customer').default('Service')
        
        # SageMaker Domain instance types for Studio
        SageMakerDomainInstanceType = String.enum(
          # System instances (for JupyterServer apps)
          'system',
          # ML instances
          'ml.t3.micro', 'ml.t3.small', 'ml.t3.medium', 'ml.t3.large', 'ml.t3.xlarge', 'ml.t3.2xlarge',
          'ml.m5.large', 'ml.m5.xlarge', 'ml.m5.2xlarge', 'ml.m5.4xlarge', 'ml.m5.8xlarge', 'ml.m5.12xlarge', 'ml.m5.16xlarge', 'ml.m5.24xlarge',
          'ml.c5.large', 'ml.c5.xlarge', 'ml.c5.2xlarge', 'ml.c5.4xlarge', 'ml.c5.9xlarge', 'ml.c5.18xlarge',
          'ml.r5.large', 'ml.r5.xlarge', 'ml.r5.2xlarge', 'ml.r5.4xlarge', 'ml.r5.8xlarge', 'ml.r5.12xlarge', 'ml.r5.16xlarge', 'ml.r5.24xlarge',
          'ml.g4dn.xlarge', 'ml.g4dn.2xlarge', 'ml.g4dn.4xlarge', 'ml.g4dn.8xlarge', 'ml.g4dn.12xlarge', 'ml.g4dn.16xlarge',
          'ml.p3.2xlarge', 'ml.p3.8xlarge', 'ml.p3.16xlarge',
          'ml.p4d.24xlarge'
        )
        
        # SageMaker Domain Jupyter Server app settings
        SageMakerDomainJupyterServerAppSettings = Hash.schema(
          default_resource_spec?: Hash.schema(
            instance_type?: SageMakerDomainInstanceType.optional,
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
        )
        
        # SageMaker Domain Kernel Gateway app settings  
        SageMakerDomainKernelGatewayAppSettings = Hash.schema(
          default_resource_spec?: Hash.schema(
            instance_type?: SageMakerDomainInstanceType.optional,
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
        )
        
        # SageMaker Domain Tensor Board app settings
        SageMakerDomainTensorBoardAppSettings = Hash.schema(
          default_resource_spec?: Hash.schema(
            instance_type?: SageMakerDomainInstanceType.optional,
            lifecycle_config_arn?: String.optional,
            sage_maker_image_arn?: String.optional,
            sage_maker_image_version_arn?: String.optional
          ).optional
        )
        
        # SageMaker Domain RStudio Server Pro app settings
        SageMakerDomainRStudioServerProAppSettings = Hash.schema(
          access_status?: String.enum('ENABLED', 'DISABLED').optional,
          user_group?: String.enum('R_STUDIO_ADMIN', 'R_STUDIO_USER').optional
        )
        
        # SageMaker Domain Canvas app settings
        SageMakerDomainCanvasAppSettings = Hash.schema(
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
          ).optional
        )
        
        # SageMaker Domain default user settings
        SageMakerDomainDefaultUserSettings = Hash.schema(
          execution_role: SageMakerDomainExecutionRole,
          security_groups?: Array.of(String).optional,
          sharing_settings?: Hash.schema(
            notebook_output_option?: String.enum('Allowed', 'Disabled').optional,
            s3_output_path?: String.optional,
            s3_kms_key_id?: String.optional
          ).optional,
          jupyter_server_app_settings?: SageMakerDomainJupyterServerAppSettings.optional,
          kernel_gateway_app_settings?: SageMakerDomainKernelGatewayAppSettings.optional,
          tensor_board_app_settings?: SageMakerDomainTensorBoardAppSettings.optional,
          r_studio_server_pro_app_settings?: SageMakerDomainRStudioServerProAppSettings.optional,
          canvas_app_settings?: SageMakerDomainCanvasAppSettings.optional
        )
        
        # SageMaker Domain retention policy
        SageMakerDomainRetentionPolicy = Hash.schema(
          home_efs_file_system?: String.enum('Retain', 'Delete').default('Retain')
        )
        
        # SageMaker Domain attributes with extensive ML-specific validation
        class SageMakerDomainAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          # Required attributes
          attribute :domain_name, Resources::Types::String.constrained(
            min_size: 1,
            max_size: 63,
            format: /\A[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\z/
          )
          attribute :auth_mode, SageMakerDomainAuthMode
          attribute :default_user_settings, SageMakerDomainDefaultUserSettings
          attribute :subnet_ids, Resources::Types::Array.of(String).constrained(min_size: 1, max_size: 16)
          attribute :vpc_id, Resources::Types::String
          
          # Optional attributes
          attribute :app_network_access_type, SageMakerDomainAppNetworkAccessType
          attribute :app_security_group_management, SageMakerDomainAppSecurityGroupManagement
          attribute :domain_settings, Resources::Types::Hash.schema(
            security_group_ids?: Array.of(String).optional,
            r_studio_server_pro_domain_settings?: Hash.schema(
              domain_execution_role_arn: String,
              r_studio_connect_url?: String.optional,
              r_studio_package_manager_url?: String.optional,
              default_resource_spec?: Hash.schema(
                instance_type?: String.optional,
                lifecycle_config_arn?: String.optional,
                sage_maker_image_arn?: String.optional,
                sage_maker_image_version_arn?: String.optional
              ).optional
            ).optional,
            execution_role_identity_config?: String.enum('USER_PROFILE_NAME', 'DISABLED').optional
          ).optional
          attribute :kms_key_id, Resources::Types::String.optional
          attribute :tags, Resources::Types::AwsTags
          attribute :default_space_settings, Resources::Types::Hash.schema(
            execution_role?: String.optional,
            security_groups?: Array.of(String).optional,
            jupyter_server_app_settings?: SageMakerDomainJupyterServerAppSettings.optional,
            kernel_gateway_app_settings?: SageMakerDomainKernelGatewayAppSettings.optional
          ).optional
          attribute :retention_policy, SageMakerDomainRetentionPolicy.optional
          
          # Custom validation for SageMaker Domain
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate VPC configuration
            if attrs[:vpc_id] && attrs[:subnet_ids]
              # All subnets must be in the same VPC
              subnet_ids = attrs[:subnet_ids]
              if subnet_ids.size < 2
                raise Dry::Struct::Error, "SageMaker Domain requires at least 2 subnets in different Availability Zones"
              end
            end
            
            # Validate auth mode specific requirements
            if attrs[:auth_mode] == 'SSO'
              if attrs[:domain_settings] && attrs[:domain_settings][:execution_role_identity_config] == 'DISABLED'
                raise Dry::Struct::Error, "execution_role_identity_config cannot be DISABLED when auth_mode is SSO"
              end
            end
            
            # Validate app network access type and VPC settings
            if attrs[:app_network_access_type] == 'VpcOnly'
              if attrs[:vpc_id].nil? || attrs[:subnet_ids].nil?
                raise Dry::Struct::Error, "vpc_id and subnet_ids are required when app_network_access_type is VpcOnly"
              end
            end
            
            # Validate KMS key format
            if attrs[:kms_key_id]
              unless attrs[:kms_key_id] =~ /\A(arn:aws:kms:|alias\/|[a-f0-9-]{36})/
                raise Dry::Struct::Error, "kms_key_id must be a valid KMS key ARN, alias, or key ID"
              end
            end
            
            # Validate execution role in default user settings
            execution_role = attrs.dig(:default_user_settings, :execution_role)
            if execution_role
              validate_execution_role_permissions(execution_role)
            end
            
            super(attrs)
          end
          
          # Validate that execution role has required permissions for SageMaker
          def self.validate_execution_role_permissions(role_arn)
            # Basic ARN format validation is handled by the type
            # In real implementation, this could validate that the role has required policies:
            # - AmazonSageMakerFullAccess or custom policies
            # - Trust relationship with sagemaker.amazonaws.com
            
            # For now, ensure it's a valid role ARN format
            unless role_arn =~ /\Aarn:aws:iam::\d{12}:role\//
              raise Dry::Struct::Error, "execution_role must be a valid IAM role ARN"
            end
          end
          
          # Computed properties
          def estimated_monthly_cost
            # Base domain cost
            base_cost = 0.0 # SageMaker Studio domain itself is free
            
            # Estimated costs based on default instance types and usage
            notebook_cost = 50.0  # Estimated for ml.t3.medium instances
            storage_cost = 10.0   # EFS storage for user directories
            
            base_cost + notebook_cost + storage_cost
          end
          
          def supports_vpc_only?
            app_network_access_type == 'VpcOnly'
          end
          
          def uses_sso_auth?
            auth_mode == 'SSO'
          end
          
          def uses_custom_kms_key?
            !kms_key_id.nil?
          end
          
          def has_custom_security_groups?
            domain_settings&.dig(:security_group_ids)&.any? || false
          end
          
          def supports_r_studio?
            domain_settings&.dig(:r_studio_server_pro_domain_settings) != nil
          end
          
          def subnet_count
            subnet_ids.size
          end
          
          # Security and compliance checks
          def security_score
            score = 0
            score += 20 if supports_vpc_only?
            score += 15 if uses_custom_kms_key?
            score += 10 if has_custom_security_groups?
            score += 15 if uses_sso_auth?
            score += 10 if subnet_count >= 3 # Multi-AZ redundancy
            
            [score, 100].min
          end
          
          def compliance_status
            issues = []
            issues << "No VPC-only access configured" unless supports_vpc_only?
            issues << "No custom KMS key for encryption" unless uses_custom_kms_key?
            issues << "Using IAM auth instead of SSO" unless uses_sso_auth?
            issues << "Insufficient subnet redundancy" if subnet_count < 2
            
            {
              status: issues.empty? ? 'compliant' : 'needs_attention',
              issues: issues
            }
          end
        end
      end
    end
  end
end