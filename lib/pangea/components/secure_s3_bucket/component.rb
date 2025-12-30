# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

require 'pangea/components/base'
require 'pangea/components/secure_s3_bucket/types'
require 'pangea/resources/aws'
require 'json'
require_relative 'component/bucket_config'
require_relative 'component/features'
require_relative 'component/monitoring'
require_relative 'component/outputs'

module Pangea
  module Components
    include SecureS3BucketComponent::BucketConfig
    include SecureS3BucketComponent::Features
    include SecureS3BucketComponent::Monitoring
    include SecureS3BucketComponent::Outputs

    def secure_s3_bucket(name, attributes = {})
      include Base
      include Resources::AWS

      component_attrs = SecureS3Bucket::SecureS3BucketAttributes.new(attributes)
      component_tag_set = component_tags('SecureS3Bucket', name, component_attrs.tags)
      resources = {}

      bucket_ref = create_bucket(name, component_attrs, component_tag_set)
      resources[:bucket] = bucket_ref
      resources[:versioning] = configure_versioning(name, bucket_ref, component_attrs)
      resources[:encryption] = configure_encryption(name, bucket_ref, component_attrs)
      resources[:public_access_block] = configure_public_access(name, bucket_ref, component_attrs)
      resources[:lifecycle] = configure_lifecycle(name, bucket_ref, component_attrs)
      resources[:policy] = configure_policy(name, bucket_ref, component_attrs)
      resources[:cors] = configure_cors(name, bucket_ref, component_attrs)
      resources[:logging] = configure_logging(name, bucket_ref, component_attrs)
      resources[:acceleration] = configure_acceleration(name, bucket_ref, component_attrs)
      resources[:request_payer] = configure_request_payer(name, bucket_ref, component_attrs)
      resources[:website] = configure_website(name, bucket_ref, component_attrs)
      resources[:object_lock] = configure_object_lock(name, bucket_ref, component_attrs)
      resources[:notification] = configure_notifications(name, bucket_ref, component_attrs)
      resources[:replication] = configure_replication(name, bucket_ref, component_attrs)
      resources[:analytics] = configure_analytics(name, bucket_ref, component_attrs)
      resources[:inventory] = configure_inventory(name, bucket_ref, component_attrs)
      resources[:alarms] = configure_alarms(name, bucket_ref, component_attrs, component_tag_set)

      resources.compact!
      outputs = calculate_outputs(bucket_ref, component_attrs)
      create_component_reference('secure_s3_bucket', name, component_attrs.to_h, resources, outputs)
    end

    private

    def configure_request_payer(name, bucket_ref, component_attrs)
      return nil if component_attrs.request_payer == 'BucketOwner'
      aws_s3_bucket_request_payment_configuration(component_resource_name(name, :request_payer), { bucket: bucket_ref.id, payer: component_attrs.request_payer })
    end
  end
end
