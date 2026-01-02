# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require_relative 'definitions'

module Pangea
  module Resources
    module AWS
      module Types
        class BudgetActionAttributes < Dry::Struct
          transform_keys(&:to_sym)

          attribute :budget_name, String.constrained(format: /\A[a-zA-Z0-9_\-. ]{1,100}\z/)
          attribute :action_type, BudgetActionType
          attribute :approval_model, BudgetActionApprovalModel
          attribute :notification_type, ActionNotificationType
          attribute :action_threshold, Numeric
          attribute :action_threshold_type, String.enum('PERCENTAGE', 'ABSOLUTE_VALUE').default('PERCENTAGE')
          attribute :definition, BudgetActionDefinition
          attribute :execution_role_arn, BudgetActionExecutionRole
          attribute :subscribers?, Array.of(ActionSubscriber).constrained(max_size: 11).optional
          attribute :tags?, AwsTags.optional

          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            validate_action_definition_match(attrs) if attrs[:action_type] && attrs[:definition]
            validate_automatic_thresholds(attrs) if attrs[:approval_model] == 'AUTOMATIC'
            super(attrs)
          end

          def self.validate_action_definition_match(attrs)
            definition = attrs[:definition]
            case attrs[:action_type]
            when 'APPLY_IAM_POLICY' then raise Dry::Struct::Error, 'IAM policy action type requires iam_action_definition' unless definition[:iam_action_definition]
            when 'APPLY_SCP_POLICY' then raise Dry::Struct::Error, 'SCP policy action type requires scp_action_definition' unless definition[:scp_action_definition]
            when 'RUN_SSM_DOCUMENTS' then raise Dry::Struct::Error, 'SSM document action type requires ssm_action_definition' unless definition[:ssm_action_definition]
            end
          end

          def self.validate_automatic_thresholds(attrs)
            threshold_type = attrs[:action_threshold_type] || 'PERCENTAGE'
            raise Dry::Struct::Error, 'Automatic actions with thresholds over 150% may cause issues' if threshold_type == 'PERCENTAGE' && attrs[:action_threshold].to_f > 150
          end

          def is_preventive_action? = %w[APPLY_IAM_POLICY APPLY_SCP_POLICY].include?(action_type)
          def is_reactive_action? = action_type == 'RUN_SSM_DOCUMENTS'
          def affects_iam_permissions? = action_type == 'APPLY_IAM_POLICY'
          def affects_organization_policies? = action_type == 'APPLY_SCP_POLICY'
          def affects_resource_state? = action_type == 'RUN_SSM_DOCUMENTS'
          def requires_manual_approval? = approval_model == 'MANUAL'
          def is_automatic? = approval_model == 'AUTOMATIC'
          def subscriber_count = subscribers&.length || 0
          def has_email_notifications? = subscribers&.any? { |s| s[:subscription_type] == 'EMAIL' } || false
          def has_sns_notifications? = subscribers&.any? { |s| s[:subscription_type] == 'SNS' } || false

          def target_count
            return 0 unless definition
            if definition[:iam_action_definition]
              iam_def = definition[:iam_action_definition]
              (iam_def[:roles]&.size || 0) + (iam_def[:groups]&.size || 0) + (iam_def[:users]&.size || 0)
            elsif definition[:scp_action_definition]
              definition[:scp_action_definition][:target_ids].size
            elsif definition[:ssm_action_definition]
              definition[:ssm_action_definition][:instance_ids]&.size || 0
            else
              0
            end
          end

          def automation_risk_score
            score = is_automatic? ? 30 : 0
            score += { 'APPLY_IAM_POLICY' => 25, 'APPLY_SCP_POLICY' => 40, 'RUN_SSM_DOCUMENTS' => 35 }[action_type] || 0
            score += 10 if action_threshold_type == 'PERCENTAGE' && action_threshold < 90
            score -= 5 if action_threshold_type == 'PERCENTAGE' && action_threshold > 120
            score += [target_count * 2, 20].min
            score -= 10 if subscriber_count.positive?
            score -= 5 if requires_manual_approval?
            [score, 100].min
          end

          def risk_level
            score = automation_risk_score
            return 'CRITICAL' if score >= 80
            return 'HIGH' if score >= 60
            return 'MEDIUM' if score >= 40
            score >= 20 ? 'LOW' : 'MINIMAL'
          end

          def governance_compliance_score
            score = 20
            score += 25 if requires_manual_approval? && %w[APPLY_SCP_POLICY RUN_SSM_DOCUMENTS].include?(action_type)
            score += 15 if has_email_notifications?
            score += 10 if has_sns_notifications?
            score += 15 if action_threshold_type == 'PERCENTAGE' && action_threshold >= 90 && action_threshold <= 120
            score -= 10 if action_threshold_type == 'PERCENTAGE' && action_threshold < 80
            score -= 20 if automation_risk_score > 70 && !has_email_notifications?
            [score, 100].min
          end
        end
      end
    end
  end
end
