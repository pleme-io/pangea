# frozen_string_literal: true

require 'pangea/resources/aws/ssm/maintenance_window_task'
require 'pangea/resources/aws/ssm/maintenance_window_target'
require 'pangea/resources/aws/ssm/ops_item'
require 'pangea/resources/aws/ssm/ops_metadata'
require 'pangea/resources/aws/ssm/resource_compliance_item'
require 'pangea/resources/aws/ssm/compliance_item'
require 'pangea/resources/aws/ssm/inventory_result_entity'
require 'pangea/resources/aws/ssm/session_preferences'
require 'pangea/resources/aws/ssm/session_manager_preferences'
require 'pangea/resources/aws/ssm/patch_manager_patch_baseline_approval_rule'
require 'pangea/resources/aws/ssm/automation_execution'
require 'pangea/resources/aws/ssm/command_invocation'

module Pangea
  module Resources
    module AWS
      # AWS Systems Manager Extended resources module
      # Advanced SSM resources for operations management, compliance tracking,
      # session management, patch management, and automation workflows.
      module SSM
        include MaintenanceWindowTask
        include MaintenanceWindowTarget
        include OpsItem
        include OpsMetadata
        include ResourceComplianceItem
        include ComplianceItem
        include InventoryResultEntity
        include SessionPreferences
        include SessionManagerPreferences
        include PatchManagerPatchBaselineApprovalRule
        include AutomationExecution
        include CommandInvocation
      end
    end
  end
end