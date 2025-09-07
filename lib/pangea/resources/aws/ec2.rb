# frozen_string_literal: true

require_relative 'ec2/ec2_availability_zone_group'
require_relative 'ec2/ec2_capacity_reservation'
require_relative 'ec2/ec2_capacity_block_reservation'
require_relative 'ec2/ec2_fleet'
require_relative 'ec2/ec2_spot_fleet_request'
require_relative 'ec2/ec2_spot_datafeed_subscription'
require_relative 'ec2/ec2_spot_instance_request'
require_relative 'ec2/ec2_dedicated_host'
require_relative 'ec2/ec2_host_resource_group_association'
require_relative 'ec2/ec2_instance_metadata_defaults'
require_relative 'ec2/ec2_serial_console_access'
require_relative 'ec2/ec2_image_block_public_access'
require_relative 'ec2/ec2_ami_launch_permission'
require_relative 'ec2/ec2_snapshot_block_public_access'
require_relative 'ec2/ec2_tag'
require_relative 'ec2/ec2_transit_gateway_multicast_domain'
require_relative 'ec2/ec2_transit_gateway_multicast_domain_association'
require_relative 'ec2/ec2_transit_gateway_multicast_group_member'

module Pangea
  module Resources
    module AWS
      # AWS EC2 Extended service module
      # Provides type-safe resource functions for advanced EC2 compute and networking
      module EC2
        # Creates an EC2 availability zone group for managing AZ access
        #
        # @param name [Symbol] Unique name for the availability zone group resource
        # @param attributes [Hash] Configuration attributes for the AZ group
        # @return [EC2::Ec2AvailabilityZoneGroup::Ec2AvailabilityZoneGroupReference] Reference to the created AZ group
        def aws_ec2_availability_zone_group(name, attributes = {})
          resource = EC2::Ec2AvailabilityZoneGroup.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2AvailabilityZoneGroup::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 capacity reservation for guaranteed compute capacity
        #
        # @param name [Symbol] Unique name for the capacity reservation resource
        # @param attributes [Hash] Configuration attributes for the reservation
        # @return [EC2::Ec2CapacityReservation::Ec2CapacityReservationReference] Reference to the created reservation
        def aws_ec2_capacity_reservation(name, attributes = {})
          resource = EC2::Ec2CapacityReservation.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2CapacityReservation::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 capacity block reservation for high-performance computing workloads
        #
        # @param name [Symbol] Unique name for the capacity block reservation resource
        # @param attributes [Hash] Configuration attributes for the block reservation
        # @return [EC2::Ec2CapacityBlockReservation::Ec2CapacityBlockReservationReference] Reference to the created block reservation
        def aws_ec2_capacity_block_reservation(name, attributes = {})
          resource = EC2::Ec2CapacityBlockReservation.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2CapacityBlockReservation::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 fleet for launching multiple instance types across multiple AZs
        #
        # @param name [Symbol] Unique name for the EC2 fleet resource
        # @param attributes [Hash] Configuration attributes for the fleet
        # @return [EC2::Ec2Fleet::Ec2FleetReference] Reference to the created fleet
        def aws_ec2_fleet(name, attributes = {})
          resource = EC2::Ec2Fleet.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2Fleet::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 spot fleet request for cost-optimized instance provisioning
        #
        # @param name [Symbol] Unique name for the spot fleet request resource
        # @param attributes [Hash] Configuration attributes for the spot fleet
        # @return [EC2::Ec2SpotFleetRequest::Ec2SpotFleetRequestReference] Reference to the created spot fleet
        def aws_ec2_spot_fleet_request(name, attributes = {})
          resource = EC2::Ec2SpotFleetRequest.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2SpotFleetRequest::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 spot datafeed subscription for spot instance activity logging
        #
        # @param name [Symbol] Unique name for the spot datafeed subscription resource
        # @param attributes [Hash] Configuration attributes for the datafeed
        # @return [EC2::Ec2SpotDatafeedSubscription::Ec2SpotDatafeedSubscriptionReference] Reference to the created datafeed
        def aws_ec2_spot_datafeed_subscription(name, attributes = {})
          resource = EC2::Ec2SpotDatafeedSubscription.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2SpotDatafeedSubscription::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 spot instance request for requesting spot instances
        #
        # @param name [Symbol] Unique name for the spot instance request resource
        # @param attributes [Hash] Configuration attributes for the spot request
        # @return [EC2::Ec2SpotInstanceRequest::Ec2SpotInstanceRequestReference] Reference to the created spot request
        def aws_ec2_spot_instance_request(name, attributes = {})
          resource = EC2::Ec2SpotInstanceRequest.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2SpotInstanceRequest::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 dedicated host for single-tenant hardware
        #
        # @param name [Symbol] Unique name for the dedicated host resource
        # @param attributes [Hash] Configuration attributes for the dedicated host
        # @return [EC2::Ec2DedicatedHost::Ec2DedicatedHostReference] Reference to the created dedicated host
        def aws_ec2_dedicated_host(name, attributes = {})
          resource = EC2::Ec2DedicatedHost.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2DedicatedHost::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 host resource group association for dedicated host management
        #
        # @param name [Symbol] Unique name for the host resource group association resource
        # @param attributes [Hash] Configuration attributes for the association
        # @return [EC2::Ec2HostResourceGroupAssociation::Ec2HostResourceGroupAssociationReference] Reference to the created association
        def aws_ec2_host_resource_group_association(name, attributes = {})
          resource = EC2::Ec2HostResourceGroupAssociation.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2HostResourceGroupAssociation::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Manages EC2 instance metadata defaults for account-level metadata service configuration
        #
        # @param name [Symbol] Unique name for the instance metadata defaults resource
        # @param attributes [Hash] Configuration attributes for metadata defaults
        # @return [EC2::Ec2InstanceMetadataDefaults::Ec2InstanceMetadataDefaultsReference] Reference to the created defaults
        def aws_ec2_instance_metadata_defaults(name, attributes = {})
          resource = EC2::Ec2InstanceMetadataDefaults.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2InstanceMetadataDefaults::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Manages EC2 serial console access configuration for debugging instances
        #
        # @param name [Symbol] Unique name for the serial console access resource
        # @param attributes [Hash] Configuration attributes for console access
        # @return [EC2::Ec2SerialConsoleAccess::Ec2SerialConsoleAccessReference] Reference to the created console access
        def aws_ec2_serial_console_access(name, attributes = {})
          resource = EC2::Ec2SerialConsoleAccess.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2SerialConsoleAccess::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Manages EC2 image block public access settings for AMI sharing control
        #
        # @param name [Symbol] Unique name for the image block public access resource
        # @param attributes [Hash] Configuration attributes for public access blocking
        # @return [EC2::Ec2ImageBlockPublicAccess::Ec2ImageBlockPublicAccessReference] Reference to the created access block
        def aws_ec2_image_block_public_access(name, attributes = {})
          resource = EC2::Ec2ImageBlockPublicAccess.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2ImageBlockPublicAccess::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 AMI launch permission for controlling AMI access
        #
        # @param name [Symbol] Unique name for the AMI launch permission resource
        # @param attributes [Hash] Configuration attributes for the launch permission
        # @return [EC2::Ec2AmiLaunchPermission::Ec2AmiLaunchPermissionReference] Reference to the created permission
        def aws_ec2_ami_launch_permission(name, attributes = {})
          resource = EC2::Ec2AmiLaunchPermission.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2AmiLaunchPermission::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Manages EC2 snapshot block public access settings for snapshot sharing control
        #
        # @param name [Symbol] Unique name for the snapshot block public access resource
        # @param attributes [Hash] Configuration attributes for public access blocking
        # @return [EC2::Ec2SnapshotBlockPublicAccess::Ec2SnapshotBlockPublicAccessReference] Reference to the created access block
        def aws_ec2_snapshot_block_public_access(name, attributes = {})
          resource = EC2::Ec2SnapshotBlockPublicAccess.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2SnapshotBlockPublicAccess::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 tag for resource tagging
        #
        # @param name [Symbol] Unique name for the EC2 tag resource
        # @param attributes [Hash] Configuration attributes for the tag
        # @return [EC2::Ec2Tag::Ec2TagReference] Reference to the created tag
        def aws_ec2_tag(name, attributes = {})
          resource = EC2::Ec2Tag.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2Tag::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 transit gateway multicast domain for multicast traffic routing
        #
        # @param name [Symbol] Unique name for the multicast domain resource
        # @param attributes [Hash] Configuration attributes for the multicast domain
        # @return [EC2::Ec2TransitGatewayMulticastDomain::Ec2TransitGatewayMulticastDomainReference] Reference to the created domain
        def aws_ec2_transit_gateway_multicast_domain(name, attributes = {})
          resource = EC2::Ec2TransitGatewayMulticastDomain.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2TransitGatewayMulticastDomain::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 transit gateway multicast domain association for subnet association
        #
        # @param name [Symbol] Unique name for the multicast domain association resource
        # @param attributes [Hash] Configuration attributes for the association
        # @return [EC2::Ec2TransitGatewayMulticastDomainAssociation::Ec2TransitGatewayMulticastDomainAssociationReference] Reference to the created association
        def aws_ec2_transit_gateway_multicast_domain_association(name, attributes = {})
          resource = EC2::Ec2TransitGatewayMulticastDomainAssociation.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2TransitGatewayMulticastDomainAssociation::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end

        # Creates an EC2 transit gateway multicast group member for multicast group management
        #
        # @param name [Symbol] Unique name for the multicast group member resource
        # @param attributes [Hash] Configuration attributes for the group member
        # @return [EC2::Ec2TransitGatewayMulticastGroupMember::Ec2TransitGatewayMulticastGroupMemberReference] Reference to the created group member
        def aws_ec2_transit_gateway_multicast_group_member(name, attributes = {})
          resource = EC2::Ec2TransitGatewayMulticastGroupMember.new(
            name: name,
            synthesizer: synthesizer,
            attributes: EC2::Ec2TransitGatewayMulticastGroupMember::Attributes.new(attributes)
          )
          resource.synthesize
          resource.reference
        end
      end
    end
  end
end