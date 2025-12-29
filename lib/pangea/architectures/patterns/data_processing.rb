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

require 'pangea/architectures/base'
require_relative 'data_processing/types'
require_relative 'data_processing/storage'
require_relative 'data_processing/ingestion'
require_relative 'data_processing/processing'
require_relative 'data_processing/analytics'
require_relative 'data_processing/security'
require_relative 'data_processing/monitoring'
require_relative 'data_processing/streaming'
require_relative 'data_processing/iam_roles'

module Pangea
  module Architectures
    module Patterns
      # Data Processing Architecture - Comprehensive data pipeline and analytics platform
      module DataProcessing
        include Base
        include Storage
        include Ingestion
        include Processing
        include Analytics
        include Security
        include Monitoring
        include Streaming
        include IamRoles

        # Create a complete data lake architecture
        def data_lake_architecture(name, attributes = {})
          data_attrs = DataLakeAttributes.new(attributes)
          arch_ref = create_architecture_reference('data_lake', name, data_attrs.to_h)

          base_tags = architecture_tags(arch_ref, {
            DataLake: data_attrs.data_lake_name,
            Environment: data_attrs.environment
          }.merge(data_attrs.tags))

          create_network_if_needed(name, arch_ref, data_attrs, base_tags)

          arch_ref.storage = create_data_storage_tier(name, arch_ref, data_attrs, base_tags)
          arch_ref.compute = { ingestion: create_data_ingestion_tier(name, arch_ref, data_attrs, base_tags) }
          arch_ref.compute[:processing] = create_data_processing_tier(name, arch_ref, data_attrs, base_tags)
          arch_ref.compute[:analytics] = create_analytics_tier(name, arch_ref, data_attrs, base_tags)
          arch_ref.security = create_data_security_tier(name, arch_ref, data_attrs, base_tags)
          arch_ref.monitoring = create_data_monitoring_tier(name, arch_ref, data_attrs, base_tags)

          arch_ref
        end

        # Create a real-time streaming data architecture
        def streaming_data_architecture(name, attributes = {})
          stream_attrs = StreamingArchitectureAttributes.new(attributes)
          arch_ref = create_architecture_reference('streaming_data', name, stream_attrs.to_h)

          base_tags = architecture_tags(arch_ref, {
            Stream: stream_attrs.stream_name,
            StreamType: stream_attrs.stream_type
          }.merge(stream_attrs.tags))

          arch_ref.compute = { ingestion: create_streaming_ingestion(name, arch_ref, stream_attrs, base_tags) }
          arch_ref.compute[:processing] = create_stream_processing(name, arch_ref, stream_attrs, base_tags)
          arch_ref.storage = create_streaming_outputs(name, arch_ref, stream_attrs, base_tags)
          arch_ref.monitoring = create_streaming_monitoring(name, arch_ref, stream_attrs, base_tags)

          arch_ref
        end

        private

        def create_network_if_needed(name, arch_ref, data_attrs, base_tags)
          return unless data_attrs.emr_enabled

          arch_ref.network = vpc_with_subnets(
            architecture_resource_name(name, :data_network),
            vpc_cidr: data_attrs.vpc_cidr,
            availability_zones: data_attrs.availability_zones,
            attributes: {
              vpc_tags: base_tags.merge(Tier: 'network'),
              private_subnet_tags: base_tags.merge(Tier: 'private', Purpose: 'processing')
            }
          )
        end
      end
    end
  end
end
