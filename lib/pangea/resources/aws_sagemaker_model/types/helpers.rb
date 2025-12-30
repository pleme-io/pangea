# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        class SageMakerModelAttributes
          def estimated_monthly_cost
            estimate_model_storage_cost + (uses_multi_model_endpoint? ? 10.0 : 0.0)
          end

          def estimate_model_storage_cost
            count = 0
            count += 1 if primary_container&.dig(:model_data_url)
            count += containers&.count { |c| c[:model_data_url] } || 0
            count * 0.023
          end

          def is_multi_container_model? = containers && containers.size > 1
          def uses_multi_model_endpoint? = primary_container&.dig(:multi_model_config, :model_cache_setting) == 'Enabled'
          def has_vpc_configuration? = !vpc_config.nil?
          def uses_network_isolation? = enable_network_isolation
          def container_count = primary_container ? 1 : (containers&.size || 0)

          def all_containers = [primary_container, *(containers || [])].compact

          def uses_model_packages? = all_containers.any? { |c| c[:model_package_name] }
          def uses_custom_images? = all_containers.any? { |c| !c[:image].include?('763104351884.dkr.ecr') }
          def has_environment_variables? = all_containers.any? { |c| c[:environment]&.any? }
          def total_environment_variables = all_containers.sum { |c| c[:environment]&.size || 0 }

          def inference_configuration
            if is_multi_container_model?
              { type: 'multi-container', container_count: container_count,
                execution_mode: inference_execution_config&.dig(:mode) || 'Serial',
                supports_direct_invocation: inference_execution_config&.dig(:mode) == 'Direct' }
            else
              { type: 'single-container', container_count: 1, multi_model_endpoint: uses_multi_model_endpoint? }
            end
          end

          def security_score
            score = 0
            score += 20 if has_vpc_configuration?
            score += 25 if uses_network_isolation?
            score += 10 if uses_model_packages?
            score += 15 unless uses_custom_images?
            score += 10 if vpc_config && vpc_config[:security_group_ids].size >= 2
            [score, 100].min
          end

          def compliance_status
            issues = []
            issues << "No VPC configuration" unless has_vpc_configuration?
            issues << "Network isolation not enabled" unless uses_network_isolation?
            issues << "Using custom images" if uses_custom_images?
            issues << "Too many env vars (#{total_environment_variables})" if total_environment_variables > 20
            { status: issues.empty? ? 'compliant' : 'needs_attention', issues: issues }
          end

          def model_summary
            { model_name: model_name, model_type: is_multi_container_model? ? 'multi-container' : 'single-container',
              container_count: container_count, uses_vpc: has_vpc_configuration?, network_isolated: uses_network_isolation?,
              multi_model_endpoint: uses_multi_model_endpoint?, estimated_monthly_cost: estimated_monthly_cost,
              security_score: security_score, inference_config: inference_configuration }
          end
        end
      end
    end
  end
end
