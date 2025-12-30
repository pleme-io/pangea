# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

# AWS Storage resources - S3, EBS, EFS
require 'pangea/resources/aws_s3_bucket/resource'
require 'pangea/resources/aws_s3_bucket_policy/resource'
require 'pangea/resources/aws_s3_bucket_versioning/resource'
require 'pangea/resources/aws_s3_bucket_encryption/resource'
require 'pangea/resources/aws_s3_bucket_public_access_block/resource'
require 'pangea/resources/aws_s3_object/resource'
require 'pangea/resources/aws_s3_bucket_lifecycle_configuration/resource'
require 'pangea/resources/aws_s3_bucket_cors_configuration/resource'
require 'pangea/resources/aws_s3_bucket_website_configuration/resource'
require 'pangea/resources/aws_s3_bucket_notification/resource'
require 'pangea/resources/aws_s3_bucket_inventory/resource'
require 'pangea/resources/aws_s3_bucket_replication_configuration/resource'
require 'pangea/resources/aws_s3_bucket_object_lock_configuration/resource'
require 'pangea/resources/aws_ebs_volume/resource'
require 'pangea/resources/aws_volume_attachment/resource'
require 'pangea/resources/aws_efs_file_system/resource'
require 'pangea/resources/aws_efs_mount_target/resource'
require 'pangea/resources/aws_efs_access_point/resource'
