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

require_relative 'monitoring/dashboards'
require_relative 'monitoring/alarms'

module Pangea
  module Components
    module DisasterRecoveryPilotLight
      # Monitoring and alerting infrastructure
      module Monitoring
        include Dashboards
        include Alarms

        def create_monitoring_infrastructure(name, attrs, resources, tags)
          monitoring_resources = {}

          if attrs.monitoring.primary_region_monitoring
            monitoring_resources[:primary_dashboard] = create_region_dashboard(
              name, "primary", attrs.primary_region, resources[:primary], tags
            )
          end

          if attrs.monitoring.dr_region_monitoring
            monitoring_resources[:dr_dashboard] = create_region_dashboard(
              name, "dr", attrs.dr_region, resources[:dr], tags
            )
          end

          monitoring_resources[:replication_dashboard] = create_replication_dashboard(
            name, attrs, resources, tags
          )

          if attrs.monitoring.alerting_enabled
            create_alerting_resources(name, attrs, resources, monitoring_resources, tags)
          end

          monitoring_resources
        end
      end
    end
  end
end
