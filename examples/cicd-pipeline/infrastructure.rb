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

# Example: CI/CD Pipeline Infrastructure
# This example demonstrates a complete CI/CD pipeline infrastructure using:
# - CodeCommit for source code management
# - CodeBuild for build and test automation
# - CodePipeline for deployment orchestration
# - CodeDeploy for application deployment
# - Artifact storage and management
# - Multi-environment promotion workflow

# Template 1: Source Control and Artifact Management
template :source_and_artifacts do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "CICD-Pipeline"
        Template "source_and_artifacts"
      end
    end
  end
  
  # CodeCommit repository for source code
  source_repo = resource :aws_codecommit_repository, :main do
    repository_name "application-source-#{namespace}"
    description "Main application source repository"
    
    tags do
      Name "CICD-SourceRepo-#{namespace}"
      Purpose "SourceControl"
    end
  end
  
  # S3 bucket for CI/CD artifacts
  artifact_bucket = resource :aws_s3_bucket, :artifacts do
    bucket "cicd-artifacts-#{namespace}-#{SecureRandom.hex(8)}"
    
    tags do
      Name "CICD-ArtifactsBucket-#{namespace}"
      Purpose "ArtifactStorage"
    end
  end
  
  # S3 bucket versioning
  resource :aws_s3_bucket_versioning, :artifacts do
    bucket ref(:aws_s3_bucket, :artifacts, :id)
    versioning_configuration do
      status "Enabled"
    end
  end
  
  # S3 bucket encryption
  resource :aws_s3_bucket_server_side_encryption_configuration, :artifacts do
    bucket ref(:aws_s3_bucket, :artifacts, :id)
    
    rule do
      apply_server_side_encryption_by_default do
        sse_algorithm "aws:kms"
        kms_master_key_id ref(:aws_kms_key, :cicd_encryption, :arn)
      end
      bucket_key_enabled true
    end
  end
  
  # Block public access to artifacts bucket
  resource :aws_s3_bucket_public_access_block, :artifacts do
    bucket ref(:aws_s3_bucket, :artifacts, :id)
    
    block_public_acls true
    block_public_policy true
    ignore_public_acls true
    restrict_public_buckets true
  end
  
  # S3 lifecycle configuration for artifact cleanup
  resource :aws_s3_bucket_lifecycle_configuration, :artifacts do
    bucket ref(:aws_s3_bucket, :artifacts, :id)
    
    rule do
      id "artifact_cleanup"
      status "Enabled"
      
      filter do
        prefix "builds/"
      end
      
      expiration do
        days 30
      end
      
      noncurrent_version_expiration do
        noncurrent_days 7
      end
    end
    
    rule do
      id "temp_artifact_cleanup"
      status "Enabled"
      
      filter do
        prefix "temp/"
      end
      
      expiration do
        days 7
      end
    end
  end
  
  # KMS key for CI/CD encryption
  cicd_kms_key = resource :aws_kms_key, :cicd_encryption do
    description "KMS key for CI/CD pipeline encryption"
    deletion_window_in_days 7
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Principal: { AWS: "arn:aws:iam::#{data(:aws_caller_identity, :current, :account_id)}:root" },
          Action: "kms:*",
          Resource: "*"
        },
        {
          Effect: "Allow",
          Principal: { Service: [
            "codebuild.amazonaws.com",
            "codepipeline.amazonaws.com",
            "s3.amazonaws.com"
          ]},
          Action: [
            "kms:Decrypt",
            "kms:EncryptionContext",
            "kms:GenerateDataKey*",
            "kms:ReEncrypt*"
          ],
          Resource: "*"
        }
      ]
    })
    
    tags do
      Name "CICD-Encryption-Key-#{namespace}"
      Purpose "CICDSecurity"
    end
  end
  
  resource :aws_kms_alias, :cicd_encryption do
    name "alias/cicd-pipeline-#{namespace}"
    target_key_id ref(:aws_kms_key, :cicd_encryption, :key_id)
  end
  
  # ECR repository for container images
  ecr_repo = resource :aws_ecr_repository, :app do
    name "application-#{namespace}"
    image_tag_mutability "MUTABLE"
    
    image_scanning_configuration do
      scan_on_push true
    end
    
    encryption_configuration do
      encryption_type "KMS"
      kms_key ref(:aws_kms_key, :cicd_encryption, :arn)
    end
    
    tags do
      Name "CICD-ECR-Repository-#{namespace}"
      Purpose "ContainerRegistry"
    end
  end
  
  # ECR lifecycle policy
  resource :aws_ecr_lifecycle_policy, :app do
    repository ref(:aws_ecr_repository, :app, :name)
    
    policy jsonencode({
      rules: [
        {
          rulePriority: 1,
          description: "Keep last 10 production images",
          selection: {
            tagStatus: "tagged",
            tagPrefixList: ["v"],
            countType: "imageCountMoreThan",
            countNumber: 10
          },
          action: {
            type: "expire"
          }
        },
        {
          rulePriority: 2,
          description: "Keep only 5 development images",
          selection: {
            tagStatus: "tagged", 
            tagPrefixList: ["dev", "feature"],
            countType: "imageCountMoreThan",
            countNumber: 5
          },
          action: {
            type: "expire"
          }
        },
        {
          rulePriority: 3,
          description: "Delete untagged images older than 1 day",
          selection: {
            tagStatus: "untagged",
            countType: "sinceImagePushed",
            countUnit: "days",
            countNumber: 1
          },
          action: {
            type: "expire"
          }
        }
      ]
    })
  end
  
  # Get current AWS account ID
  data :aws_caller_identity, :current do
  end
  
  # CloudWatch Log Groups for CI/CD logging
  resource :aws_cloudwatch_log_group, :codebuild do
    name "/aws/codebuild/application-#{namespace}"
    retention_in_days 14
    
    tags do
      Name "CICD-CodeBuild-Logs-#{namespace}"
      Purpose "BuildLogging"
    end
  end
  
  resource :aws_cloudwatch_log_group, :codedeploy do
    name "/aws/codedeploy/application-#{namespace}"
    retention_in_days 30
    
    tags do
      Name "CICD-CodeDeploy-Logs-#{namespace}"
      Purpose "DeploymentLogging"
    end
  end
  
  # Outputs for other templates
  output :source_repository_clone_url_http do
    value ref(:aws_codecommit_repository, :main, :clone_url_http)
    description "CodeCommit repository HTTP clone URL"
  end
  
  output :source_repository_clone_url_ssh do
    value ref(:aws_codecommit_repository, :main, :clone_url_ssh)
    description "CodeCommit repository SSH clone URL"
  end
  
  output :artifact_bucket_name do
    value ref(:aws_s3_bucket, :artifacts, :bucket)
    description "S3 bucket name for CI/CD artifacts"
  end
  
  output :artifact_bucket_arn do
    value ref(:aws_s3_bucket, :artifacts, :arn)
    description "S3 bucket ARN for CI/CD artifacts"
  end
  
  output :ecr_repository_url do
    value ref(:aws_ecr_repository, :app, :repository_url)
    description "ECR repository URL for container images"
  end
  
  output :kms_key_id do
    value ref(:aws_kms_key, :cicd_encryption, :key_id)
    description "KMS key ID for CI/CD encryption"
  end
  
  output :kms_key_arn do
    value ref(:aws_kms_key, :cicd_encryption, :arn)
    description "KMS key ARN for CI/CD encryption"
  end
