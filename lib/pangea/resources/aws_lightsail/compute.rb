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
        # Compute resources for AWS Lightsail
        module Compute
          def aws_lightsail_instance(name, attributes = {})
            required_attrs = %i[availability_zone blueprint_id bundle_id]
            optional_attrs = { key_pair_name: nil, user_data: nil, tags: {} }

            instance_attrs = optional_attrs.merge(attributes)
            validate_required_attrs!(required_attrs, instance_attrs)

            resource(:aws_lightsail_instance, name) do
              availability_zone instance_attrs[:availability_zone]
              blueprint_id instance_attrs[:blueprint_id]
              bundle_id instance_attrs[:bundle_id]
              key_pair_name instance_attrs[:key_pair_name] if instance_attrs[:key_pair_name]
              user_data instance_attrs[:user_data] if instance_attrs[:user_data]
              tags instance_attrs[:tags] if instance_attrs[:tags].any?
            end

            ResourceReference.new(
              type: 'aws_lightsail_instance',
              name: name,
              resource_attributes: instance_attrs,
              outputs: {
                id: "${aws_lightsail_instance.#{name}.id}",
                arn: "${aws_lightsail_instance.#{name}.arn}",
                public_ip_address: "${aws_lightsail_instance.#{name}.public_ip_address}",
                private_ip_address: "${aws_lightsail_instance.#{name}.private_ip_address}",
                is_static_ip: "${aws_lightsail_instance.#{name}.is_static_ip}",
                username: "${aws_lightsail_instance.#{name}.username}",
                availability_zone: "${aws_lightsail_instance.#{name}.availability_zone}"
              }
            )
          end

          def aws_lightsail_key_pair(name, attributes = {})
            optional_attrs = { public_key: nil, key_pair_name: nil, tags: {} }
            key_attrs = optional_attrs.merge(attributes)

            resource(:aws_lightsail_key_pair, name) do
              key_pair_name key_attrs[:key_pair_name] if key_attrs[:key_pair_name]
              public_key key_attrs[:public_key] if key_attrs[:public_key]
              tags key_attrs[:tags] if key_attrs[:tags].any?
            end

            ResourceReference.new(
              type: 'aws_lightsail_key_pair',
              name: name,
              resource_attributes: key_attrs,
              outputs: {
                id: "${aws_lightsail_key_pair.#{name}.id}",
                arn: "${aws_lightsail_key_pair.#{name}.arn}",
                name: "${aws_lightsail_key_pair.#{name}.name}",
                fingerprint: "${aws_lightsail_key_pair.#{name}.fingerprint}",
                public_key: "${aws_lightsail_key_pair.#{name}.public_key}",
                private_key: "${aws_lightsail_key_pair.#{name}.private_key}"
              }
            )
          end
        end
      end
    end
  end
end
