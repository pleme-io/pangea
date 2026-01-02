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

module Pangea
  module Resources
    module AWS
      module Lightsail
        # Load balancer resources for AWS Lightsail
        module LoadBalancer
          def aws_lightsail_load_balancer(name, attributes = {})
            optional_attrs = { lb_name: nil, instance_port: 80, health_check_path: '/', tags: {} }
            lb_attrs = optional_attrs.merge(attributes)

            resource(:aws_lightsail_load_balancer, name) do
              name lb_attrs[:lb_name] if lb_attrs[:lb_name]
              instance_port lb_attrs[:instance_port]
              health_check_path lb_attrs[:health_check_path]
              tags lb_attrs[:tags] if lb_attrs[:tags].any?
            end

            ResourceReference.new(
              type: 'aws_lightsail_load_balancer',
              name: name,
              resource_attributes: lb_attrs,
              outputs: {
                id: "${aws_lightsail_load_balancer.#{name}.id}",
                arn: "${aws_lightsail_load_balancer.#{name}.arn}",
                dns_name: "${aws_lightsail_load_balancer.#{name}.dns_name}",
                protocol: "${aws_lightsail_load_balancer.#{name}.protocol}",
                public_ports: "${aws_lightsail_load_balancer.#{name}.public_ports}"
              }
            )
          end

          def aws_lightsail_load_balancer_attachment(name, attributes = {})
            required_attrs = %i[load_balancer_name instance_names]
            validate_required_attrs!(required_attrs, attributes)

            resource(:aws_lightsail_load_balancer_attachment, name) do
              load_balancer_name attributes[:load_balancer_name]
              instance_names attributes[:instance_names]
            end

            ResourceReference.new(
              type: 'aws_lightsail_load_balancer_attachment',
              name: name,
              resource_attributes: attributes,
              outputs: { id: "${aws_lightsail_load_balancer_attachment.#{name}.id}" }
            )
          end
        end
      end
    end
  end
end
