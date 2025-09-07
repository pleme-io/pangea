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
require 'pangea/resources/aws_ce_anomaly_detector/types'
require 'pangea/resource_registry'

module Pangea
  module Resources
    module AWS
      def aws_ce_anomaly_detector(name, attributes = {})
        detector_attrs = Types::AnomalyDetectorAttributes.new(attributes)
        
        resource(:aws_ce_anomaly_detector, name) do
          name detector_attrs.name
          monitor_type detector_attrs.monitor_type
          monitor_specification detector_attrs.monitor_specification if detector_attrs.monitor_specification
          
          if detector_attrs.dimension_key
            dimension_key detector_attrs.dimension_key
            dimension_values detector_attrs.dimension_values if detector_attrs.dimension_values
            match_options detector_attrs.match_options if detector_attrs.match_options
          end
          
          if detector_attrs.tags&.any?
            tags do
              detector_attrs.tags.each { |k, v| public_send(k, v) }
            end
          end
        end
        
        ResourceReference.new(
          type: 'aws_ce_anomaly_detector',
          name: name,
          resource_attributes: detector_attrs.to_h,
          outputs: {
            arn: "${aws_ce_anomaly_detector.#{name}.arn}",
            name: "${aws_ce_anomaly_detector.#{name}.name}",
            monitor_type: "${aws_ce_anomaly_detector.#{name}.monitor_type}",
            is_service_monitor: detector_attrs.is_service_monitor?,
            is_dimensional_monitor: detector_attrs.is_dimensional_monitor?,
            has_custom_specification: detector_attrs.has_custom_specification?
          }
        )
      end
    end
  end
end

# Auto-register this module when it's loaded
Pangea::ResourceRegistry.register(:aws, Pangea::Resources::AWS)