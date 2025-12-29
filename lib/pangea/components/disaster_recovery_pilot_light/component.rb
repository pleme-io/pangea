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

require 'pangea/components/base'
require 'pangea/components/disaster_recovery_pilot_light/types'
require_relative 'modules/helpers'
require_relative 'modules/code_generators'
require_relative 'modules/primary_region'
require_relative 'modules/dr_region'
require_relative 'modules/networking'
require_relative 'modules/replication'
require_relative 'modules/backup'
require_relative 'modules/automation'
require_relative 'modules/testing'
require_relative 'modules/monitoring'
require_relative 'modules/compliance'

module Pangea
  module Components
    module DisasterRecoveryPilotLight
      include Helpers
      include CodeGenerators
      include PrimaryRegion
      include DrRegion
      include Networking
      include Replication
      include Backup
      include Automation
      include Testing
      include Monitoring
      include Compliance

      # Pilot light DR pattern with automated activation and validation
      # Creates minimal standby resources, automated testing, and rapid activation
      def disaster_recovery_pilot_light(name, attributes = {})
        attrs = DisasterRecoveryPilotLightAttributes.new(attributes)
        attrs.validate!

        component_tag_set = component_tags('DisasterRecoveryPilotLight', name, attrs.tags)
        resources = {}

        # Set up infrastructure in dependency order
        resources[:primary] = setup_primary_region(name, attrs, component_tag_set)
        resources[:dr] = setup_dr_region(name, attrs, component_tag_set)

        # Create cross-region networking if enabled
        if attrs.enable_cross_region_vpc_peering
          resources[:peering] = create_cross_region_peering(
            name, attrs, resources[:primary], resources[:dr], component_tag_set
          )
        end

        # Set up data replication
        resources[:replication] = setup_data_replication(
          name, attrs, resources[:primary], resources[:dr], component_tag_set
        )

        # Create backup and recovery infrastructure
        resources[:backup] = create_backup_infrastructure(
          name, attrs, resources[:primary], component_tag_set
        )

        # Create activation automation
        resources[:activation] = create_activation_automation(
          name, attrs, resources[:dr], component_tag_set
        )

        # Set up DR testing infrastructure
        if attrs.testing.automated_testing
          resources[:testing] = create_testing_infrastructure(
            name, attrs, resources, component_tag_set
          )
        end

        # Create monitoring and alerting
        if attrs.monitoring.dashboard_enabled || attrs.monitoring.alerting_enabled
          resources[:monitoring] = create_monitoring_infrastructure(
            name, attrs, resources, component_tag_set
          )
        end

        # Create compliance and audit resources
        if attrs.compliance.audit_logging
          resources[:compliance] = create_compliance_resources(
            name, attrs, resources, component_tag_set
          )
        end

        create_component_reference(
          'disaster_recovery_pilot_light',
          name,
          attrs.to_h,
          resources,
          build_outputs(name, attrs, resources)
        )
      end

      include Base
    end
  end
end
