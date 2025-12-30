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

# Load all AWS resource requires from extracted modules
require_relative 'aws_minimal/requires/service_modules'
require_relative 'aws_minimal/requires/extended_services'
require_relative 'aws_minimal/requires/database_resources'
require_relative 'aws_minimal/requires/compute_network_resources'

module Pangea
  module Resources
    # AWS resource functions - All 50 resources from database batch
    # Each resource file defines its method directly in the AWS module
    module AWS
      include Base

      # Service modules
      include EMRContainers
      include SageMaker
      include Lookout
      include FraudDetector
      include HealthLake
      include ComprehendMedical
      include ServiceCatalog
      include ControlTower
      include WellArchitected
      include ApplicationDiscoveryService
      include MigrationHub
      include SSM
      include Detective
      include SecurityLake
      include AuditManager
      include Batch
      include VPC
      include LoadBalancing
      include AutoScaling
      include EC2
      # include OpenSearch
      # include ElastiCacheExtended
      # include SfnExtended
      include RoboMaker
      include CleanRooms
      include SupplyChain
      include Private5G
      include VerifiedPermissions

      # Gaming and AR/VR service modules
      include GameLift
      include GameSparks
      include Sumerian
      include GameDev

      # Media Services modules
      include MediaLive
      include MediaPackage
      include KinesisVideo
      include MediaConvert

      # IoT resources
      include AwsIotThingGroup
      include AwsIotThingGroupMembership
      include AwsIotThingPrincipalAttachment
      include AwsIotPolicyAttachment
      include AwsIotRoleAlias
      include AwsIotCaCertificate
      include AwsIotProvisioningTemplate
      include AwsIotAuthorizer
      include AwsIotJobTemplate
      include AwsIotDomainConfiguration
      include AwsIotBillingGroup
      include AwsIotanalyticsDataset
      include AwsIotWirelessDestination
    end
  end
end
