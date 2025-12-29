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

require_relative 'replication/database'
require_relative 'replication/s3'
require_relative 'replication/efs'

module Pangea
  module Components
    module DisasterRecoveryPilotLight
      # Data replication infrastructure
      module Replication
        include Database
        include S3
        include Efs

        def setup_data_replication(name, attrs, primary_resources, dr_resources, tags)
          replication_resources = {}

          if attrs.pilot_light.database_replicas && attrs.critical_data.databases.any?
            replication_resources[:database_replicas] = create_database_replicas(
              name, attrs, dr_resources, tags
            )
          end

          if attrs.critical_data.s3_buckets.any?
            replication_resources[:s3_replication] = create_s3_replication(
              name, attrs, tags
            )
          end

          if attrs.critical_data.efs_filesystems.any?
            replication_resources[:efs_replication] = create_efs_replication(
              name, attrs, tags
            )
          end

          if attrs.critical_data.databases.any? { |db| !db[:engine].start_with?('aurora') }
            replication_resources[:dms_instance] = create_dms_instance(
              name, dr_resources, tags
            )
          end

          replication_resources
        end
      end
    end
  end
end
