# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Resources
    module AWS
      module Types
        BudgetActionType = String.enum('APPLY_IAM_POLICY', 'APPLY_SCP_POLICY', 'RUN_SSM_DOCUMENTS')
        BudgetActionStatus = String.enum('STANDBY', 'PENDING', 'EXECUTION_IN_PROGRESS', 'EXECUTION_SUCCESS', 'EXECUTION_FAILURE', 'REVERSE_IN_PROGRESS', 'REVERSE_SUCCESS', 'REVERSE_FAILURE', 'RESET')
        ActionNotificationType = String.enum('ACTUAL', 'FORECASTED')
        BudgetActionApprovalModel = String.enum('AUTOMATIC', 'MANUAL')

        ActionSubscriber = Hash.schema(
          subscription_type: String.enum('EMAIL', 'SNS'),
          address: String
        )

        BudgetIamPolicyDefinition = Hash.schema(
          policy_arn: String,
          roles?: Array.of(String).optional,
          groups?: Array.of(String).optional,
          users?: Array.of(String).optional
        )

        BudgetScpPolicyDefinition = Hash.schema(
          policy_id: String,
          target_ids: Array.of(String).constrained(min_size: 1, max_size: 20)
        )

        BudgetSsmParameter = Hash.schema(
          name: String.constrained(format: /\A[a-zA-Z0-9_.-]{1,128}\z/),
          value: String.constrained(max_size: 4096)
        )

        BudgetSsmDocumentDefinition = Hash.schema(
          ssm_action_type: String.enum('START_EC2_INSTANCES', 'STOP_EC2_INSTANCES', 'START_RDS_INSTANCES', 'STOP_RDS_INSTANCES'),
          region: AwsRegion,
          instance_ids?: Array.of(String).constrained(max_size: 50).optional,
          parameters?: Array.of(BudgetSsmParameter).constrained(max_size: 100).optional
        )

        BudgetActionDefinition = Hash.schema(
          iam_action_definition?: BudgetIamPolicyDefinition.optional,
          scp_action_definition?: BudgetScpPolicyDefinition.optional,
          ssm_action_definition?: BudgetSsmDocumentDefinition.optional
        )

        BudgetActionExecutionRole = String.constrained(format: /\Aarn:aws:iam::\d{12}:role\/[a-zA-Z0-9+=,.@_-]+\z/)
      end
    end
  end
end
