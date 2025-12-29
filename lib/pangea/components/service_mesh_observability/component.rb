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
require 'pangea/components/service_mesh_observability/types'
require 'pangea/components/service_mesh_observability/xray'
require 'pangea/components/service_mesh_observability/logging'
require 'pangea/components/service_mesh_observability/alerting'
require 'pangea/components/service_mesh_observability/dashboard'
require 'pangea/components/service_mesh_observability/anomaly'
require 'pangea/components/service_mesh_observability/helpers'
require 'pangea/resources/aws'

module Pangea
  module Components
    # Comprehensive observability stack for distributed microservices with tracing, metrics, and service maps
    # Creates X-Ray tracing, CloudWatch dashboards, alarms, and service visualization
    def service_mesh_observability(name, attributes = {})
      include Base
      include Resources::AWS
      include ServiceMeshObservability::Xray
      include ServiceMeshObservability::Logging
      include ServiceMeshObservability::Alerting
      include ServiceMeshObservability::Dashboard
      include ServiceMeshObservability::Anomaly
      include ServiceMeshObservability::Helpers

      component_attrs = ServiceMeshObservability::ServiceMeshObservabilityAttributes.new(attributes)
      component_attrs.validate!

      component_tag_set = component_tags('ServiceMeshObservability', name, component_attrs.tags)
      resources = {}

      # X-Ray configuration
      xray_encryption = create_xray_encryption(name, component_attrs, component_tag_set)
      resources[:xray_encryption] = xray_encryption if xray_encryption
      resources[:sampling_rules] = create_sampling_rules(name, component_attrs, component_tag_set)
      resources[:xray_group] = create_xray_group(name, component_attrs, component_tag_set)

      # Logging
      log_groups = create_log_groups(name, component_attrs, component_tag_set)
      resources[:log_groups] = log_groups unless log_groups.empty?
      metric_filters = create_metric_filters(name, component_attrs, log_groups)
      resources[:metric_filters] = metric_filters unless metric_filters.empty?

      # Alerting
      alert_topic = create_alert_topic(name, component_attrs, component_tag_set)
      resources[:alert_topic] = alert_topic if alert_topic

      notification_arn = component_attrs.alerting.notification_channel_ref&.arn ||
                         (resources[:alert_topic]&.arn if component_attrs.alerting.enabled)

      alarms = create_service_alarms(name, component_attrs, notification_arn, component_tag_set)
      resources[:alarms] = alarms

      # Dashboard
      resources[:dashboard] = create_dashboard(name, component_attrs)

      # Insights and Anomaly Detection
      insights_queries = create_insights_queries(name, component_attrs, log_groups)
      resources[:insights_queries] = insights_queries unless insights_queries.empty?

      configure_container_insights(name, component_attrs)

      anomaly_detectors = create_anomaly_detectors(name, component_attrs)
      resources[:anomaly_detectors] = anomaly_detectors unless anomaly_detectors.empty?

      # Build outputs
      outputs = build_observability_outputs(component_attrs, resources, alarms)

      create_component_reference(
        'service_mesh_observability',
        name,
        component_attrs.to_h,
        resources,
        outputs
      )
    end
  end
end