end

# Template 2: Build and Test Infrastructure
template :build_infrastructure do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "CICD-Pipeline"
        Template "build_infrastructure"
      end
    end
  end
  
  # Reference source and artifacts template
  data :aws_s3_bucket, :artifacts do
    filter do
      name "tag:Name"
      values ["CICD-ArtifactsBucket-#{namespace}"]
    end
  end
  
  data :aws_kms_key, :cicd_encryption do
    filter do
      name "tag:Name"
      values ["CICD-Encryption-Key-#{namespace}"]
    end
  end
  
  data :aws_ecr_repository, :app do
    filter do
      name "tag:Name"
      values ["CICD-ECR-Repository-#{namespace}"]
    end
  end
  
  # IAM role for CodeBuild
  codebuild_role = resource :aws_iam_role, :codebuild do
    name_prefix "CICD-CodeBuild-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "codebuild.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "CICD-CodeBuild-Role-#{namespace}"
      Purpose "BuildExecution"
    end
  end
  
  # CodeBuild service policy
  resource :aws_iam_role_policy, :codebuild do
    name_prefix "CICD-CodeBuild-Policy-"
    role ref(:aws_iam_role, :codebuild, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource: "arn:aws:logs:*:*:*"
        },
        {
          Effect: "Allow",
          Action: [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:PutObject"
          ],
          Resource: [
            data(:aws_s3_bucket, :artifacts, :arn),
            "#{data(:aws_s3_bucket, :artifacts, :arn)}/*"
          ]
        },
        {
          Effect: "Allow",
          Action: [
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:GetAuthorizationToken",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload"
          ],
          Resource: "*"
        },
        {
          Effect: "Allow",
          Action: [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          Resource: data(:aws_kms_key, :cicd_encryption, :arn)
        },
        {
          Effect: "Allow",
          Action: [
            "codecommit:GitPull"
          ],
          Resource: "*"
        },
        {
          Effect: "Allow",
          Action: [
            "ssm:GetParameters",
            "ssm:GetParameter",
            "ssm:GetParametersByPath"
          ],
          Resource: "arn:aws:ssm:*:*:parameter/cicd/*"
        }
      ]
    })
  end
  
  # Build environment configurations
  build_environments = {
    unit_tests: {
      name: "unit-tests",
      description: "Run unit tests and code quality checks",
      compute_type: "BUILD_GENERAL1_SMALL",
      buildspec: "buildspec-test.yml"
    },
    build_and_package: {
      name: "build-and-package", 
      description: "Build application and create deployment package",
      compute_type: "BUILD_GENERAL1_MEDIUM",
      buildspec: "buildspec-build.yml"
    },
    container_build: {
      name: "container-build",
      description: "Build and push Docker container to ECR",
      compute_type: "BUILD_GENERAL1_MEDIUM", 
      buildspec: "buildspec-container.yml",
      privileged: true
    },
    security_scan: {
      name: "security-scan",
      description: "Run security scans on code and dependencies",
      compute_type: "BUILD_GENERAL1_SMALL",
      buildspec: "buildspec-security.yml"
    }
  }
  
  # CodeBuild projects for different build types
  build_environments.each do |key, config|
    resource :"aws_codebuild_project", key do
      name "#{config[:name]}-#{namespace}"
      description config[:description]
      service_role ref(:aws_iam_role, :codebuild, :arn)
      
      artifacts do
        type "S3"
        location "#{data(:aws_s3_bucket, :artifacts, :bucket)}/#{config[:name]}"
        packaging "ZIP"
        override_artifact_name true
        encryption_key data(:aws_kms_key, :cicd_encryption, :arn)
      end
      
      environment do
        compute_type config[:compute_type]
        image "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
        type "LINUX_CONTAINER"
        image_pull_credentials_type "CODEBUILD"
        privileged_mode config[:privileged] || false
        
        environment_variable do
          name "AWS_DEFAULT_REGION"
          value "us-east-1"
        end
        
        environment_variable do
          name "AWS_ACCOUNT_ID"
          value data(:aws_caller_identity, :current, :account_id)
        end
        
        environment_variable do
          name "IMAGE_REPO_NAME"
          value data(:aws_ecr_repository, :app, :name)
        end
        
        environment_variable do
          name "IMAGE_URI"
          value data(:aws_ecr_repository, :app, :repository_url)
        end
        
        environment_variable do
          name "ENVIRONMENT"
          value namespace
        end
      end
      
      source do
        type "CODECOMMIT"
        location data(:aws_codecommit_repository, :main, :clone_url_http)
        buildspec config[:buildspec]
        git_clone_depth 1
        
        git_submodules_config do
          fetch_submodules true
        end
      end
      
      logs_config do
        cloudwatch_logs do
          group_name "/aws/codebuild/#{config[:name]}-#{namespace}"
          status "ENABLED"
        end
        
        s3_logs do
          status "ENABLED"
          location "#{data(:aws_s3_bucket, :artifacts, :bucket)}/logs/#{config[:name]}"
          encryption_key data(:aws_kms_key, :cicd_encryption, :arn)
        end
      end
      
      cache do
        type "S3"
        location "#{data(:aws_s3_bucket, :artifacts, :bucket)}/cache/#{config[:name]}"
      end
      
      tags do
        Name "CICD-CodeBuild-#{config[:name].titleize}-#{namespace}"
        Purpose "Build"
        BuildType config[:name]
      end
    end
  end
  
  # Get current AWS account and region for references
  data :aws_caller_identity, :current do
  end
  
  data :aws_codecommit_repository, :main do
    filter do
      name "tag:Name"
      values ["CICD-SourceRepo-#{namespace}"]
    end
  end
  
  # CloudWatch dashboard for build metrics
  resource :aws_cloudwatch_dashboard, :builds do
    dashboard_name "CICD-Builds-#{namespace}"
    
    dashboard_body jsonencode({
      widgets: [
        {
          type: "metric",
          x: 0,
          y: 0,
          width: 12,
          height: 6,
          properties: {
            metrics: build_environments.map { |key, config|
              ["AWS/CodeBuild", "Builds", "ProjectName", "#{config[:name]}-#{namespace}"]
            },
            view: "timeSeries",
            stacked: false,
            region: "us-east-1",
            title: "Build Executions",
            period: 300
          }
        },
        {
          type: "metric",
          x: 0,
          y: 6,
          width: 12,
          height: 6,
          properties: {
            metrics: build_environments.map { |key, config|
              ["AWS/CodeBuild", "Duration", "ProjectName", "#{config[:name]}-#{namespace}"]
            },
            view: "timeSeries",
            stacked: false,
            region: "us-east-1",
            title: "Build Duration (seconds)",
            period: 300
          }
        }
      ]
    })
  end
  
  # SNS topic for build notifications
  build_notifications = resource :aws_sns_topic, :build_notifications do
    name "cicd-build-notifications-#{namespace}"
    display_name "CI/CD Build Notifications"
    
    tags do
      Name "CICD-Build-Notifications-#{namespace}"
      Purpose "BuildAlerts"
    end
  end
  
  # CloudWatch alarms for build failures
  build_environments.each do |key, config|
    resource :"aws_cloudwatch_metric_alarm", :"build_failure_#{key}" do
      alarm_name "cicd-build-failure-#{config[:name]}-#{namespace}"
      alarm_description "Build failures for #{config[:description]}"
      comparison_operator "GreaterThanThreshold"
      evaluation_periods 1
      metric_name "FailedBuilds"
      namespace "AWS/CodeBuild"
      period 300
      statistic "Sum"
      threshold 0
      treat_missing_data "notBreaching"
      alarm_actions [ref(:aws_sns_topic, :build_notifications, :arn)]
      
      dimensions do
        ProjectName "#{config[:name]}-#{namespace}"
      end
      
      tags do
        Name "CICD-BuildFailure-#{config[:name].titleize}-#{namespace}"
        AlertType "BuildFailure"
      end
    end
  end
  
  # Outputs
  output :codebuild_projects do
    value build_environments.transform_values { |config|
      "#{config[:name]}-#{namespace}"
    }
    description "CodeBuild project names"
  end
  
  output :build_notifications_topic_arn do
    value ref(:aws_sns_topic, :build_notifications, :arn)
    description "SNS topic ARN for build notifications"
  end
