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


require 'pangea/resources/aws/cdk/bootstrap_version'
require 'pangea/resources/aws/cdk/toolkit_stack_tags'
require 'pangea/resources/aws/cdk/file_asset'
require 'pangea/resources/aws/cdk/docker_image_asset'
require 'pangea/resources/aws/cdk/custom_resource_provider'
require 'pangea/resources/aws/cdk/bundling_docker_image'
require 'pangea/resources/aws/cdk/metadata'
require 'pangea/resources/aws/cdk/tree_metadata'

module Pangea
  module Resources
    module AWS
      # AWS CDK (Cloud Development Kit) resources module
      # Provides CDK-specific resource management for bootstrap environments,
      # asset handling, and CDK toolkit integration.
      module CDK
        include BootstrapVersion
        include ToolkitStackTags
        include FileAsset
        include DockerImageAsset
        include CustomResourceProvider
        include BundlingDockerImage
        include Metadata
        include TreeMetadata
      end
    end
  end
end