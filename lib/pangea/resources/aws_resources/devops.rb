# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

# AWS DevOps resources - CodeCommit, CodeBuild, CodeDeploy, CodePipeline, ECR
require 'pangea/resources/aws_codecommit_repository/resource'
require 'pangea/resources/aws_codebuild_project/resource'
require 'pangea/resources/aws_codedeploy_application/resource'
require 'pangea/resources/aws_codedeploy_deployment_group/resource'
require 'pangea/resources/aws_codedeploy_deployment_config/resource'
require 'pangea/resources/aws_codepipeline/resource'
require 'pangea/resources/aws_codepipeline_webhook/resource'
require 'pangea/resources/aws_ecr_repository/resource'
require 'pangea/resources/aws_ecr_repository_policy/resource'
require 'pangea/resources/aws_ecr_lifecycle_policy/resource'
require 'pangea/resources/aws_ecr_replication_configuration/resource'
require 'pangea/resources/aws_codeartifact_domain/resource'
require 'pangea/resources/aws_codeartifact_repository/resource'
require 'pangea/resources/aws_codestar_connection/resource'
