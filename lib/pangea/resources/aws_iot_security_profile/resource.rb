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


require 'pangea/resources/base'
require 'pangea/resources/reference'
require 'pangea/resources/aws_iot_security_profile/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_iot_security_profile(name, attributes = {})
        profile_attrs = Types::IotSecurityProfileAttributes.new(attributes)
        
        resource(:aws_iot_security_profile, name) do
          security_profile_name profile_attrs.security_profile_name
          security_profile_description profile_attrs.security_profile_description if profile_attrs.security_profile_description
          
          profile_attrs.behaviors.each do |behavior|
            behaviors do
              name behavior[:name]
              metric behavior[:metric] if behavior[:metric]
              metric_dimension behavior[:metric_dimension] if behavior[:metric_dimension]
              criteria behavior[:criteria] if behavior[:criteria]
              suppress_alerts behavior[:suppress_alerts] if behavior.key?(:suppress_alerts)
            end
          end
          
          if profile_attrs.alert_targets
            alert_targets do
              profile_attrs.alert_targets.each { |k, v| public_send(k, v) }
            end
          end
          
          if profile_attrs.additional_metrics_to_retain_v2&.any?
            profile_attrs.additional_metrics_to_retain_v2.each do |metric|
              additional_metrics_to_retain_v2 do
                metric metric[:metric]
                metric_dimension metric[:metric_dimension] if metric[:metric_dimension]
                export_metric metric[:export_metric] if metric.key?(:export_metric)
              end
            end
          end
          
          if profile_attrs.tags.any?
            tags do
              profile_attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_iot_security_profile',
          name: name,
          resource_attributes: profile_attrs.to_h,
          outputs: {
            security_profile_name: "${aws_iot_security_profile.#{name}.security_profile_name}",
            security_profile_arn: "${aws_iot_security_profile.#{name}.security_profile_arn}",
            version: "${aws_iot_security_profile.#{name}.version}",
            creation_date: "${aws_iot_security_profile.#{name}.creation_date}",
            last_modified_date: "${aws_iot_security_profile.#{name}.last_modified_date}"
          },
          computed_properties: {
            behavior_count: profile_attrs.behavior_count,
            has_alert_targets: profile_attrs.has_alert_targets?,
            metric_count: profile_attrs.metric_count,
            security_coverage_score: profile_attrs.security_coverage_score
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)