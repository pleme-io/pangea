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

# CloudWatch Extended resources
require 'pangea/resources/aws_cloudwatch_log_resource_policy/resource'
require 'pangea/resources/aws_cloudwatch_query_definition/resource'
require 'pangea/resources/aws_cloudwatch_anomaly_detector/resource'
require 'pangea/resources/aws_cloudwatch_insight_rule/resource'
require 'pangea/resources/aws_cloudwatch_log_data_protection_policy/resource'

# X-Ray Extended resources
require 'pangea/resources/aws_xray_encryption_config/resource'
require 'pangea/resources/aws_xray_sampling_rule/resource'
require 'pangea/resources/aws_xray_group/resource'

# Backup Services resources
require 'pangea/resources/aws_backup_region_settings/resource'
# require 'pangea/resources/aws_backup_framework/resource'  # Temporarily disabled due to syntax errors
require 'pangea/resources/aws_backup_report_plan/resource'

# Disaster Recovery resources
require 'pangea/resources/aws_drs_replication_configuration_template/resource'
require 'pangea/resources/aws_drs_launch_configuration_template/resource'

# Resource Groups resources
require 'pangea/resources/aws_resourcegroups_group/resource'
require 'pangea/resources/aws_resource_explorer_index/resource'
require 'pangea/resources/aws_resource_explorer_view/resource'

# Organizations Extended resources
require 'pangea/resources/aws_organizations_delegated_administrator/resource'
require 'pangea/resources/aws_organizations_resource_policy/resource'

# Support resources
require 'pangea/resources/aws_support_app_slack_channel_configuration/resource'
require 'pangea/resources/aws_support_app_slack_workspace_configuration/resource'

# Extended Service Resources (Route 53, CloudFront, API Gateway, ACM, WAF)
# require 'pangea/resources/aws_route53_delegation_set/resource'  # Temporarily disabled due to syntax errors
require 'pangea/resources/aws_route53_query_log/resource'
require 'pangea/resources/aws_cloudfront_public_key/resource'
require 'pangea/resources/aws_cloudfront_key_group/resource'
require 'pangea/resources/aws_cloudfront_response_headers_policy/resource'
require 'pangea/resources/aws_api_gateway_usage_plan/resource'
require 'pangea/resources/aws_api_gateway_api_key/resource'
require 'pangea/resources/aws_acmpca_certificate_authority/resource'
require 'pangea/resources/aws_wafv2_regex_pattern_set/resource'

# IoT resources
require 'pangea/resources/aws_iot_thing_group/resource'
require 'pangea/resources/aws_iot_thing_group_membership/resource'
require 'pangea/resources/aws_iot_thing_principal_attachment/resource'
require 'pangea/resources/aws_iot_policy_attachment/resource'
require 'pangea/resources/aws_iot_role_alias/resource'
require 'pangea/resources/aws_iot_ca_certificate/resource'
require 'pangea/resources/aws_iot_provisioning_template/resource'
require 'pangea/resources/aws_iot_authorizer/resource'
require 'pangea/resources/aws_iot_job_template/resource'
require 'pangea/resources/aws_iot_domain_configuration/resource'
require 'pangea/resources/aws_iot_billing_group/resource'
require 'pangea/resources/aws_iotanalytics_dataset/resource'
require 'pangea/resources/aws_iot_wireless_destination/resource'
