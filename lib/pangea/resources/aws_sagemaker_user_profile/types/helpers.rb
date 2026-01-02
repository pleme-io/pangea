# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class SageMakerUserProfileAttributes
          def estimated_monthly_cost = 20.0 + get_storage_cost

          def get_storage_cost
            storage = user_settings&.dig(:space_storage_settings, :default_ebs_storage_settings)
            storage ? (storage[:default_ebs_volume_size_in_gb] || 10) * 0.10 : 1.0
          end

          def has_sso_integration? = !single_sign_on_user_identifier.nil?
          def has_custom_execution_role? = !user_settings&.dig(:execution_role).nil?
          def has_custom_posix_config? = !user_settings&.dig(:custom_posix_user_config).nil?
          def has_efs_integration? = user_settings&.dig(:custom_file_system_configs)&.any? { |c| c[:efs_file_system_config] }
          def canvas_enabled? = user_settings&.dig(:canvas_app_settings) != nil
          def r_studio_enabled? = user_settings&.dig(:r_studio_server_pro_app_settings) != nil
          def notebook_sharing_disabled? = user_settings&.dig(:sharing_settings, :notebook_output_option) == 'Disabled'
          def uses_custom_storage? = user_settings&.dig(:space_storage_settings, :default_ebs_storage_settings) != nil
          def default_storage_size_gb = user_settings&.dig(:space_storage_settings, :default_ebs_storage_settings, :default_ebs_volume_size_in_gb) || 5
          def max_storage_size_gb = user_settings&.dig(:space_storage_settings, :default_ebs_storage_settings, :maximum_ebs_volume_size_in_gb) || 16384

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
            issues << "No custom execution role" unless has_custom_execution_role?
            issues << "Notebook sharing enabled" unless notebook_sharing_disabled?
            issues << "No SSO integration" unless has_sso_integration?
            issues << "No KMS for shared outputs" unless user_settings&.dig(:sharing_settings, :s3_kms_key_id)
            { status: issues.empty? ? 'compliant' : 'needs_attention', issues: issues }
          end

          def enabled_applications
            apps = ['jupyter-server']
            apps << 'kernel-gateway' if user_settings&.dig(:kernel_gateway_app_settings)
            apps << 'tensor-board' if user_settings&.dig(:tensor_board_app_settings)
            apps << 'r-studio-server-pro' if r_studio_enabled?
            apps << 'canvas' if canvas_enabled?
            apps
          end

          def profile_summary
            { user_profile_name: user_profile_name, domain_id: domain_id, sso_integrated: has_sso_integration?,
              enabled_applications: enabled_applications, storage_size_gb: default_storage_size_gb,
              security_score: security_score, estimated_monthly_cost: estimated_monthly_cost }
          end
        end
      end
    end
  end
end
