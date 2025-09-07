# frozen_string_literal: true

module Pangea
  module Resources
    module AWS
      # AWS Snow Family - Edge computing and data transfer devices
      # Snow Family provides physical devices for edge computing, data collection, and migration in environments with limited or no connectivity
      
      # Create a Snowball job for data transfer
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Snowball job attributes
      # @option attributes [String] :job_type (required) The job type ("IMPORT" or "EXPORT")
      # @option attributes [Array<Hash>] :resources (required) Resources configuration
      # @option attributes [String] :description Job description
      # @option attributes [String] :role_arn Role ARN for Snowball operations
      # @option attributes [Hash] :shipping_details Shipping details
      # @option attributes [Hash] :snowball_capacitys3 S3 capacity configuration
      # @option attributes [String] :snowball_type Device type ("STANDARD", "EDGE", "EDGE_C", "EDGE_CG")
      # @return [ResourceReference] Reference object with outputs
      def aws_snowball_job(name, attributes = {})
        required_attrs = %i[job_type resources]
        optional_attrs = {
          description: nil,
          role_arn: nil,
          shipping_details: {},
          snowball_capacity_preference: "T100",
          snowball_type: "STANDARD"
        }
        
        job_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless job_attrs.key?(attr)
        end
        
        resource(:aws_snowball_job, name) do
          job_type job_attrs[:job_type]
          resources job_attrs[:resources]
          description job_attrs[:description] if job_attrs[:description]
          role_arn job_attrs[:role_arn] if job_attrs[:role_arn]
          snowball_capacity_preference job_attrs[:snowball_capacity_preference]
          snowball_type job_attrs[:snowball_type]
          
          if job_attrs[:shipping_details].any?
            shipping_details job_attrs[:shipping_details]
          end
        end
        
        ResourceReference.new(
          type: 'aws_snowball_job',
          name: name,
          resource_attributes: job_attrs,
          outputs: {
            id: "${aws_snowball_job.#{name}.id}",
            arn: "${aws_snowball_job.#{name}.arn}",
            job_state: "${aws_snowball_job.#{name}.job_state}",
            creation_date: "${aws_snowball_job.#{name}.creation_date}"
          }
        )
      end
      
      # Create a Snowball cluster for large-scale data transfers
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Snowball cluster attributes
      # @option attributes [String] :job_type (required) The job type ("LOCAL_USE" or "EXPORT")
      # @option attributes [Hash] :resources (required) Resources configuration
      # @option attributes [String] :description Cluster description
      # @option attributes [String] :role_arn Role ARN for Snowball operations
      # @option attributes [Hash] :shipping_details Shipping details
      # @option attributes [String] :snowball_type Device type ("EDGE", "EDGE_C", "EDGE_CG")
      # @return [ResourceReference] Reference object with outputs
      def aws_snowball_cluster(name, attributes = {})
        required_attrs = %i[job_type resources]
        optional_attrs = {
          description: nil,
          role_arn: nil,
          shipping_details: {},
          snowball_type: "EDGE"
        }
        
        cluster_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless cluster_attrs.key?(attr)
        end
        
        resource(:aws_snowball_cluster, name) do
          job_type cluster_attrs[:job_type]
          resources cluster_attrs[:resources]
          description cluster_attrs[:description] if cluster_attrs[:description]
          role_arn cluster_attrs[:role_arn] if cluster_attrs[:role_arn]
          snowball_type cluster_attrs[:snowball_type]
          
          if cluster_attrs[:shipping_details].any?
            shipping_details cluster_attrs[:shipping_details]
          end
        end
        
        ResourceReference.new(
          type: 'aws_snowball_cluster',
          name: name,
          resource_attributes: cluster_attrs,
          outputs: {
            id: "${aws_snowball_cluster.#{name}.id}",
            arn: "${aws_snowball_cluster.#{name}.arn}",
            cluster_state: "${aws_snowball_cluster.#{name}.cluster_state}",
            creation_date: "${aws_snowball_cluster.#{name}.creation_date}"
          }
        )
      end
      
      # Create a Snowcone job for edge computing and data transfer
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Snowcone job attributes
      # @option attributes [String] :job_type (required) The job type ("IMPORT" or "LOCAL_USE")
      # @option attributes [Hash] :resources (required) Resources configuration
      # @option attributes [String] :description Job description
      # @option attributes [String] :role_arn Role ARN for operations
      # @option attributes [Hash] :shipping_details Shipping details
      # @option attributes [Hash] :device_configuration Device-specific configuration
      # @return [ResourceReference] Reference object with outputs
      def aws_snowcone_job(name, attributes = {})
        required_attrs = %i[job_type resources]
        optional_attrs = {
          description: nil,
          role_arn: nil,
          shipping_details: {},
          device_configuration: {}
        }
        
        job_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless job_attrs.key?(attr)
        end
        
        resource(:aws_snowcone_job, name) do
          job_type job_attrs[:job_type]
          resources job_attrs[:resources]
          description job_attrs[:description] if job_attrs[:description]
          role_arn job_attrs[:role_arn] if job_attrs[:role_arn]
          snowball_type "SNC1_HDD"  # Snowcone device type
          
          if job_attrs[:shipping_details].any?
            shipping_details job_attrs[:shipping_details]
          end
          
          if job_attrs[:device_configuration].any?
            device_configuration job_attrs[:device_configuration]
          end
        end
        
        ResourceReference.new(
          type: 'aws_snowcone_job',
          name: name,
          resource_attributes: job_attrs,
          outputs: {
            id: "${aws_snowcone_job.#{name}.id}",
            arn: "${aws_snowcone_job.#{name}.arn}",
            job_state: "${aws_snowcone_job.#{name}.job_state}",
            device_id: "${aws_snowcone_job.#{name}.device_id}"
          }
        )
      end
      
      # Query Snowcone device information
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Device attributes
      # @option attributes [String] :device_id The device ID
      # @option attributes [String] :job_id The associated job ID
      # @return [ResourceReference] Reference object with outputs
      def aws_snowcone_device(name, attributes = {})
        optional_attrs = {
          device_id: nil,
          job_id: nil
        }
        
        device_attrs = optional_attrs.merge(attributes)
        
        data(:aws_snowball_job, name) do
          job_id device_attrs[:job_id] if device_attrs[:job_id]
        end
        
        ResourceReference.new(
          type: 'aws_snowball_job',
          name: name,
          resource_attributes: device_attrs,
          outputs: {
            id: "${data.aws_snowball_job.#{name}.id}",
            job_state: "${data.aws_snowball_job.#{name}.job_state}",
            snowball_type: "${data.aws_snowball_job.#{name}.snowball_type}",
            shipping_details: "${data.aws_snowball_job.#{name}.shipping_details}"
          }
        )
      end
      
      # Create a Snowmobile job for exabyte-scale data transfer
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Snowmobile job attributes
      # @option attributes [Hash] :resources (required) Resources configuration with S3 buckets
      # @option attributes [String] :description Job description
      # @option attributes [String] :role_arn Role ARN for Snowmobile operations
      # @option attributes [Hash] :shipping_details Shipping and site details
      # @return [ResourceReference] Reference object with outputs
      def aws_snowmobile_job(name, attributes = {})
        required_attrs = %i[resources]
        optional_attrs = {
          description: nil,
          role_arn: nil,
          shipping_details: {}
        }
        
        job_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless job_attrs.key?(attr)
        end
        
        resource(:aws_snowmobile_job, name) do
          job_type "EXPORT"  # Snowmobile is typically for export jobs
          resources job_attrs[:resources]
          description job_attrs[:description] if job_attrs[:description]
          role_arn job_attrs[:role_arn] if job_attrs[:role_arn]
          snowball_type "SNOWMOBILE"
          
          if job_attrs[:shipping_details].any?
            shipping_details job_attrs[:shipping_details]
          end
        end
        
        ResourceReference.new(
          type: 'aws_snowmobile_job',
          name: name,
          resource_attributes: job_attrs,
          outputs: {
            id: "${aws_snowmobile_job.#{name}.id}",
            arn: "${aws_snowmobile_job.#{name}.arn}",
            job_state: "${aws_snowmobile_job.#{name}.job_state}",
            capacity: "${aws_snowmobile_job.#{name}.capacity}"
          }
        )
      end
      
      # Create a DataSync on Snow task
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] DataSync task attributes
      # @option attributes [String] :source_location_arn (required) Source location ARN
      # @option attributes [String] :destination_location_arn (required) Destination location ARN
      # @option attributes [String] :name Task name
      # @option attributes [Hash] :options Sync options
      # @option attributes [Hash] :schedule Task schedule
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_datasync_on_snow_task(name, attributes = {})
        required_attrs = %i[source_location_arn destination_location_arn]
        optional_attrs = {
          name: nil,
          options: {},
          schedule: {},
          tags: {}
        }
        
        task_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless task_attrs.key?(attr)
        end
        
        resource(:aws_datasync_task, name) do
          source_location_arn task_attrs[:source_location_arn]
          destination_location_arn task_attrs[:destination_location_arn]
          name task_attrs[:name] if task_attrs[:name]
          
          if task_attrs[:options].any?
            options task_attrs[:options]
          end
          
          if task_attrs[:schedule].any?
            schedule task_attrs[:schedule]
          end
          
          if task_attrs[:tags].any?
            tags task_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_datasync_task',
          name: name,
          resource_attributes: task_attrs,
          outputs: {
            id: "${aws_datasync_task.#{name}.id}",
            arn: "${aws_datasync_task.#{name}.arn}",
            current_task_execution_arn: "${aws_datasync_task.#{name}.current_task_execution_arn}"
          }
        )
      end
      
      # Create a DataSync location for Snow devices
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Location attributes
      # @option attributes [String] :agent_arns (required) Agent ARNs for Snow device
      # @option attributes [String] :server_hostname Server hostname on Snow device
      # @option attributes [String] :subdirectory Subdirectory path
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_datasync_on_snow_location(name, attributes = {})
        required_attrs = %i[agent_arns]
        optional_attrs = {
          server_hostname: nil,
          subdirectory: "/",
          tags: {}
        }
        
        location_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless location_attrs.key?(attr)
        end
        
        resource(:aws_datasync_location_nfs, name) do
          server_hostname location_attrs[:server_hostname] if location_attrs[:server_hostname]
          subdirectory location_attrs[:subdirectory]
          
          on_prem_config do
            agent_arns location_attrs[:agent_arns]
          end
          
          if location_attrs[:tags].any?
            tags location_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_datasync_location_nfs',
          name: name,
          resource_attributes: location_attrs,
          outputs: {
            id: "${aws_datasync_location_nfs.#{name}.id}",
            arn: "${aws_datasync_location_nfs.#{name}.arn}",
            uri: "${aws_datasync_location_nfs.#{name}.uri}"
          }
        )
      end
      
      # Query DataSync agent on Snow Ball Edge
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Agent attributes
      # @option attributes [String] :ip_address Snow Ball Edge IP address
      # @option attributes [String] :activation_key Agent activation key
      # @return [ResourceReference] Reference object with outputs
      def aws_datasync_snow_ball_edge(name, attributes = {})
        optional_attrs = {
          ip_address: nil,
          activation_key: nil
        }
        
        agent_attrs = optional_attrs.merge(attributes)
        
        resource(:aws_datasync_agent, name) do
          ip_address agent_attrs[:ip_address] if agent_attrs[:ip_address]
          activation_key agent_attrs[:activation_key] if agent_attrs[:activation_key]
        end
        
        ResourceReference.new(
          type: 'aws_datasync_agent',
          name: name,
          resource_attributes: agent_attrs,
          outputs: {
            id: "${aws_datasync_agent.#{name}.id}",
            arn: "${aws_datasync_agent.#{name}.arn}",
            name: "${aws_datasync_agent.#{name}.name}",
            status: "${aws_datasync_agent.#{name}.status}"
          }
        )
      end
    end
  end
end