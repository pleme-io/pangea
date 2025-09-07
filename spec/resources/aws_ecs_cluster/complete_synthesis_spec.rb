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


require 'spec_helper'
require 'json'

# Load aws_ecs_cluster resource and terraform-synthesizer for testing
require 'pangea/resources/aws_ecs_cluster/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_ecs_cluster terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }
  let(:custom_provider_arn) { "arn:aws:ecs:us-east-1:123456789012:capacity-provider/custom-provider" }
  let(:service_connect_namespace) { "arn:aws:servicediscovery:us-east-1:123456789012:namespace/ns-12345" }

  # Test basic cluster synthesis
  it "synthesizes basic ECS cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:basic, {
        name: "basic-cluster"
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :basic)
    
    expect(cluster_config[:name]).to eq("basic-cluster")
    expect(cluster_config).not_to have_key(:capacity_providers)
    expect(cluster_config).not_to have_key(:setting)
    expect(cluster_config).not_to have_key(:configuration)
  end

  # Test cluster with FARGATE capacity provider synthesis
  it "synthesizes cluster with FARGATE correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:fargate, {
        name: "fargate-cluster",
        capacity_providers: ["FARGATE"]
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :fargate)
    
    expect(cluster_config[:name]).to eq("fargate-cluster")
    expect(cluster_config[:capacity_providers]).to eq(["FARGATE"])
  end

  # Test cluster with multiple capacity providers synthesis
  it "synthesizes cluster with multiple capacity providers correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:multi_provider, {
        name: "multi-provider-cluster",
        capacity_providers: ["FARGATE", "FARGATE_SPOT", custom_provider_arn]
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :multi_provider)
    
    expect(cluster_config[:name]).to eq("multi-provider-cluster")
    expect(cluster_config[:capacity_providers]).to eq(["FARGATE", "FARGATE_SPOT", custom_provider_arn])
  end

  # Test cluster with Container Insights (shorthand) synthesis
  it "synthesizes cluster with Container Insights shorthand correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:insights, {
        name: "insights-cluster",
        container_insights_enabled: true
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :insights)
    
    expect(cluster_config[:name]).to eq("insights-cluster")
    expect(cluster_config[:setting]).to be_an(Array)
    
    insights_setting = cluster_config[:setting].find { |s| s[:name] == "containerInsights" }
    expect(insights_setting).not_to be_nil
    expect(insights_setting[:value]).to eq("enabled")
  end

  # Test cluster with explicit settings synthesis
  it "synthesizes cluster with explicit settings correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:settings, {
        name: "settings-cluster",
        setting: [
          { name: "containerInsights", value: "disabled" }
        ]
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :settings)
    
    expect(cluster_config[:name]).to eq("settings-cluster")
    expect(cluster_config[:setting]).to eq([
      { name: "containerInsights", value: "disabled" }
    ])
  end

  # Test cluster with execute command configuration synthesis
  it "synthesizes cluster with execute command configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:exec_command, {
        name: "exec-command-cluster",
        configuration: {
          execute_command_configuration: {
            kms_key_id: kms_key_arn,
            logging: "OVERRIDE",
            log_configuration: {
              cloud_watch_encryption_enabled: true,
              cloud_watch_log_group_name: "/ecs/exec",
              s3_bucket_name: "exec-logs",
              s3_bucket_encryption_enabled: true,
              s3_key_prefix: "logs/"
            }
          }
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :exec_command)
    
    expect(cluster_config[:name]).to eq("exec-command-cluster")
    expect(cluster_config[:configuration]).to be_a(Hash)
    
    exec_config = cluster_config[:configuration][:execute_command_configuration]
    expect(exec_config[:kms_key_id]).to eq(kms_key_arn)
    expect(exec_config[:logging]).to eq("OVERRIDE")
    
    log_config = exec_config[:log_configuration]
    expect(log_config[:cloud_watch_encryption_enabled]).to eq(true)
    expect(log_config[:cloud_watch_log_group_name]).to eq("/ecs/exec")
    expect(log_config[:s3_bucket_name]).to eq("exec-logs")
    expect(log_config[:s3_bucket_encryption_enabled]).to eq(true)
    expect(log_config[:s3_key_prefix]).to eq("logs/")
  end

  # Test cluster with Service Connect defaults synthesis
  it "synthesizes cluster with Service Connect defaults correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:service_connect, {
        name: "service-connect-cluster",
        service_connect_defaults: {
          namespace: service_connect_namespace
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :service_connect)
    
    expect(cluster_config[:name]).to eq("service-connect-cluster")
    expect(cluster_config[:service_connect_defaults]).to be_a(Hash)
    expect(cluster_config[:service_connect_defaults][:namespace]).to eq(service_connect_namespace)
  end

  # Test cluster with comprehensive configuration synthesis
  it "synthesizes comprehensive cluster configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:comprehensive, {
        name: "comprehensive-cluster",
        capacity_providers: ["FARGATE", "FARGATE_SPOT"],
        container_insights_enabled: true,
        configuration: {
          execute_command_configuration: {
            kms_key_id: kms_key_arn,
            logging: "OVERRIDE",
            log_configuration: {
              cloud_watch_encryption_enabled: true,
              cloud_watch_log_group_name: "/ecs/comprehensive"
            }
          }
        },
        service_connect_defaults: {
          namespace: service_connect_namespace
        },
        tags: {
          Environment: "production",
          Team: "platform",
          Security: "high"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :comprehensive)
    
    expect(cluster_config[:name]).to eq("comprehensive-cluster")
    expect(cluster_config[:capacity_providers]).to eq(["FARGATE", "FARGATE_SPOT"])
    
    # Verify Container Insights setting was added
    insights_setting = cluster_config[:setting].find { |s| s[:name] == "containerInsights" }
    expect(insights_setting[:value]).to eq("enabled")
    
    # Verify execute command configuration
    exec_config = cluster_config[:configuration][:execute_command_configuration]
    expect(exec_config[:kms_key_id]).to eq(kms_key_arn)
    expect(exec_config[:logging]).to eq("OVERRIDE")
    
    # Verify Service Connect defaults
    expect(cluster_config[:service_connect_defaults][:namespace]).to eq(service_connect_namespace)
    
    # Verify tags
    expect(cluster_config[:tags]).to eq({
      Environment: "production",
      Team: "platform",
      Security: "high"
    })
  end

  # Test development cluster pattern synthesis
  it "synthesizes development cluster pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:development, {
        name: "dev-cluster",
        capacity_providers: ["FARGATE"],
        container_insights_enabled: false,
        tags: {
          Environment: "development",
          Purpose: "testing",
          CostOptimized: "true"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :development)
    
    expect(cluster_config[:name]).to eq("dev-cluster")
    expect(cluster_config[:capacity_providers]).to eq(["FARGATE"])
    
    # Container Insights should be explicitly disabled
    insights_setting = cluster_config[:setting].find { |s| s[:name] == "containerInsights" }
    expect(insights_setting[:value]).to eq("disabled")
    
    expect(cluster_config[:tags][:Environment]).to eq("development")
    expect(cluster_config[:tags][:CostOptimized]).to eq("true")
  end

  # Test production cluster pattern synthesis
  it "synthesizes production cluster pattern correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:production, {
        name: "prod-cluster",
        capacity_providers: ["FARGATE", "FARGATE_SPOT"],
        container_insights_enabled: true,
        configuration: {
          execute_command_configuration: {
            kms_key_id: kms_key_arn,
            logging: "OVERRIDE",
            log_configuration: {
              cloud_watch_encryption_enabled: true,
              cloud_watch_log_group_name: "/ecs/production",
              s3_bucket_name: "prod-exec-logs",
              s3_bucket_encryption_enabled: true
            }
          }
        },
        service_connect_defaults: {
          namespace: service_connect_namespace
        },
        tags: {
          Environment: "production",
          Security: "high",
          Monitoring: "enabled",
          Backup: "required"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :production)
    
    expect(cluster_config[:name]).to eq("prod-cluster")
    expect(cluster_config[:capacity_providers]).to eq(["FARGATE", "FARGATE_SPOT"])
    
    # Container Insights enabled
    insights_setting = cluster_config[:setting].find { |s| s[:name] == "containerInsights" }
    expect(insights_setting[:value]).to eq("enabled")
    
    # Full execute command configuration
    exec_config = cluster_config[:configuration][:execute_command_configuration]
    expect(exec_config[:kms_key_id]).to eq(kms_key_arn)
    expect(exec_config[:log_configuration][:s3_bucket_encryption_enabled]).to eq(true)
    
    # Service Connect enabled
    expect(cluster_config[:service_connect_defaults][:namespace]).to eq(service_connect_namespace)
    
    # Production tags
    expect(cluster_config[:tags][:Security]).to eq("high")
    expect(cluster_config[:tags][:Monitoring]).to eq("enabled")
  end

  # Test microservices platform synthesis
  it "synthesizes microservices platform correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:microservices, {
        name: "microservices-platform",
        capacity_providers: ["FARGATE", "FARGATE_SPOT"],
        container_insights_enabled: true,
        configuration: {
          execute_command_configuration: {
            logging: "OVERRIDE",
            log_configuration: {
              cloud_watch_encryption_enabled: true,
              cloud_watch_log_group_name: "/ecs/microservices"
            }
          }
        },
        service_connect_defaults: {
          namespace: service_connect_namespace
        },
        tags: {
          Environment: "production",
          Architecture: "microservices",
          ServiceMesh: "enabled",
          Platform: "ecs"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :microservices)
    
    expect(cluster_config[:name]).to eq("microservices-platform")
    expect(cluster_config[:capacity_providers]).to eq(["FARGATE", "FARGATE_SPOT"])
    
    # Service Connect is critical for microservices
    expect(cluster_config[:service_connect_defaults][:namespace]).to eq(service_connect_namespace)
    
    # Architecture tags
    expect(cluster_config[:tags][:Architecture]).to eq("microservices")
    expect(cluster_config[:tags][:ServiceMesh]).to eq("enabled")
  end

  # Test hybrid cluster synthesis
  it "synthesizes hybrid cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:hybrid, {
        name: "hybrid-cluster",
        capacity_providers: ["FARGATE", custom_provider_arn],
        container_insights_enabled: true,
        tags: {
          Environment: "production",
          Type: "hybrid",
          CostOptimized: "partial"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :hybrid)
    
    expect(cluster_config[:name]).to eq("hybrid-cluster")
    expect(cluster_config[:capacity_providers]).to eq(["FARGATE", custom_provider_arn])
    expect(cluster_config[:tags][:Type]).to eq("hybrid")
  end

  # Test security-focused cluster synthesis
  it "synthesizes security-focused cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:secure, {
        name: "secure-cluster",
        capacity_providers: ["FARGATE"], # No Spot for security
        container_insights_enabled: true,
        configuration: {
          execute_command_configuration: {
            kms_key_id: kms_key_arn,
            logging: "OVERRIDE",
            log_configuration: {
              cloud_watch_encryption_enabled: true,
              cloud_watch_log_group_name: "/ecs/secure",
              s3_bucket_name: "secure-exec-logs",
              s3_bucket_encryption_enabled: true,
              s3_key_prefix: "secure-logs/"
            }
          }
        },
        tags: {
          Environment: "production",
          Security: "high",
          Compliance: "required",
          Encryption: "enabled"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :secure)
    
    expect(cluster_config[:name]).to eq("secure-cluster")
    expect(cluster_config[:capacity_providers]).to eq(["FARGATE"]) # No Spot
    
    # Full encryption configuration
    exec_config = cluster_config[:configuration][:execute_command_configuration]
    expect(exec_config[:kms_key_id]).to eq(kms_key_arn)
    expect(exec_config[:log_configuration][:cloud_watch_encryption_enabled]).to eq(true)
    expect(exec_config[:log_configuration][:s3_bucket_encryption_enabled]).to eq(true)
    
    # Security tags
    expect(cluster_config[:tags][:Security]).to eq("high")
    expect(cluster_config[:tags][:Compliance]).to eq("required")
    expect(cluster_config[:tags][:Encryption]).to eq("enabled")
  end

  # Test cost-optimized cluster synthesis
  it "synthesizes cost-optimized cluster correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:cost_optimized, {
        name: "cost-optimized-cluster",
        capacity_providers: ["FARGATE_SPOT"],
        container_insights_enabled: false,
        tags: {
          Environment: "development",
          CostOptimized: "true",
          Purpose: "testing"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :cost_optimized)
    
    expect(cluster_config[:name]).to eq("cost-optimized-cluster")
    expect(cluster_config[:capacity_providers]).to eq(["FARGATE_SPOT"])
    
    # Container Insights disabled for cost savings
    insights_setting = cluster_config[:setting].find { |s| s[:name] == "containerInsights" }
    expect(insights_setting[:value]).to eq("disabled")
    
    expect(cluster_config[:tags][:CostOptimized]).to eq("true")
  end

  # Test cluster with different logging configurations
  it "synthesizes cluster with DEFAULT logging correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:default_logging, {
        name: "default-logging-cluster",
        configuration: {
          execute_command_configuration: {
            logging: "DEFAULT"
          }
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :default_logging)
    
    exec_config = cluster_config[:configuration][:execute_command_configuration]
    expect(exec_config[:logging]).to eq("DEFAULT")
    expect(exec_config).not_to have_key(:log_configuration)
  end

  # Test cluster with NONE logging
  it "synthesizes cluster with NONE logging correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:none_logging, {
        name: "none-logging-cluster",
        configuration: {
          execute_command_configuration: {
            logging: "NONE"
          }
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :none_logging)
    
    exec_config = cluster_config[:configuration][:execute_command_configuration]
    expect(exec_config[:logging]).to eq("NONE")
    expect(exec_config).not_to have_key(:log_configuration)
  end

  # Test cluster with only CloudWatch logging
  it "synthesizes cluster with CloudWatch-only logging correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:cloudwatch_logging, {
        name: "cloudwatch-logging-cluster",
        configuration: {
          execute_command_configuration: {
            logging: "OVERRIDE",
            log_configuration: {
              cloud_watch_encryption_enabled: false,
              cloud_watch_log_group_name: "/ecs/cloudwatch-only"
            }
          }
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :cloudwatch_logging)
    
    exec_config = cluster_config[:configuration][:execute_command_configuration]
    log_config = exec_config[:log_configuration]
    
    expect(log_config[:cloud_watch_encryption_enabled]).to eq(false)
    expect(log_config[:cloud_watch_log_group_name]).to eq("/ecs/cloudwatch-only")
    expect(log_config).not_to have_key(:s3_bucket_name)
  end

  # Test cluster with only S3 logging
  it "synthesizes cluster with S3-only logging correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:s3_logging, {
        name: "s3-logging-cluster",
        configuration: {
          execute_command_configuration: {
            logging: "OVERRIDE",
            log_configuration: {
              s3_bucket_name: "ecs-exec-logs",
              s3_bucket_encryption_enabled: true,
              s3_key_prefix: "exec-logs/"
            }
          }
        }
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :s3_logging)
    
    exec_config = cluster_config[:configuration][:execute_command_configuration]
    log_config = exec_config[:log_configuration]
    
    expect(log_config[:s3_bucket_name]).to eq("ecs-exec-logs")
    expect(log_config[:s3_bucket_encryption_enabled]).to eq(true)
    expect(log_config[:s3_key_prefix]).to eq("exec-logs/")
    expect(log_config).not_to have_key(:cloud_watch_log_group_name)
  end

  # Test cluster with minimal configuration
  it "synthesizes minimal cluster configuration correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_ecs_cluster(:minimal, {
        name: "minimal-cluster"
      })
    end
    
    json_output = synthesizer.synthesis
    cluster_config = json_output.dig(:resource, :aws_ecs_cluster, :minimal)
    
    expect(cluster_config[:name]).to eq("minimal-cluster")
    
    # Optional fields should not be present when not specified
    expect(cluster_config).not_to have_key(:capacity_providers)
    expect(cluster_config).not_to have_key(:setting)
    expect(cluster_config).not_to have_key(:configuration)
    expect(cluster_config).not_to have_key(:service_connect_defaults)
    expect(cluster_config).not_to have_key(:tags)
  end
end