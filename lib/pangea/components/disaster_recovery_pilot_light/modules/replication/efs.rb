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
  module Components
    module DisasterRecoveryPilotLight
      module Replication
        # EFS filesystem replication resources
        module Efs
          def create_efs_replication(name, attrs, tags)
            efs_replication = {}

            attrs.critical_data.efs_filesystems.each_with_index do |fs_id, index|
              efs_replication["fs_#{index}".to_sym] = aws_efs_replication_configuration(
                component_resource_name(name, :efs_replication, "fs#{index}".to_sym),
                {
                  source_file_system_id: fs_id,
                  destination: [{
                    region: attrs.dr_region.region,
                    availability_zone_name: attrs.dr_region.availability_zones.first,
                    kms_key_id: attrs.compliance.encryption_required ? "alias/aws/efs" : nil
                  }]
                }.compact
              )
            end

            efs_replication
          end
        end
      end
    end
  end
end
