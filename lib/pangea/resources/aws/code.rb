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


require 'pangea/resources/aws/code/codecommit_approval_rule_template'
require 'pangea/resources/aws/code/codecommit_approval_rule_template_association'
require 'pangea/resources/aws/code/codebuild_project_cache'
require 'pangea/resources/aws/code/codebuild_project_file_system_location'
require 'pangea/resources/aws/code/codebuild_source_credential'
require 'pangea/resources/aws/code/codebuild_webhook_filter'
require 'pangea/resources/aws/code/codedeploy_deployment_config'
require 'pangea/resources/aws/code/codedeploy_deployment_group_auto_rollback'
require 'pangea/resources/aws/code/codepipeline_custom_action_type'
require 'pangea/resources/aws/code/codepipeline_webhook'
require 'pangea/resources/aws/code/codestar_connection'
require 'pangea/resources/aws/code/codestar_notification_rule'

module Pangea
  module Resources
    module AWS
      # AWS Code Suite Extended resources module
      # Advanced CodeCommit, CodeBuild, CodeDeploy, CodePipeline, and CodeStar resources
      # for enterprise DevOps workflows and automation.
      module Code
        include CodecommitApprovalRuleTemplate
        include CodecommitApprovalRuleTemplateAssociation
        include CodebuildProjectCache
        include CodebuildProjectFileSystemLocation
        include CodebuildSourceCredential
        include CodebuildWebhookFilter
        include CodedeployDeploymentConfig
        include CodedeployDeploymentGroupAutoRollback
        include CodepipelineCustomActionType
        include CodepipelineWebhook
        include CodestarConnection
        include CodestarNotificationRule
      end
    end
  end
end