# frozen_string_literal: true

require 'pangea/resources/aws/appconfig/configuration_version'
require 'pangea/resources/aws/appconfig/deployment_strategy'
require 'pangea/resources/aws/appconfig/extension'
require 'pangea/resources/aws/appconfig/extension_association'
require 'pangea/resources/aws/appconfig/hosted_configuration_version'
require 'pangea/resources/aws/appconfig/monitor'
require 'pangea/resources/aws/appconfig/validator'

module Pangea
  module Resources
    module AWS
      # AWS AppConfig Extended resources module
      # Advanced application configuration management with deployment strategies,
      # extensions, monitoring, and validation capabilities.
      module AppConfig
        include ConfigurationVersion
        include DeploymentStrategy
        include Extension
        include ExtensionAssociation
        include HostedConfigurationVersion
        include Monitor
        include Validator
      end
    end
  end
end