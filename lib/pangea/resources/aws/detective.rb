# frozen_string_literal: true

require_relative 'detective/graph'
require_relative 'detective/member'
require_relative 'detective/invitation_accepter'
require_relative 'detective/organization_admin_account'
require_relative 'detective/organization_configuration'
require_relative 'detective/datasource_package'
require_relative 'detective/finding'
require_relative 'detective/indicator'

module Pangea
  module Resources
    module AWS
      # AWS Detective service module
      # Provides type-safe resource functions for Detective security investigation services
      module Detective
        # Creates a Detective behavior graph for security analysis
        #
        # @param name [Symbol] Unique name for the graph resource
        # @param attributes [Hash] Configuration attributes for the graph
        # @return [Detective::Graph::GraphReference] Reference to the created graph
        def aws_detective_graph(name, attributes = {})
          resource = Detective::Graph.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Detective::Graph::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Adds a member account to a Detective behavior graph
        #
        # @param name [Symbol] Unique name for the member resource
        # @param attributes [Hash] Configuration attributes for the member
        # @return [Detective::Member::MemberReference] Reference to the created member
        def aws_detective_member(name, attributes = {})
          resource = Detective::Member.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Detective::Member::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Accepts an invitation to join a Detective behavior graph
        #
        # @param name [Symbol] Unique name for the invitation accepter resource
        # @param attributes [Hash] Configuration attributes for the invitation accepter
        # @return [Detective::InvitationAccepter::InvitationAccepterReference] Reference to the created accepter
        def aws_detective_invitation_accepter(name, attributes = {})
          resource = Detective::InvitationAccepter.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Detective::InvitationAccepter::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Designates a Detective administrator account for AWS Organizations
        #
        # @param name [Symbol] Unique name for the organization admin account resource
        # @param attributes [Hash] Configuration attributes for the admin account
        # @return [Detective::OrganizationAdminAccount::OrganizationAdminAccountReference] Reference to the created admin account
        def aws_detective_organization_admin_account(name, attributes = {})
          resource = Detective::OrganizationAdminAccount.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Detective::OrganizationAdminAccount::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Configures Detective settings for AWS Organizations
        #
        # @param name [Symbol] Unique name for the organization configuration resource
        # @param attributes [Hash] Configuration attributes for the organization settings
        # @return [Detective::OrganizationConfiguration::OrganizationConfigurationReference] Reference to the created configuration
        def aws_detective_organization_configuration(name, attributes = {})
          resource = Detective::OrganizationConfiguration.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Detective::OrganizationConfiguration::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Manages datasource packages for Detective behavior graphs
        #
        # @param name [Symbol] Unique name for the datasource package resource
        # @param attributes [Hash] Configuration attributes for the datasource package
        # @return [Detective::DatasourcePackage::DatasourcePackageReference] Reference to the created package
        def aws_detective_datasource_package(name, attributes = {})
          resource = Detective::DatasourcePackage.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Detective::DatasourcePackage::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a security finding in Detective behavior graph
        #
        # @param name [Symbol] Unique name for the finding resource
        # @param attributes [Hash] Configuration attributes for the finding
        # @return [Detective::Finding::FindingReference] Reference to the created finding
        def aws_detective_finding(name, attributes = {})
          resource = Detective::Finding.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Detective::Finding::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates a threat indicator in Detective behavior graph
        #
        # @param name [Symbol] Unique name for the indicator resource
        # @param attributes [Hash] Configuration attributes for the indicator
        # @return [Detective::Indicator::IndicatorReference] Reference to the created indicator
        def aws_detective_indicator(name, attributes = {})
          resource = Detective::Indicator.new(
            name: name,
            synthesizer: synthesizer,
            attributes: Detective::Indicator::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end