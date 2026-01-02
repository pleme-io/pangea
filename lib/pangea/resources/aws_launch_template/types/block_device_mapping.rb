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

require 'dry-struct'
require 'pangea/resources/types'

module Pangea
  module Resources
    module AWS
      module Types
        # Block device mapping for launch template
        class BlockDeviceMapping < Dry::Struct
          transform_keys(&:to_sym)

          attribute :device_name, Resources::Types::String
          attribute :no_device, Resources::Types::String.optional.default(nil)
          attribute :virtual_name, Resources::Types::String.optional.default(nil)

          # EBS block device settings
          attribute :ebs, Resources::Types::Hash.schema(
            delete_on_termination: Resources::Types::Bool.default(true),
            encrypted: Resources::Types::Bool.default(false),
            iops: Resources::Types::Integer.optional,
            kms_key_id: Resources::Types::String.optional,
            snapshot_id: Resources::Types::String.optional,
            throughput: Resources::Types::Integer.optional,
            volume_size: Resources::Types::Integer.optional,
            volume_type: Resources::Types::String.default('gp3').enum('gp2', 'gp3', 'io1', 'io2', 'st1', 'sc1', 'standard')
          ).optional.default(nil)

          def to_h
            hash = {
              device_name: device_name,
              no_device: no_device,
              virtual_name: virtual_name
            }.compact

            hash[:ebs] = ebs if ebs
            hash
          end
        end
      end
    end
  end
end
