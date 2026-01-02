# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

# AWS Governance resources - Service Catalog, Control Tower, Well-Architected, Migration
require 'pangea/resources/aws/servicecatalog/portfolio_resource'
require 'pangea/resources/aws/servicecatalog/product_resource'
require 'pangea/resources/aws/servicecatalog/constraint_resource'
require 'pangea/resources/aws/servicecatalog/principal_portfolio_association_resource'
require 'pangea/resources/aws/servicecatalog/product_portfolio_association_resource'
require 'pangea/resources/aws/servicecatalog/provisioned_product_resource'
require 'pangea/resources/aws/servicecatalog/tag_option_resource'
require 'pangea/resources/aws/servicecatalog/tag_option_resource_association_resource'
require 'pangea/resources/aws/controltower/control_resource'
require 'pangea/resources/aws/controltower/landing_zone_resource'
require 'pangea/resources/aws/wellarchitected/workload_resource'
require 'pangea/resources/aws/ssm/maintenance_window_task_resource'
require 'pangea/resources/aws/ssm/maintenance_window_target_resource'
require 'pangea/resources/aws/applicationdiscoveryservice/application_resource'
require 'pangea/resources/aws/migrationhub/progress_update_stream_resource'
