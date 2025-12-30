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

# DocumentDB resources
require 'pangea/resources/aws_docdb_cluster/resource'
require 'pangea/resources/aws_docdb_cluster_instance/resource'
require 'pangea/resources/aws_docdb_cluster_parameter_group/resource'
require 'pangea/resources/aws_docdb_cluster_snapshot/resource'
require 'pangea/resources/aws_docdb_subnet_group/resource'
require 'pangea/resources/aws_docdb_cluster_endpoint/resource'
require 'pangea/resources/aws_docdb_global_cluster/resource'
require 'pangea/resources/aws_docdb_event_subscription/resource'
require 'pangea/resources/aws_docdb_certificate/resource'
require 'pangea/resources/aws_docdb_cluster_backup/resource'

# Neptune resources
require 'pangea/resources/aws_neptune_cluster/resource'
require 'pangea/resources/aws_neptune_cluster_instance/resource'
require 'pangea/resources/aws_neptune_cluster_parameter_group/resource'
require 'pangea/resources/aws_neptune_cluster_snapshot/resource'
require 'pangea/resources/aws_neptune_subnet_group/resource'
require 'pangea/resources/aws_neptune_event_subscription/resource'
require 'pangea/resources/aws_neptune_parameter_group/resource'
require 'pangea/resources/aws_neptune_cluster_endpoint/resource'

# Timestream resources
require 'pangea/resources/aws_timestream_database/resource'
require 'pangea/resources/aws_timestream_table/resource'
require 'pangea/resources/aws_timestream_scheduled_query/resource'
require 'pangea/resources/aws_timestream_batch_load_task/resource'
require 'pangea/resources/aws_timestream_influx_db_instance/resource'
require 'pangea/resources/aws_timestream_table_retention_properties/resource'
require 'pangea/resources/aws_timestream_access_policy/resource'

# MemoryDB resources
require 'pangea/resources/aws_memorydb_cluster/resource'
require 'pangea/resources/aws_memorydb_parameter_group/resource'
require 'pangea/resources/aws_memorydb_subnet_group/resource'
require 'pangea/resources/aws_memorydb_user/resource'
require 'pangea/resources/aws_memorydb_acl/resource'
require 'pangea/resources/aws_memorydb_snapshot/resource'
require 'pangea/resources/aws_memorydb_multi_region_cluster/resource'
require 'pangea/resources/aws_memorydb_cluster_endpoint/resource'

# License Manager resources
require 'pangea/resources/aws_licensemanager_license_configuration/resource'
require 'pangea/resources/aws_licensemanager_association/resource'
require 'pangea/resources/aws_licensemanager_grant/resource'
require 'pangea/resources/aws_licensemanager_grant_accepter/resource'
require 'pangea/resources/aws_licensemanager_license_grant_accepter/resource'
require 'pangea/resources/aws_licensemanager_token/resource'
require 'pangea/resources/aws_licensemanager_report_generator/resource'

# RAM resources
require 'pangea/resources/aws_ram_resource_share/resource'
require 'pangea/resources/aws_ram_resource_association/resource'
require 'pangea/resources/aws_ram_principal_association/resource'
require 'pangea/resources/aws_ram_resource_share_accepter/resource'
require 'pangea/resources/aws_ram_invitation_accepter/resource'
require 'pangea/resources/aws_ram_sharing_with_organization/resource'
require 'pangea/resources/aws_ram_permission/resource'
require 'pangea/resources/aws_ram_permission_association/resource'
require 'pangea/resources/aws_ram_resource_share_invitation/resource'
require 'pangea/resources/aws_ram_managed_permission/resource'
