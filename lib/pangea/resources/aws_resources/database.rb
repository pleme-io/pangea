# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

# AWS Database resources - RDS, DynamoDB, ElastiCache, Redshift
require 'pangea/resources/aws_db_instance/resource'
require 'pangea/resources/aws_db_subnet_group/resource'
require 'pangea/resources/aws_db_parameter_group/resource'
require 'pangea/resources/aws_rds_cluster/resource'
require 'pangea/resources/aws_rds_cluster_instance/resource'
require 'pangea/resources/aws_rds_cluster_endpoint/resource'
require 'pangea/resources/aws_rds_cluster_parameter_group/resource'
require 'pangea/resources/aws_rds_global_cluster/resource'
require 'pangea/resources/aws_rds_proxy/resource'
require 'pangea/resources/aws_rds_proxy_default_target_group/resource'
require 'pangea/resources/aws_rds_proxy_target/resource'
require 'pangea/resources/aws_db_snapshot/resource'
require 'pangea/resources/aws_db_cluster_snapshot/resource'
require 'pangea/resources/aws_dynamodb_table/resource'
require 'pangea/resources/aws_dynamodb_global_table/resource'
require 'pangea/resources/aws_elasticache_cluster/resource'
require 'pangea/resources/aws_elasticache_subnet_group/resource'
require 'pangea/resources/aws_elasticache_parameter_group/resource'
require 'pangea/resources/aws_redshift_cluster/resource'
require 'pangea/resources/aws_redshift_subnet_group/resource'
require 'pangea/resources/aws_redshift_parameter_group/resource'
require 'pangea/resources/aws_redshift_snapshot_schedule/resource'
