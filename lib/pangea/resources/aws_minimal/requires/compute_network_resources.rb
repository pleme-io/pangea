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
