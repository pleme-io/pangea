# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

# AWS Analytics resources - Kinesis, Glue, EMR, Athena, Batch
require 'pangea/resources/aws_kinesis_stream/resource'
require 'pangea/resources/aws_kinesis_firehose_delivery_stream/resource'
require 'pangea/resources/aws_kinesis_analytics_application/resource'
require 'pangea/resources/aws_kinesis_video_stream/resource'
require 'pangea/resources/aws_glue_catalog_database/resource'
require 'pangea/resources/aws_glue_catalog_table/resource'
require 'pangea/resources/aws_glue_job/resource'
require 'pangea/resources/aws_glue_trigger/resource'
require 'pangea/resources/aws_emr_cluster/resource'
require 'pangea/resources/aws_emr_instance_group/resource'
require 'pangea/resources/aws_emr_step/resource'
require 'pangea/resources/aws_athena_database/resource'
require 'pangea/resources/aws_athena_workgroup/resource'
require 'pangea/resources/aws_athena_named_query/resource'
require 'pangea/resources/aws_batch_compute_environment/resource'
require 'pangea/resources/aws_batch_job_queue/resource'
require 'pangea/resources/aws_batch_job_definition/resource'