end

# Template 3: Deployment Pipeline
template :deployment_pipeline do
  provider :aws do
    region "us-east-1"
    
    default_tags do
      tags do
        ManagedBy "Pangea"
        Environment namespace
        Project "CICD-Pipeline"
        Template "deployment_pipeline"
      end
    end
  end
  
  # Reference previous templates
  data :aws_s3_bucket, :artifacts do
    filter do
      name "tag:Name"
      values ["CICD-ArtifactsBucket-#{namespace}"]
    end
  end
  
  data :aws_kms_key, :cicd_encryption do
    filter do
      name "tag:Name"
      values ["CICD-Encryption-Key-#{namespace}"]
    end
  end
  
  data :aws_codecommit_repository, :main do
    filter do
      name "tag:Name"
      values ["CICD-SourceRepo-#{namespace}"]
    end
  end
  
  # IAM role for CodePipeline
  codepipeline_role = resource :aws_iam_role, :codepipeline do
    name_prefix "CICD-CodePipeline-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "codepipeline.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "CICD-CodePipeline-Role-#{namespace}"
      Purpose "PipelineExecution"
    end
  end
  
  # CodePipeline policy
  resource :aws_iam_role_policy, :codepipeline do
    name_prefix "CICD-CodePipeline-Policy-"
    role ref(:aws_iam_role, :codepipeline, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "s3:GetBucketVersioning",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:PutObject"
          ],
          Resource: [
            data(:aws_s3_bucket, :artifacts, :arn),
            "#{data(:aws_s3_bucket, :artifacts, :arn)}/*"
          ]
        },
        {
          Effect: "Allow",
          Action: [
            "codecommit:CancelUploadArchive",
            "codecommit:GetBranch",
            "codecommit:GetCommit", 
            "codecommit:GetUploadArchiveStatus",
            "codecommit:UploadArchive"
          ],
          Resource: "*"
        },
        {
          Effect: "Allow",
          Action: [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild"
          ],
          Resource: "*"
        },
        {
          Effect: "Allow",
          Action: [
            "codedeploy:CreateDeployment",
            "codedeploy:GetApplication",
            "codedeploy:GetApplicationRevision",
            "codedeploy:GetDeployment",
            "codedeploy:GetDeploymentConfig",
            "codedeploy:RegisterApplicationRevision"
          ],
          Resource: "*"
        },
        {
          Effect: "Allow",
          Action: [
            "kms:Decrypt",
            "kms:GenerateDataKey"
          ],
          Resource: data(:aws_kms_key, :cicd_encryption, :arn)
        },
        {
          Effect: "Allow",
          Action: [
            "sns:Publish"
          ],
          Resource: "*"
        }
      ]
    })
  end
  
  # CodeDeploy application
  codedeploy_app = resource :aws_codedeploy_app, :main do
    compute_platform "Server"
    name "application-#{namespace}"
    
    tags do
      Name "CICD-CodeDeploy-App-#{namespace}"
      Purpose "ApplicationDeployment"
    end
  end
  
  # CodeDeploy deployment group for different environments
  deployment_configs = {
    development: "CodeDeployDefault.AllAtOneInstances",
    staging: "CodeDeployDefault.AllAtOneInstances", 
    production: "CodeDeployDefault.OneAtATimeInstances"
  }
  
  # IAM role for CodeDeploy
  codedeploy_role = resource :aws_iam_role, :codedeploy do
    name_prefix "CICD-CodeDeploy-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "codedeploy.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "CICD-CodeDeploy-Role-#{namespace}"
      Purpose "DeploymentExecution"
    end
  end
  
  # Attach CodeDeploy service role policy
  resource :aws_iam_role_policy_attachment, :codedeploy do
    policy_arn "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
    role ref(:aws_iam_role, :codedeploy, :name)
  end
  
  # CodeDeploy deployment group
  deployment_group = resource :aws_codedeploy_deployment_group, :main do
    app_name ref(:aws_codedeploy_app, :main, :name)
    deployment_group_name "#{namespace}-deployment-group"
    service_role_arn ref(:aws_iam_role, :codedeploy, :arn)
    deployment_config_name deployment_configs[namespace.to_sym] || deployment_configs[:development]
    
    # Auto scaling groups (would reference actual ASGs)
    auto_scaling_groups = namespace == "production" ? ["prod-asg"] : ["#{namespace}-asg"]
    
    auto_rollback_configuration do
      enabled true
      events ["DEPLOYMENT_FAILURE"]
    end
    
    blue_green_deployment_config do
      terminate_blue_instances_on_deployment_success do
        action "TERMINATE"
        termination_wait_time_in_minutes 5
      end
      
      deployment_ready_option do
        action_on_timeout "CONTINUE_DEPLOYMENT"
      end
      
      green_fleet_provisioning_option do
        action "COPY_AUTO_SCALING_GROUP"
      end
    end
    
    tags do
      Name "CICD-DeploymentGroup-#{namespace}"
      Environment namespace
    end
  end
  
  # Main CI/CD Pipeline
  pipeline = resource :aws_codepipeline, :main do
    name "application-pipeline-#{namespace}"
    role_arn ref(:aws_iam_role, :codepipeline, :arn)
    
    artifact_store do
      location data(:aws_s3_bucket, :artifacts, :bucket)
      type "S3"
      
      encryption_key do
        id data(:aws_kms_key, :cicd_encryption, :arn)
        type "KMS"
      end
    end
    
    # Source stage
    stage do
      name "Source"
      
      action do
        name "Source"
        category "Source"
        owner "AWS"
        provider "CodeCommit"
        version "1"
        
        output_artifacts ["source_output"]
        
        configuration do
          RepositoryName data(:aws_codecommit_repository, :main, :repository_name)
          BranchName namespace == "production" ? "main" : "develop"
          PollForSourceChanges false
        end
      end
    end
    
    # Build stage
    stage do
      name "Build"
      
      # Unit tests
      action do
        name "UnitTests"
        category "Build"
        owner "AWS"
        provider "CodeBuild"
        version "1"
        
        input_artifacts ["source_output"]
        output_artifacts ["test_output"]
        
        configuration do
          ProjectName "unit-tests-#{namespace}"
        end
        
        run_order 1
      end
      
      # Security scan
      action do
        name "SecurityScan"
        category "Build"
        owner "AWS"
        provider "CodeBuild"
        version "1"
        
        input_artifacts ["source_output"]
        output_artifacts ["security_output"]
        
        configuration do
          ProjectName "security-scan-#{namespace}"
        end
        
        run_order 1
      end
      
      # Build application
      action do
        name "BuildApplication"
        category "Build"
        owner "AWS"
        provider "CodeBuild"
        version "1"
        
        input_artifacts ["source_output"]
        output_artifacts ["build_output"]
        
        configuration do
          ProjectName "build-and-package-#{namespace}"
        end
        
        run_order 2
      end
      
      # Build container (if using containers)
      action do
        name "BuildContainer"
        category "Build"
        owner "AWS"
        provider "CodeBuild"
        version "1"
        
        input_artifacts ["source_output"]
        output_artifacts ["container_output"]
        
        configuration do
          ProjectName "container-build-#{namespace}"
        end
        
        run_order 2
      end
    end
    
    # Approval stage for production
    if namespace == "production"
      stage do
        name "ApprovalForProduction"
        
        action do
          name "ManualApproval"
          category "Approval"
          owner "AWS"
          provider "Manual"
          version "1"
          
          configuration do
            CustomData "Please review the build artifacts and approve deployment to production."
            ExternalEntityLink "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/application-pipeline-#{namespace}/view"
          end
        end
      end
    end
    
    # Deploy stage
    stage do
      name "Deploy"
      
      action do
        name "Deploy"
        category "Deploy"
        owner "AWS"
        provider "CodeDeploy"
        version "1"
        
        input_artifacts ["build_output"]
        
        configuration do
          ApplicationName ref(:aws_codedeploy_app, :main, :name)
          DeploymentGroupName ref(:aws_codedeploy_deployment_group, :main, :deployment_group_name)
        end
      end
    end
    
    tags do
      Name "CICD-Pipeline-#{namespace}"
      Purpose "ContinuousDeployment"
      Environment namespace
    end
  end
  
  # CloudWatch Event Rule for automated pipeline triggering
  resource :aws_cloudwatch_event_rule, :pipeline_trigger do
    name "cicd-pipeline-trigger-#{namespace}"
    description "Trigger CI/CD pipeline on CodeCommit push"
    
    event_pattern jsonencode({
      source: ["aws.codecommit"],
      detail_type: ["CodeCommit Repository State Change"],
      resources: [data(:aws_codecommit_repository, :main, :arn)],
      detail: {
        event: ["referenceCreated", "referenceUpdated"],
        referenceType: ["branch"],
        referenceName: [namespace == "production" ? "main" : "develop"]
      }
    })
    
    tags do
      Name "CICD-PipelineTrigger-#{namespace}"
      Purpose "AutomatedTrigger"
    end
  end
  
  # CloudWatch Event Target for pipeline
  resource :aws_cloudwatch_event_target, :pipeline do
    rule ref(:aws_cloudwatch_event_rule, :pipeline_trigger, :name)
    target_id "CodePipelineTarget"
    arn ref(:aws_codepipeline, :main, :arn)
    role_arn ref(:aws_iam_role, :pipeline_trigger, :arn)
  end
  
  # IAM role for pipeline trigger
  resource :aws_iam_role, :pipeline_trigger do
    name_prefix "CICD-PipelineTrigger-"
    assume_role_policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Action: "sts:AssumeRole",
          Effect: "Allow",
          Principal: {
            Service: "events.amazonaws.com"
          }
        }
      ]
    })
    
    tags do
      Name "CICD-PipelineTrigger-Role-#{namespace}"
      Purpose "AutomatedTrigger"
    end
  end
  
  resource :aws_iam_role_policy, :pipeline_trigger do
    name_prefix "CICD-PipelineTrigger-Policy-"
    role ref(:aws_iam_role, :pipeline_trigger, :id)
    
    policy jsonencode({
      Version: "2012-10-17",
      Statement: [
        {
          Effect: "Allow",
          Action: [
            "codepipeline:StartPipelineExecution"
          ],
          Resource: ref(:aws_codepipeline, :main, :arn)
        }
      ]
    })
  end
  
  # Pipeline notifications
  pipeline_notifications = resource :aws_sns_topic, :pipeline_notifications do
    name "cicd-pipeline-notifications-#{namespace}"
    display_name "CI/CD Pipeline Notifications"
    
    tags do
      Name "CICD-Pipeline-Notifications-#{namespace}"
      Purpose "PipelineAlerts"
    end
  end
  
  # CloudWatch alarms for pipeline failures
  resource :aws_cloudwatch_metric_alarm, :pipeline_failures do
    alarm_name "cicd-pipeline-failures-#{namespace}"
    alarm_description "Pipeline execution failures"
    comparison_operator "GreaterThanThreshold"
    evaluation_periods 1
    metric_name "PipelineExecutionFailure"
    namespace "AWS/CodePipeline"
    period 300
    statistic "Sum"
    threshold 0
    treat_missing_data "notBreaching"
    alarm_actions [ref(:aws_sns_topic, :pipeline_notifications, :arn)]
    
    dimensions do
      PipelineName ref(:aws_codepipeline, :main, :name)
    end
    
    tags do
      Name "CICD-PipelineFailures-#{namespace}"
      AlertType "PipelineFailure"
    end
  end
  
  # Outputs
  output :pipeline_name do
    value ref(:aws_codepipeline, :main, :name)
    description "CodePipeline name"
  end
  
  output :pipeline_url do
    value "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/#{ref(:aws_codepipeline, :main, :name)}/view"
    description "CodePipeline console URL"
  end
  
  output :codedeploy_application_name do
    value ref(:aws_codedeploy_app, :main, :name)
    description "CodeDeploy application name"
  end
  
  output :pipeline_notifications_topic_arn do
    value ref(:aws_sns_topic, :pipeline_notifications, :arn)
    description "SNS topic ARN for pipeline notifications"
  end
