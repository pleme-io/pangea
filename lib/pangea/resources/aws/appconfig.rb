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