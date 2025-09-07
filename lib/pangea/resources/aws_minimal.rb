# frozen_string_literal: true

require 'pangea/resources/base'
require 'pangea/resources/reference'

# Load new AWS service modules
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

# Load Gaming and AR/VR service modules
require 'pangea/resources/aws/gamelift'
require 'pangea/resources/aws/gamesparks'
require 'pangea/resources/aws/sumerian'
require 'pangea/resources/aws/gamedev'

# Load Media Services modules
require 'pangea/resources/aws/medialive'
require 'pangea/resources/aws/mediapackage'
require 'pangea/resources/aws/kinesisvideo'
require 'pangea/resources/aws/mediaconvert'

# Load CloudWatch Extended resources
require 'pangea/resources/aws_cloudwatch_log_resource_policy/resource'
require 'pangea/resources/aws_cloudwatch_query_definition/resource'
require 'pangea/resources/aws_cloudwatch_anomaly_detector/resource'
require 'pangea/resources/aws_cloudwatch_insight_rule/resource'
require 'pangea/resources/aws_cloudwatch_log_data_protection_policy/resource'

# Load X-Ray Extended resources
require 'pangea/resources/aws_xray_encryption_config/resource'
require 'pangea/resources/aws_xray_sampling_rule/resource'
require 'pangea/resources/aws_xray_group/resource'

# Load Backup Services resources
require 'pangea/resources/aws_backup_region_settings/resource'
# require 'pangea/resources/aws_backup_framework/resource'  # Temporarily disabled due to syntax errors
require 'pangea/resources/aws_backup_report_plan/resource'

# Load Disaster Recovery resources
require 'pangea/resources/aws_drs_replication_configuration_template/resource'
require 'pangea/resources/aws_drs_launch_configuration_template/resource'

# Load Resource Groups resources
require 'pangea/resources/aws_resourcegroups_group/resource'
require 'pangea/resources/aws_resource_explorer_index/resource'
require 'pangea/resources/aws_resource_explorer_view/resource'

# Load Organizations Extended resources
require 'pangea/resources/aws_organizations_delegated_administrator/resource'
require 'pangea/resources/aws_organizations_resource_policy/resource'

# Load Support resources
require 'pangea/resources/aws_support_app_slack_channel_configuration/resource'
require 'pangea/resources/aws_support_app_slack_workspace_configuration/resource'

# Load Extended Service Resources (Route 53, CloudFront, API Gateway, ACM, WAF)
# require 'pangea/resources/aws_route53_delegation_set/resource'  # Temporarily disabled due to syntax errors
require 'pangea/resources/aws_route53_query_log/resource'
require 'pangea/resources/aws_cloudfront_public_key/resource'
require 'pangea/resources/aws_cloudfront_key_group/resource'
require 'pangea/resources/aws_cloudfront_response_headers_policy/resource'
require 'pangea/resources/aws_api_gateway_usage_plan/resource'
require 'pangea/resources/aws_api_gateway_api_key/resource'
require 'pangea/resources/aws_acmpca_certificate_authority/resource'
require 'pangea/resources/aws_wafv2_regex_pattern_set/resource'

# Load IoT resources
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

# Load all AWS resource implementations
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
require 'pangea/resources/aws_neptune_cluster/resource'
require 'pangea/resources/aws_neptune_cluster_instance/resource'
require 'pangea/resources/aws_neptune_cluster_parameter_group/resource'
require 'pangea/resources/aws_neptune_cluster_snapshot/resource'
require 'pangea/resources/aws_neptune_subnet_group/resource'
require 'pangea/resources/aws_neptune_event_subscription/resource'
require 'pangea/resources/aws_neptune_parameter_group/resource'
require 'pangea/resources/aws_neptune_cluster_endpoint/resource'
require 'pangea/resources/aws_timestream_database/resource'
require 'pangea/resources/aws_timestream_table/resource'
require 'pangea/resources/aws_timestream_scheduled_query/resource'
require 'pangea/resources/aws_timestream_batch_load_task/resource'
require 'pangea/resources/aws_timestream_influx_db_instance/resource'
require 'pangea/resources/aws_timestream_table_retention_properties/resource'
require 'pangea/resources/aws_timestream_access_policy/resource'
require 'pangea/resources/aws_memorydb_cluster/resource'
require 'pangea/resources/aws_memorydb_parameter_group/resource'
require 'pangea/resources/aws_memorydb_subnet_group/resource'
require 'pangea/resources/aws_memorydb_user/resource'
require 'pangea/resources/aws_memorydb_acl/resource'
require 'pangea/resources/aws_memorydb_snapshot/resource'
require 'pangea/resources/aws_memorydb_multi_region_cluster/resource'
require 'pangea/resources/aws_memorydb_cluster_endpoint/resource'
require 'pangea/resources/aws_licensemanager_license_configuration/resource'
require 'pangea/resources/aws_licensemanager_association/resource'
require 'pangea/resources/aws_licensemanager_grant/resource'
require 'pangea/resources/aws_licensemanager_grant_accepter/resource'
require 'pangea/resources/aws_licensemanager_license_grant_accepter/resource'
require 'pangea/resources/aws_licensemanager_token/resource'
require 'pangea/resources/aws_licensemanager_report_generator/resource'
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

