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

require_relative 'core'

module Pangea
  module Resources
    module Types
      # GuardDuty types
      GuardDutyFindingPublishingFrequency = String.enum('FIFTEEN_MINUTES', 'ONE_HOUR', 'SIX_HOURS')
      GuardDutyDetectorStatus = String.enum('ENABLED', 'DISABLED')
      GuardDutyDataSourceStatus = String.enum('ENABLED', 'DISABLED')
      GuardDutyThreatIntelSetFormat = String.enum('TXT', 'STIX', 'OTX_CSV', 'ALIEN_VAULT', 'PROOF_POINT', 'FIRE_EYE')
      GuardDutyIpSetFormat = String.enum('TXT', 'STIX', 'OTX_CSV', 'ALIEN_VAULT', 'PROOF_POINT', 'FIRE_EYE')
      GuardDutyMemberStatus = String.enum('CREATED', 'INVITED', 'DISABLED', 'ENABLED', 'REMOVED', 'RESIGNED')
      GuardDutyDetectorArn = String.constrained(format: /\Aarn:aws:guardduty:[a-z0-9-]+:\d{12}:detector\/[a-f0-9]{32}\z/)

      GuardDutyInvitationEmail = String.constrained(format: /\A[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/).constructor { |value|
        if value.length > 320
          raise Dry::Types::ConstraintError, "Email address cannot exceed 320 characters"
        end
        value
      }

      # Inspector v2 types
      InspectorV2ResourceType = String.enum('ECR', 'EC2')
      InspectorV2ScanType = String.enum('NETWORK', 'PACKAGE')
      InspectorV2ScanStatus = String.enum('ENABLED', 'DISABLED', 'SUSPENDED')

      # Security Hub types
      SecurityHubStandardsArn = String.constrained(format: /\Aarn:aws:securityhub:[a-z0-9-]+::\w+\/\w+\/\w+\z/)
      SecurityHubControlStatus = String.enum('ENABLED', 'DISABLED')
      SecurityHubComplianceStatus = String.enum('PASSED', 'WARNING', 'FAILED', 'NOT_AVAILABLE')
      SecurityHubSeverity = String.enum('INFORMATIONAL', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
      SecurityHubRecordState = String.enum('ACTIVE', 'ARCHIVED')
      SecurityHubWorkflowStatus = String.enum('NEW', 'NOTIFIED', 'RESOLVED', 'SUPPRESSED')
      SecurityHubArn = String.constrained(format: /\Aarn:aws:securityhub:[a-z0-9-]+:\d{12}:hub\/default\z/)
    end
  end
end