end

# This CI/CD pipeline infrastructure example demonstrates several key concepts:
#
# 1. **Template Isolation for CI/CD Components**: Three separate templates for:
#    - Source control and artifact management
#    - Build and test infrastructure
#    - Deployment pipeline orchestration
#
# 2. **Comprehensive Build Pipeline**: Multiple CodeBuild projects for different
#    build stages (unit tests, security scans, packaging, container builds).
#
# 3. **Artifact Management**: S3-based artifact storage with lifecycle policies,
#    ECR for container images with automated cleanup.
#
# 4. **Multi-Environment Support**: Environment-aware configurations with
#    different deployment strategies and approval workflows.
#
# 5. **Security Best Practices**: KMS encryption for artifacts, IAM roles with
#    least privilege, security scanning in the pipeline.
#
# 6. **Monitoring and Notifications**: CloudWatch dashboards, alarms for build
#    failures, SNS notifications for pipeline status.
#
# 7. **Automation**: Event-driven pipeline triggering on code commits,
#    automated rollback configurations.
#
# Deployment order:
#   pangea apply examples/cicd-pipeline-infrastructure.rb --template source_and_artifacts
#   pangea apply examples/cicd-pipeline-infrastructure.rb --template build_infrastructure  
#   pangea apply examples/cicd-pipeline-infrastructure.rb --template deployment_pipeline
#
# Environment-specific deployment:
#   pangea apply examples/cicd-pipeline-infrastructure.rb --namespace development
#   pangea apply examples/cicd-pipeline-infrastructure.rb --namespace staging
#   pangea apply examples/cicd-pipeline-infrastructure.rb --namespace production
#
# This example showcases how Pangea's template isolation enables building
# sophisticated CI/CD infrastructure with clear separation of concerns and
# environment-specific customizations.