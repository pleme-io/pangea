# frozen_string_literal: true
# Copyright 2025 The Pangea Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Budget action types for automated responses
        BudgetActionType = String.enum('APPLY_IAM_POLICY', 'APPLY_SCP_POLICY', 'RUN_SSM_DOCUMENTS')
        
        # Budget action status
        BudgetActionStatus = String.enum('STANDBY', 'PENDING', 'EXECUTION_IN_PROGRESS', 'EXECUTION_SUCCESS', 'EXECUTION_FAILURE', 'REVERSE_IN_PROGRESS', 'REVERSE_SUCCESS', 'REVERSE_FAILURE', 'RESET')
        
        # Budget action notification type (reuse from budget types)
        ActionNotificationType = String.enum('ACTUAL', 'FORECASTED')
        
        # Budget action subscriber (reuse from budget types)  
        ActionSubscriber = Hash.schema(
          subscription_type: String.enum('EMAIL', 'SNS'),
          address: String.constructor { |value, context|
            protocol = context[:subscription_type] rescue nil
            
            case protocol
            when 'EMAIL'
              unless value.match?(/\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)
                raise Dry::Types::ConstraintError, "Email address format is invalid"
              end
            when 'SNS'
              unless value.match?(/\Aarn:aws:sns:[a-z0-9-]+:\d{12}:[a-zA-Z0-9-_]+\z/)
                raise Dry::Types::ConstraintError, "SNS topic ARN format is invalid"
              end
            end
            
            value
          }
        )
        
        # IAM policy definition for budget actions
        BudgetIamPolicyDefinition = Hash.schema(
          policy_arn: String.constrained(format: /\Aarn:aws:iam::(\*|\d{12}):policy\/[a-zA-Z0-9+=,.@_-]+\z/).constructor { |value|
            # Validate IAM policy ARN format
            unless value.match?(/\Aarn:aws:iam::(\*|\d{12}):policy\/[a-zA-Z0-9+=,.@_-]+\z/)
              raise Dry::Types::ConstraintError, "Invalid IAM policy ARN format"
            end
            value
          },
          roles?: Array.of(String.constrained(format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9+=,.@_-]+\z/)).constrained(max_size: 100).optional,
          groups?: Array.of(String.constrained(format: /\Aarn:aws:iam::\d{12}:group\/[a-zA-Z0-9+=,.@_-]+\z/)).constrained(max_size: 100).optional,
          users?: Array.of(String.constrained(format: /\Aarn:aws:iam::\d{12}:user\/[a-zA-Z0-9+=,.@_-]+\z/)).constrained(max_size: 100).optional
        ).constructor { |value|
          # Must specify at least one target (roles, groups, or users)
          if !value[:roles] && !value[:groups] && !value[:users]
            raise Dry::Types::ConstraintError, "IAM policy action must specify at least one target (roles, groups, or users)"
          end
          
          # Validate total targets don't exceed AWS limits
          total_targets = (value[:roles]&.size || 0) + (value[:groups]&.size || 0) + (value[:users]&.size || 0)
          if total_targets > 100
            raise Dry::Types::ConstraintError, "Total IAM targets cannot exceed 100"
          end
          
          value
        end
        
        # Service Control Policy definition for budget actions
        BudgetScpPolicyDefinition = Hash.schema(
          policy_id: String.constrained(format: /\Ap-[0-9a-z]{8,128}\z/).constructor { |value|
            # Validate SCP policy ID format
            unless value.match?(/\Ap-[0-9a-z]{8,128}\z/)
              raise Dry::Types::ConstraintError, "Invalid SCP policy ID format"
            end
            value
          },
          target_ids: Array.of(String).constrained(min_size: 1, max_size: 20).constructor { |values|
            # Validate target IDs (can be account IDs, OU IDs, or root IDs)
            values.each do |target_id|
              unless target_id.match?(/\A(r-[0-9a-z]{4,32}|ou-[0-9a-z]{8,32}-[0-9a-z]{8,32}|\d{12})\z/)
                raise Dry::Types::ConstraintError, "Invalid SCP target ID format: #{target_id}"
              end
            end
            values
          }
        )
        
        # SSM document parameter
        BudgetSsmParameter = Hash.schema(
          name: String.constrained(format: /\A[a-zA-Z0-9_.-]{1,128}\z/),
          value: String.constrained(max_size: 4096)
        )
        
        # SSM document definition for budget actions
        BudgetSsmDocumentDefinition = Hash.schema(
          ssm_action_type: String.enum('START_EC2_INSTANCES', 'STOP_EC2_INSTANCES', 'START_RDS_INSTANCES', 'STOP_RDS_INSTANCES'),
          region: AwsRegion,
          instance_ids?: Array.of(String).constrained(max_size: 50).optional,
          parameters?: Array.of(BudgetSsmParameter).constrained(max_size: 100).optional
        ).constructor { |value|
          # Validate instance IDs based on action type
          if ['START_EC2_INSTANCES', 'STOP_EC2_INSTANCES'].include?(value[:ssm_action_type])
            if value[:instance_ids]
              value[:instance_ids].each do |instance_id|
                unless instance_id.match?(/\Ai-[0-9a-f]{8,17}\z/)
                  raise Dry::Types::ConstraintError, "Invalid EC2 instance ID format: #{instance_id}"
                end
              end
            end
          elsif ['START_RDS_INSTANCES', 'STOP_RDS_INSTANCES'].include?(value[:ssm_action_type])
            if value[:instance_ids]
              value[:instance_ids].each do |instance_id|
                unless instance_id.match?(/\A[a-zA-Z0-9-]{1,63}\z/)
                  raise Dry::Types::ConstraintError, "Invalid RDS instance ID format: #{instance_id}"
                end
              end
            end
          end
          
          value
        end
        
        # Budget action definition union type
        BudgetActionDefinition = Hash.schema(
          iam_action_definition?: BudgetIamPolicyDefinition.optional,
          scp_action_definition?: BudgetScpPolicyDefinition.optional,
          ssm_action_definition?: BudgetSsmDocumentDefinition.optional
        ).constructor { |value|
          # Must specify exactly one action definition type
          definition_count = [value[:iam_action_definition], value[:scp_action_definition], value[:ssm_action_definition]].compact.size
          
          if definition_count == 0
            raise Dry::Types::ConstraintError, "Must specify exactly one action definition (IAM, SCP, or SSM)"
          end
          
          if definition_count > 1
            raise Dry::Types::ConstraintError, "Can only specify one action definition type per budget action"
          end
          
          value
        end
        
        # Budget action execution role validation
        BudgetActionExecutionRole = String.constrained(format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9+=,.@_-]+\z/).constructor { |value|
          # Validate execution role has proper permissions for action type
          unless value.match?(/\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9+=,.@_-]+\z/)
            raise Dry::Types::ConstraintError, "Invalid execution role ARN format"
          end
          
          # Role name should indicate budget action permissions
          role_name = value.split('/').last
          unless role_name.include?('Budget') || role_name.include?('Cost') || role_name.downcase.include?('budget') || role_name.downcase.include?('cost')
            # This is a warning, not an error - but good practice
          end
          
          value
        end
        
        # Budget action approval model
        BudgetActionApprovalModel = String.enum('AUTOMATIC', 'MANUAL').constructor { |value|
          # AUTOMATIC actions should be used carefully with appropriate thresholds
          if value == 'AUTOMATIC'
            # This is handled in the main attributes validation
          end
          value
        end
        
        # Budget action threshold configuration
        BudgetActionThreshold = Hash.schema(
          action_threshold: Numeric.constructor { |value|
            if value <= 0
              raise Dry::Types::ConstraintError, "Action threshold must be positive"
            end
            if value > 1000000
              raise Dry::Types::ConstraintError, "Action threshold cannot exceed 1,000,000"
            end
            value
          },
          action_threshold_type: String.enum('PERCENTAGE', 'ABSOLUTE_VALUE').default('PERCENTAGE')
        )
        
        # Budget action resource attributes with comprehensive validation
        class BudgetActionAttributes < Dry::Struct
          transform_keys(&:to_sym)
          
          attribute :budget_name, String.constrained(format: /\A[a-zA-Z0-9_\-. ]{1,100}\z/).constructor { |value|
            # Must match an existing budget name
            cleaned = value.strip
            if cleaned.empty?
              raise Dry::Struct::Error, "Budget name cannot be empty"
            end
            cleaned
          }
          
          attribute :action_type, BudgetActionType
          attribute :approval_model, BudgetActionApprovalModel
          attribute :notification_type, ActionNotificationType
          
          # Action threshold configuration
          attribute :action_threshold, Numeric.constructor { |value|
            if value <= 0
              raise Dry::Struct::Error, "Action threshold must be positive"
            end
            if value > 1000000
              raise Dry::Struct::Error, "Action threshold cannot exceed 1,000,000"
            end
            value
          }
          
          attribute :action_threshold_type, String.enum('PERCENTAGE', 'ABSOLUTE_VALUE').default('PERCENTAGE')
          
          # Action definition (exactly one must be specified)
          attribute :definition, BudgetActionDefinition
          
          # Execution role for performing the action
          attribute :execution_role_arn, BudgetActionExecutionRole
          
          # Optional attributes
          attribute :subscribers?, Array.of(ActionSubscriber).constrained(max_size: 11).optional
          attribute :tags?, AwsTags.optional
          
          # Custom validation for action type and definition alignment
          def self.new(attributes)
            attrs = attributes.is_a?(Hash) ? attributes : {}
            
            # Validate action type matches definition type
            if attrs[:action_type] && attrs[:definition]
              definition = attrs[:definition]
              action_type = attrs[:action_type]
              
              case action_type
              when 'APPLY_IAM_POLICY'
                unless definition[:iam_action_definition]
                  raise Dry::Struct::Error, "IAM policy action type requires iam_action_definition"
                end
              when 'APPLY_SCP_POLICY'
                unless definition[:scp_action_definition]
                  raise Dry::Struct::Error, "SCP policy action type requires scp_action_definition"
                end
              when 'RUN_SSM_DOCUMENTS'
                unless definition[:ssm_action_definition]
                  raise Dry::Struct::Error, "SSM document action type requires ssm_action_definition"
                end
              end
            end
            
            # Validate automatic approval thresholds are reasonable
            if attrs[:approval_model] == 'AUTOMATIC'
              threshold = attrs[:action_threshold]
              threshold_type = attrs[:action_threshold_type] || 'PERCENTAGE'
              
              if threshold_type == 'PERCENTAGE'
                if threshold < 80
                  # Warning: Low threshold for automatic actions could be risky
                  # This is more of a best practice warning than a hard error
                end
                if threshold > 150
                  raise Dry::Struct::Error, "Automatic actions with thresholds over 150% may cause issues"
                end
              end
            end
            
            super(attrs)
          end
          
          # Computed properties for action analysis
          def is_preventive_action?
            action_type == 'APPLY_IAM_POLICY' || action_type == 'APPLY_SCP_POLICY'
          end
          
          def is_reactive_action?
            action_type == 'RUN_SSM_DOCUMENTS'
          end
          
          def affects_iam_permissions?
            action_type == 'APPLY_IAM_POLICY'
          end
          
          def affects_organization_policies?
            action_type == 'APPLY_SCP_POLICY'
          end
          
          def affects_resource_state?
            action_type == 'RUN_SSM_DOCUMENTS'
          end
          
          def requires_manual_approval?
            approval_model == 'MANUAL'
          end
          
          def is_automatic?
            approval_model == 'AUTOMATIC'
          end
          
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
          
          def subscriber_count
            subscribers&.length || 0
          end
          
          def has_email_notifications?
            return false unless subscribers
            subscribers.any? { |s| s[:subscription_type] == 'EMAIL' }
          end
          
          def has_sns_notifications?
            return false unless subscribers
            subscribers.any? { |s| s[:subscription_type] == 'SNS' }
          end
          
          # Risk assessment for automated actions
          def automation_risk_score
            score = 0
            
            # Base risk for automatic actions
            score += 30 if is_automatic?
            
            # Risk based on action type
            case action_type
            when 'APPLY_IAM_POLICY'
              score += 25  # Medium risk - can block access
            when 'APPLY_SCP_POLICY'
              score += 40  # High risk - affects entire organization
            when 'RUN_SSM_DOCUMENTS'
              score += 35  # Medium-high risk - can stop services
            end
            
            # Risk based on threshold
            if action_threshold_type == 'PERCENTAGE'
              score += 10 if action_threshold < 90   # Low threshold = higher risk
              score -= 5 if action_threshold > 120   # High threshold = lower risk
            end
            
            # Risk based on targets
            score += [target_count * 2, 20].min  # More targets = more risk (capped)
            
            # Risk mitigation factors
            score -= 10 if subscriber_count > 0    # Notifications reduce risk
            score -= 5 if requires_manual_approval?  # Manual approval reduces risk
            
            [score, 100].min
          end
          
          def risk_level
            risk_score = automation_risk_score
            
            if risk_score >= 80
              'CRITICAL'
            elsif risk_score >= 60
              'HIGH'
            elsif risk_score >= 40
              'MEDIUM'
            elsif risk_score >= 20
              'LOW'
            else
              'MINIMAL'
            end
          end
          
          # Governance compliance for budget actions
          def governance_compliance_score
            score = 0
            
            # Base points for having budget actions
            score += 20
            
            # Points for manual approval on high-risk actions
            if requires_manual_approval? && ['APPLY_SCP_POLICY', 'RUN_SSM_DOCUMENTS'].include?(action_type)
              score += 25
            end
            
            # Points for notifications
            score += 15 if has_email_notifications?
            score += 10 if has_sns_notifications?
            
            # Points for reasonable thresholds
            if action_threshold_type == 'PERCENTAGE'
              score += 15 if action_threshold >= 90 && action_threshold <= 120
              score -= 10 if action_threshold < 80  # Too aggressive
            end
            
            # Deduct points for high automation risk without safeguards
            score -= 20 if automation_risk_score > 70 && !has_email_notifications?
            
            [score, 100].min
          end
        end
      end
    end
  end
end