# VPC Extended resources
require 'pangea/resources/aws_vpc_endpoint_connection_notification/resource'
require 'pangea/resources/aws_vpc_endpoint_service_allowed_principal/resource'
require 'pangea/resources/aws_vpc_endpoint_connection_accepter/resource'
require 'pangea/resources/aws_vpc_endpoint_route_table_association/resource'
require 'pangea/resources/aws_vpc_endpoint_subnet_association/resource'
require 'pangea/resources/aws_vpc_peering_connection_options/resource'
require 'pangea/resources/aws_vpc_peering_connection_accepter/resource'
require 'pangea/resources/aws_vpc_dhcp_options_association/resource'
require 'pangea/resources/aws_vpc_network_performance_metric_subscription/resource'
require 'pangea/resources/aws_vpc_security_group_egress_rule/resource'
require 'pangea/resources/aws_vpc_security_group_ingress_rule/resource'
require 'pangea/resources/aws_default_vpc_dhcp_options/resource'
require 'pangea/resources/aws_default_network_acl/resource'
require 'pangea/resources/aws_default_route_table/resource'
require 'pangea/resources/aws_default_security_group/resource'

# Load Balancing Extended resources
require 'pangea/resources/aws_lb_trust_store/resource'
require 'pangea/resources/aws_lb_trust_store_revocation/resource'
require 'pangea/resources/aws_alb_target_group_attachment/resource'
require 'pangea/resources/aws_lb_target_group_attachment/resource'
require 'pangea/resources/aws_lb_ssl_negotiation_policy/resource'
require 'pangea/resources/aws_lb_cookie_stickiness_policy/resource'
require 'pangea/resources/aws_elb_attachment/resource'
require 'pangea/resources/aws_elb_service_account/resource'
require 'pangea/resources/aws_proxy_protocol_policy/resource'
require 'pangea/resources/aws_load_balancer_backend_server_policy/resource'
require 'pangea/resources/aws_load_balancer_listener_policy/resource'
require 'pangea/resources/aws_load_balancer_policy/resource'

# Auto Scaling Extended resources
require 'pangea/resources/aws_autoscaling_lifecycle_hook/resource'
require 'pangea/resources/aws_autoscaling_notification/resource'
require 'pangea/resources/aws_autoscaling_schedule/resource'
require 'pangea/resources/aws_autoscaling_traffic_source_attachment/resource'
require 'pangea/resources/aws_autoscaling_warm_pool/resource'
require 'pangea/resources/aws_autoscaling_group_tag/resource'
require 'pangea/resources/aws_launch_configuration/resource'
require 'pangea/resources/aws_placement_group/resource'
require 'pangea/resources/aws_autoscaling_policy_step_adjustment/resource'
require 'pangea/resources/aws_autoscaling_policy_target_tracking_scaling_policy/resource'

# EC2 Extended resources
require 'pangea/resources/aws_ec2_availability_zone_group/resource'
require 'pangea/resources/aws_ec2_capacity_reservation/resource'
require 'pangea/resources/aws_ec2_capacity_block_reservation/resource'
require 'pangea/resources/aws_ec2_fleet/resource'
require 'pangea/resources/aws_ec2_spot_fleet_request/resource'
require 'pangea/resources/aws_ec2_spot_datafeed_subscription/resource'
require 'pangea/resources/aws_ec2_spot_instance_request/resource'
require 'pangea/resources/aws_ec2_dedicated_host/resource'
require 'pangea/resources/aws_ec2_host_resource_group_association/resource'
require 'pangea/resources/aws_ec2_instance_metadata_defaults/resource'
require 'pangea/resources/aws_ec2_serial_console_access/resource'
require 'pangea/resources/aws_ec2_image_block_public_access/resource'
require 'pangea/resources/aws_ec2_ami_launch_permission/resource'
require 'pangea/resources/aws_ec2_snapshot_block_public_access/resource'
require 'pangea/resources/aws_ec2_tag/resource'
require 'pangea/resources/aws_ec2_transit_gateway_multicast_domain/resource'
require 'pangea/resources/aws_ec2_transit_gateway_multicast_domain_association/resource'
require 'pangea/resources/aws_ec2_transit_gateway_multicast_group_member/resource'

module Pangea
  module Resources
    # AWS resource functions - All 50 resources from database batch
    # Each resource file defines its method directly in the AWS module
    module AWS
      include Base
      
      # Include new service modules
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
      
      # Include Gaming and AR/VR service modules
      include GameLift
      include GameSparks
      include Sumerian
      include GameDev
      
      # Include Media Services modules
      include MediaLive
      include MediaPackage
      include KinesisVideo
      include MediaConvert
      
      # Include IoT resources
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
