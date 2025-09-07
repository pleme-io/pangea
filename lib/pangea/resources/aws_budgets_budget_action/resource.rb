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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_budgets_budget_action/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      # Create an AWS Budgets Budget Action for automated cost control responses
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Budget action configuration attributes
      # @return [ResourceReference] Reference object with outputs and automation insights
      def aws_budgets_budget_action(name, attributes = {})
        # Validate attributes using dry-struct with comprehensive automation validation
        action_attrs = Types::BudgetActionAttributes.new(attributes)
        
        # Generate terraform resource block via terraform-synthesizer
        resource(:aws_budgets_budget_action, name) do
          budget_name action_attrs.budget_name
          action_type action_attrs.action_type
          approval_model action_attrs.approval_model
          notification_type action_attrs.notification_type
          
          # Action threshold configuration
          action_threshold do
            action_threshold action_attrs.action_threshold
            action_threshold_type action_attrs.action_threshold_type
          end
          
          # Action definition based on type
          if action_attrs.definition[:iam_action_definition]
            iam_def = action_attrs.definition[:iam_action_definition]
            
            definition do
              iam_action_definition do
                policy_arn iam_def[:policy_arn]
                
                # IAM roles to apply policy to
                if iam_def[:roles]
                  iam_def[:roles].each_with_index do |role_arn, index|
                    role index do
                      arn role_arn
                    end
                  end
                end
                
                # IAM groups to apply policy to
                if iam_def[:groups]
                  iam_def[:groups].each_with_index do |group_arn, index|
                    group index do
                      arn group_arn
                    end
                  end
                end
                
                # IAM users to apply policy to
                if iam_def[:users]
                  iam_def[:users].each_with_index do |user_arn, index|
                    user index do
                      arn user_arn
                    end
                  end
                end
              end
            end
            
          elsif action_attrs.definition[:scp_action_definition]
            scp_def = action_attrs.definition[:scp_action_definition]
            
            definition do
              scp_action_definition do
                policy_id scp_def[:policy_id]
                
                # Organization targets for SCP
                scp_def[:target_ids].each_with_index do |target_id, index|
                  target index do
                    target_id target_id
                  end
                end
              end
            end
            
          elsif action_attrs.definition[:ssm_action_definition]
            ssm_def = action_attrs.definition[:ssm_action_definition]
            
            definition do
              ssm_action_definition do
                action_type ssm_def[:ssm_action_type]
                region ssm_def[:region]
                
                # Instance IDs for SSM action
                if ssm_def[:instance_ids]
                  ssm_def[:instance_ids].each_with_index do |instance_id, index|
                    instance index do
                      instance_id instance_id
                    end
                  end
                end
                
                # SSM parameters
                if ssm_def[:parameters]
                  ssm_def[:parameters].each_with_index do |parameter, index|
                    parameter index do
                      name parameter[:name]
                      value parameter[:value]
                    end
                  end
                end
              end
            end
          end
          
          # Execution role for performing the action
          execution_role_arn action_attrs.execution_role_arn
          
          # Notification subscribers
          if action_attrs.subscribers
            action_attrs.subscribers.each_with_index do |subscriber, index|
              subscriber index do
                address subscriber[:address]
                subscription_type subscriber[:subscription_type]
              end
            end
          end
          
          # Apply tags for resource organization
          if action_attrs.tags&.any?
            tags do
              action_attrs.tags.each do |key, value|
                public_send(key, value)
              end
            end
          end
        end
        
        # Return resource reference with comprehensive automation insights
        ResourceReference.new(
          type: 'aws_budgets_budget_action',
          name: name,
          resource_attributes: action_attrs.to_h,
          outputs: {
            # Core action identifiers
            action_id: "${aws_budgets_budget_action.#{name}.action_id}",
            budget_name: "${aws_budgets_budget_action.#{name}.budget_name}",
            action_type: "${aws_budgets_budget_action.#{name}.action_type}",
            status: "${aws_budgets_budget_action.#{name}.status}",
            
            # Action configuration
            approval_model: "${aws_budgets_budget_action.#{name}.approval_model}",
            notification_type: "${aws_budgets_budget_action.#{name}.notification_type}",
            action_threshold: "${aws_budgets_budget_action.#{name}.action_threshold.action_threshold}",
            action_threshold_type: "${aws_budgets_budget_action.#{name}.action_threshold.action_threshold_type}",
            execution_role_arn: "${aws_budgets_budget_action.#{name}.execution_role_arn}",
            
            # Computed automation insights
            is_preventive_action: action_attrs.is_preventive_action?,
            is_reactive_action: action_attrs.is_reactive_action?,
            affects_iam_permissions: action_attrs.affects_iam_permissions?,
            affects_organization_policies: action_attrs.affects_organization_policies?,
            affects_resource_state: action_attrs.affects_resource_state?,
            
            # Approval and automation characteristics
            requires_manual_approval: action_attrs.requires_manual_approval?,
            is_automatic: action_attrs.is_automatic?,
            
            # Target and notification metrics
            target_count: action_attrs.target_count,
            subscriber_count: action_attrs.subscriber_count,
            has_email_notifications: action_attrs.has_email_notifications?,
            has_sns_notifications: action_attrs.has_sns_notifications?,
            
            # Risk and compliance assessments
            automation_risk_score: action_attrs.automation_risk_score,
            risk_level: action_attrs.risk_level,
            governance_compliance_score: action_attrs.governance_compliance_score
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)