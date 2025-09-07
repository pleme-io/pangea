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


module Pangea
  module Resources
    module AWS
      # AWS Lightsail - Simple virtual private servers and containers
      # Lightsail provides easy-to-use cloud platform that offers everything needed to build an application or website
      
      # Create a Lightsail instance (virtual private server)
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Instance attributes
      # @option attributes [String] :availability_zone (required) The availability zone
      # @option attributes [String] :blueprint_id (required) The blueprint ID (e.g., "wordpress", "lamp_7", "ubuntu_20_04")
      # @option attributes [String] :bundle_id (required) The bundle ID (e.g., "nano_2_0", "micro_2_0", "small_2_0")
      # @option attributes [String] :key_pair_name The key pair name
      # @option attributes [String] :user_data The user data script
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_instance(name, attributes = {})
        required_attrs = %i[availability_zone blueprint_id bundle_id]
        optional_attrs = {
          key_pair_name: nil,
          user_data: nil,
          tags: {}
        }
        
        instance_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless instance_attrs.key?(attr)
        end
        
        resource(:aws_lightsail_instance, name) do
          availability_zone instance_attrs[:availability_zone]
          blueprint_id instance_attrs[:blueprint_id]
          bundle_id instance_attrs[:bundle_id]
          key_pair_name instance_attrs[:key_pair_name] if instance_attrs[:key_pair_name]
          user_data instance_attrs[:user_data] if instance_attrs[:user_data]
          
          if instance_attrs[:tags].any?
            tags instance_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_instance',
          name: name,
          resource_attributes: instance_attrs,
          outputs: {
            id: "${aws_lightsail_instance.#{name}.id}",
            arn: "${aws_lightsail_instance.#{name}.arn}",
            public_ip_address: "${aws_lightsail_instance.#{name}.public_ip_address}",
            private_ip_address: "${aws_lightsail_instance.#{name}.private_ip_address}",
            is_static_ip: "${aws_lightsail_instance.#{name}.is_static_ip}",
            username: "${aws_lightsail_instance.#{name}.username}",
            availability_zone: "${aws_lightsail_instance.#{name}.availability_zone}"
          }
        )
      end
      
      # Create a Lightsail key pair for SSH access
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Key pair attributes
      # @option attributes [String] :public_key The public key material (if importing)
      # @option attributes [String] :key_pair_name Override the key pair name
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_key_pair(name, attributes = {})
        optional_attrs = {
          public_key: nil,
          key_pair_name: nil,
          tags: {}
        }
        
        key_attrs = optional_attrs.merge(attributes)
        
        resource(:aws_lightsail_key_pair, name) do
          key_pair_name key_attrs[:key_pair_name] if key_attrs[:key_pair_name]
          public_key key_attrs[:public_key] if key_attrs[:public_key]
          
          if key_attrs[:tags].any?
            tags key_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_key_pair',
          name: name,
          resource_attributes: key_attrs,
          outputs: {
            id: "${aws_lightsail_key_pair.#{name}.id}",
            arn: "${aws_lightsail_key_pair.#{name}.arn}",
            name: "${aws_lightsail_key_pair.#{name}.name}",
            fingerprint: "${aws_lightsail_key_pair.#{name}.fingerprint}",
            public_key: "${aws_lightsail_key_pair.#{name}.public_key}",
            private_key: "${aws_lightsail_key_pair.#{name}.private_key}"
          }
        )
      end
      
      # Create a Lightsail static IP
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Static IP attributes
      # @option attributes [String] :static_ip_name Override the static IP name
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_static_ip(name, attributes = {})
        optional_attrs = {
          static_ip_name: nil
        }
        
        ip_attrs = optional_attrs.merge(attributes)
        
        resource(:aws_lightsail_static_ip, name) do
          static_ip_name ip_attrs[:static_ip_name] if ip_attrs[:static_ip_name]
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_static_ip',
          name: name,
          resource_attributes: ip_attrs,
          outputs: {
            id: "${aws_lightsail_static_ip.#{name}.id}",
            arn: "${aws_lightsail_static_ip.#{name}.arn}",
            ip_address: "${aws_lightsail_static_ip.#{name}.ip_address}",
            support_code: "${aws_lightsail_static_ip.#{name}.support_code}"
          }
        )
      end
      
      # Attach a static IP to a Lightsail instance
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Attachment attributes
      # @option attributes [String] :static_ip_name (required) The static IP name
      # @option attributes [String] :instance_name (required) The instance name
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_static_ip_attachment(name, attributes = {})
        required_attrs = %i[static_ip_name instance_name]
        
        attach_attrs = attributes
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless attach_attrs.key?(attr)
        end
        
        resource(:aws_lightsail_static_ip_attachment, name) do
          static_ip_name attach_attrs[:static_ip_name]
          instance_name attach_attrs[:instance_name]
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_static_ip_attachment',
          name: name,
          resource_attributes: attach_attrs,
          outputs: {
            id: "${aws_lightsail_static_ip_attachment.#{name}.id}",
            ip_address: "${aws_lightsail_static_ip_attachment.#{name}.ip_address}"
          }
        )
      end
      
      # Create a Lightsail domain
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Domain attributes
      # @option attributes [String] :domain_name (required) The domain name
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_domain(name, attributes = {})
        required_attrs = %i[domain_name]
        optional_attrs = {
          tags: {}
        }
        
        domain_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless domain_attrs.key?(attr)
        end
        
        resource(:aws_lightsail_domain, name) do
          domain_name domain_attrs[:domain_name]
          
          if domain_attrs[:tags].any?
            tags domain_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_domain',
          name: name,
          resource_attributes: domain_attrs,
          outputs: {
            id: "${aws_lightsail_domain.#{name}.id}",
            arn: "${aws_lightsail_domain.#{name}.arn}",
            domain_name: "${aws_lightsail_domain.#{name}.domain_name}"
          }
        )
      end
      
      # Create a Lightsail disk
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Disk attributes
      # @option attributes [String] :availability_zone (required) The availability zone
      # @option attributes [Integer] :size_in_gb (required) The size in GB
      # @option attributes [String] :disk_name Override the disk name
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_disk(name, attributes = {})
        required_attrs = %i[availability_zone size_in_gb]
        optional_attrs = {
          disk_name: nil,
          tags: {}
        }
        
        disk_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless disk_attrs.key?(attr)
        end
        
        resource(:aws_lightsail_disk, name) do
          availability_zone disk_attrs[:availability_zone]
          size_in_gb disk_attrs[:size_in_gb]
          disk_name disk_attrs[:disk_name] if disk_attrs[:disk_name]
          
          if disk_attrs[:tags].any?
            tags disk_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_disk',
          name: name,
          resource_attributes: disk_attrs,
          outputs: {
            id: "${aws_lightsail_disk.#{name}.id}",
            arn: "${aws_lightsail_disk.#{name}.arn}",
            name: "${aws_lightsail_disk.#{name}.name}",
            support_code: "${aws_lightsail_disk.#{name}.support_code}",
            availability_zone: "${aws_lightsail_disk.#{name}.availability_zone}",
            size_in_gb: "${aws_lightsail_disk.#{name}.size_in_gb}"
          }
        )
      end
      
      # Attach a disk to a Lightsail instance
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Attachment attributes
      # @option attributes [String] :disk_name (required) The disk name
      # @option attributes [String] :instance_name (required) The instance name
      # @option attributes [String] :disk_path (required) The disk path
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_disk_attachment(name, attributes = {})
        required_attrs = %i[disk_name instance_name disk_path]
        
        attach_attrs = attributes
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless attach_attrs.key?(attr)
        end
        
        resource(:aws_lightsail_disk_attachment, name) do
          disk_name attach_attrs[:disk_name]
          instance_name attach_attrs[:instance_name]
          disk_path attach_attrs[:disk_path]
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_disk_attachment',
          name: name,
          resource_attributes: attach_attrs,
          outputs: {
            id: "${aws_lightsail_disk_attachment.#{name}.id}"
          }
        )
      end
      
      # Create a Lightsail load balancer
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Load balancer attributes
      # @option attributes [String] :lb_name Override the load balancer name
      # @option attributes [Integer] :instance_port Instance port (default: 80)
      # @option attributes [String] :health_check_path Health check path (default: "/")
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_load_balancer(name, attributes = {})
        optional_attrs = {
          lb_name: nil,
          instance_port: 80,
          health_check_path: "/",
          tags: {}
        }
        
        lb_attrs = optional_attrs.merge(attributes)
        
        resource(:aws_lightsail_load_balancer, name) do
          name lb_attrs[:lb_name] if lb_attrs[:lb_name]
          instance_port lb_attrs[:instance_port]
          health_check_path lb_attrs[:health_check_path]
          
          if lb_attrs[:tags].any?
            tags lb_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_load_balancer',
          name: name,
          resource_attributes: lb_attrs,
          outputs: {
            id: "${aws_lightsail_load_balancer.#{name}.id}",
            arn: "${aws_lightsail_load_balancer.#{name}.arn}",
            dns_name: "${aws_lightsail_load_balancer.#{name}.dns_name}",
            protocol: "${aws_lightsail_load_balancer.#{name}.protocol}",
            public_ports: "${aws_lightsail_load_balancer.#{name}.public_ports}"
          }
        )
      end
      
      # Attach instances to a Lightsail load balancer
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Attachment attributes
      # @option attributes [String] :load_balancer_name (required) The load balancer name
      # @option attributes [Array<String>] :instance_names (required) The instance names
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_load_balancer_attachment(name, attributes = {})
        required_attrs = %i[load_balancer_name instance_names]
        
        attach_attrs = attributes
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless attach_attrs.key?(attr)
        end
        
        resource(:aws_lightsail_load_balancer_attachment, name) do
          load_balancer_name attach_attrs[:load_balancer_name]
          instance_names attach_attrs[:instance_names]
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_load_balancer_attachment',
          name: name,
          resource_attributes: attach_attrs,
          outputs: {
            id: "${aws_lightsail_load_balancer_attachment.#{name}.id}"
          }
        )
      end
      
      # Create a Lightsail certificate
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Certificate attributes
      # @option attributes [String] :certificate_name (required) The certificate name
      # @option attributes [String] :domain_name (required) The domain name
      # @option attributes [Array<String>] :subject_alternative_names Subject alternative names
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_certificate(name, attributes = {})
        required_attrs = %i[certificate_name domain_name]
        optional_attrs = {
          subject_alternative_names: [],
          tags: {}
        }
        
        cert_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless cert_attrs.key?(attr)
        end
        
        resource(:aws_lightsail_certificate, name) do
          certificate_name cert_attrs[:certificate_name]
          domain_name cert_attrs[:domain_name]
          subject_alternative_names cert_attrs[:subject_alternative_names] if cert_attrs[:subject_alternative_names].any?
          
          if cert_attrs[:tags].any?
            tags cert_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_certificate',
          name: name,
          resource_attributes: cert_attrs,
          outputs: {
            id: "${aws_lightsail_certificate.#{name}.id}",
            arn: "${aws_lightsail_certificate.#{name}.arn}",
            created_at: "${aws_lightsail_certificate.#{name}.created_at}",
            domain_validation_options: "${aws_lightsail_certificate.#{name}.domain_validation_options}"
          }
        )
      end
      
      # Create a Lightsail database
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Database attributes
      # @option attributes [String] :relational_database_blueprint_id (required) Blueprint ID (e.g., "mysql_8_0", "postgres_12")
      # @option attributes [String] :relational_database_bundle_id (required) Bundle ID (e.g., "micro_1_0", "small_1_0")
      # @option attributes [String] :master_database_name (required) Master database name
      # @option attributes [String] :master_username (required) Master username
      # @option attributes [String] :master_password Master password (auto-generated if not specified)
      # @option attributes [String] :availability_zone Availability zone
      # @option attributes [Boolean] :skip_final_snapshot Skip final snapshot (default: false)
      # @option attributes [String] :final_snapshot_name Final snapshot name
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_database(name, attributes = {})
        required_attrs = %i[relational_database_blueprint_id relational_database_bundle_id master_database_name master_username]
        optional_attrs = {
          master_password: nil,
          availability_zone: nil,
          skip_final_snapshot: false,
          final_snapshot_name: nil,
          tags: {}
        }
        
        db_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless db_attrs.key?(attr)
        end
        
        resource(:aws_lightsail_database, name) do
          relational_database_blueprint_id db_attrs[:relational_database_blueprint_id]
          relational_database_bundle_id db_attrs[:relational_database_bundle_id]
          master_database_name db_attrs[:master_database_name]
          master_username db_attrs[:master_username]
          master_password db_attrs[:master_password] if db_attrs[:master_password]
          availability_zone db_attrs[:availability_zone] if db_attrs[:availability_zone]
          skip_final_snapshot db_attrs[:skip_final_snapshot]
          final_snapshot_name db_attrs[:final_snapshot_name] if db_attrs[:final_snapshot_name]
          
          if db_attrs[:tags].any?
            tags db_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_database',
          name: name,
          resource_attributes: db_attrs,
          outputs: {
            id: "${aws_lightsail_database.#{name}.id}",
            arn: "${aws_lightsail_database.#{name}.arn}",
            master_endpoint_address: "${aws_lightsail_database.#{name}.master_endpoint_address}",
            master_endpoint_port: "${aws_lightsail_database.#{name}.master_endpoint_port}",
            engine: "${aws_lightsail_database.#{name}.engine}",
            engine_version: "${aws_lightsail_database.#{name}.engine_version}"
          }
        )
      end
      
      # Create a Lightsail bucket (object storage)
      #
      # @param name [Symbol] The resource name
      # @param attributes [Hash] Bucket attributes
      # @option attributes [String] :bucket_name (required) The bucket name
      # @option attributes [String] :bundle_id (required) Bundle ID (e.g., "small_1_0", "medium_1_0", "large_1_0")
      # @option attributes [Boolean] :force_delete Force delete bucket and contents (default: false)
      # @option attributes [Hash<String,String>] :tags Resource tags
      # @return [ResourceReference] Reference object with outputs
      def aws_lightsail_bucket(name, attributes = {})
        required_attrs = %i[bucket_name bundle_id]
        optional_attrs = {
          force_delete: false,
          tags: {}
        }
        
        bucket_attrs = optional_attrs.merge(attributes)
        
        required_attrs.each do |attr|
          raise ArgumentError, "Missing required attribute: #{attr}" unless bucket_attrs.key?(attr)
        end
        
        resource(:aws_lightsail_bucket, name) do
          bucket_name bucket_attrs[:bucket_name]
          bundle_id bucket_attrs[:bundle_id]
          force_delete bucket_attrs[:force_delete]
          
          if bucket_attrs[:tags].any?
            tags bucket_attrs[:tags]
          end
        end
        
        ResourceReference.new(
          type: 'aws_lightsail_bucket',
          name: name,
          resource_attributes: bucket_attrs,
          outputs: {
            id: "${aws_lightsail_bucket.#{name}.id}",
            arn: "${aws_lightsail_bucket.#{name}.arn}",
            availability_zone: "${aws_lightsail_bucket.#{name}.availability_zone}",
            region: "${aws_lightsail_bucket.#{name}.region}",
            url: "${aws_lightsail_bucket.#{name}.url}"
          }
        )
      end
    end
  end
end