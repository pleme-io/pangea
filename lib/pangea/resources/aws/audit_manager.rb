# frozen_string_literal: true

require_relative 'audit_manager/assessment'
require_relative 'audit_manager/assessment_report'
require_relative 'audit_manager/control'
require_relative 'audit_manager/framework'
require_relative 'audit_manager/assessment_delegation'
require_relative 'audit_manager/organization_admin_account'
require_relative 'audit_manager/account_registration'
require_relative 'audit_manager/framework_share'
require_relative 'audit_manager/evidence_folder'
require_relative 'audit_manager/assessment_control_set'

module Pangea
  module Resources
    module AWS
      # AWS Audit Manager service module
      # Provides type-safe resource functions for compliance assessment and audit management
      module AuditManager
        # Creates an Audit Manager assessment for compliance validation
        #
        # @param name [Symbol] Unique name for the assessment resource
        # @param attributes [Hash] Configuration attributes for the assessment
        # @return [AuditManager::Assessment::AssessmentReference] Reference to the created assessment
        def aws_auditmanager_assessment(name, attributes = {})
          resource = AuditManager::Assessment.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AuditManager::Assessment::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Generates an assessment report for compliance documentation
        #
        # @param name [Symbol] Unique name for the assessment report resource
        # @param attributes [Hash] Configuration attributes for the report
        # @return [AuditManager::AssessmentReport::AssessmentReportReference] Reference to the created report
        def aws_auditmanager_assessment_report(name, attributes = {})
          resource = AuditManager::AssessmentReport.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AuditManager::AssessmentReport::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an Audit Manager control for compliance requirements
        #
        # @param name [Symbol] Unique name for the control resource
        # @param attributes [Hash] Configuration attributes for the control
        # @return [AuditManager::Control::ControlReference] Reference to the created control
        def aws_auditmanager_control(name, attributes = {})
          resource = AuditManager::Control.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AuditManager::Control::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an Audit Manager framework for grouping compliance controls
        #
        # @param name [Symbol] Unique name for the framework resource
        # @param attributes [Hash] Configuration attributes for the framework
        # @return [AuditManager::Framework::FrameworkReference] Reference to the created framework
        def aws_auditmanager_framework(name, attributes = {})
          resource = AuditManager::Framework.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AuditManager::Framework::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Delegates assessment controls to specific users or roles
        #
        # @param name [Symbol] Unique name for the assessment delegation resource
        # @param attributes [Hash] Configuration attributes for the delegation
        # @return [AuditManager::AssessmentDelegation::AssessmentDelegationReference] Reference to the created delegation
        def aws_auditmanager_assessment_delegation(name, attributes = {})
          resource = AuditManager::AssessmentDelegation.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AuditManager::AssessmentDelegation::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Designates an Audit Manager administrator account for AWS Organizations
        #
        # @param name [Symbol] Unique name for the organization admin account resource
        # @param attributes [Hash] Configuration attributes for the admin account
        # @return [AuditManager::OrganizationAdminAccount::OrganizationAdminAccountReference] Reference to the created admin account
        def aws_auditmanager_organization_admin_account(name, attributes = {})
          resource = AuditManager::OrganizationAdminAccount.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AuditManager::OrganizationAdminAccount::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Registers an AWS account to enable Audit Manager functionality
        #
        # @param name [Symbol] Unique name for the account registration resource
        # @param attributes [Hash] Configuration attributes for the registration
        # @return [AuditManager::AccountRegistration::AccountRegistrationReference] Reference to the created registration
        def aws_auditmanager_account_registration(name, attributes = {})
          resource = AuditManager::AccountRegistration.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AuditManager::AccountRegistration::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Shares a custom framework with other AWS accounts
        #
        # @param name [Symbol] Unique name for the framework share resource
        # @param attributes [Hash] Configuration attributes for the share
        # @return [AuditManager::FrameworkShare::FrameworkShareReference] Reference to the created share
        def aws_auditmanager_framework_share(name, attributes = {})
          resource = AuditManager::FrameworkShare.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AuditManager::FrameworkShare::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an evidence folder for organizing audit evidence
        #
        # @param name [Symbol] Unique name for the evidence folder resource
        # @param attributes [Hash] Configuration attributes for the evidence folder
        # @return [AuditManager::EvidenceFolder::EvidenceFolderReference] Reference to the created folder
        def aws_auditmanager_evidence_folder(name, attributes = {})
          resource = AuditManager::EvidenceFolder.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AuditManager::EvidenceFolder::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Manages control sets within assessments
        #
        # @param name [Symbol] Unique name for the assessment control set resource
        # @param attributes [Hash] Configuration attributes for the control set
        # @return [AuditManager::AssessmentControlSet::AssessmentControlSetReference] Reference to the created control set
        def aws_auditmanager_assessment_control_set(name, attributes = {})
          resource = AuditManager::AssessmentControlSet.new(
            name: name,
            synthesizer: synthesizer,
            attributes: AuditManager::AssessmentControlSet::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end