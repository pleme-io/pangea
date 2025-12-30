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

# Core dependencies
require 'pangea/resources/base'
require 'pangea/resources/reference'

# AWS Service Modules
require 'pangea/resources/aws/emrcontainers'
require 'pangea/resources/aws/sagemaker'
require 'pangea/resources/aws/lookout'
require 'pangea/resources/aws/frauddetector'
require 'pangea/resources/aws/healthlake'
require 'pangea/resources/aws/comprehendmedical'
require 'pangea/resources/aws/servicecatalog'
require 'pangea/resources/aws/controltower'
require 'pangea/resources/aws/wellarchitected'
require 'pangea/resources/aws/applicationdiscoveryservice'
require 'pangea/resources/aws/migrationhub'
require 'pangea/resources/aws/ssm'
require 'pangea/resources/aws/detective'
require 'pangea/resources/aws/security_lake'
require 'pangea/resources/aws/audit_manager'
require 'pangea/resources/aws/batch'
require 'pangea/resources/aws/vpc'
require 'pangea/resources/aws/load_balancing'
require 'pangea/resources/aws/autoscaling'
require 'pangea/resources/aws/ec2'
# require 'pangea/resources/aws/opensearch'  # Temporarily disabled
# require 'pangea/resources/aws/elasticache_extended'  # Temporarily disabled
# require 'pangea/resources/aws/sfn_extended'  # Temporarily disabled
require 'pangea/resources/aws/robomaker'
require 'pangea/resources/aws/cleanrooms'
require 'pangea/resources/aws/supplychain'
require 'pangea/resources/aws/private5g'
require 'pangea/resources/aws/verifiedpermissions'

# Gaming and AR/VR service modules
require 'pangea/resources/aws/gamelift'
require 'pangea/resources/aws/gamesparks'
require 'pangea/resources/aws/sumerian'
require 'pangea/resources/aws/gamedev'

# Media Services modules
require 'pangea/resources/aws/medialive'
require 'pangea/resources/aws/mediapackage'
require 'pangea/resources/aws/kinesisvideo'
require 'pangea/resources/aws/mediaconvert'
