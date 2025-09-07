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

# Load aws_batch_job_definition resource and terraform-synthesizer for testing
require 'pangea/resources/aws_batch_job_definition/resource'
require 'terraform-synthesizer'

RSpec.describe "aws_batch_job_definition terraform synthesis" do
  let(:synthesizer) { TerraformSynthesizer.new }
  
  # Test ARN values for various resources
  let(:job_role_arn) { "arn:aws:iam::123456789012:role/batch-job-role" }
  let(:execution_role_arn) { "arn:aws:iam::123456789012:role/batch-execution-role" }
  let(:efs_file_system_id) { "fs-12345678" }
  let(:efs_access_point_id) { "fsap-12345678" }
  let(:kms_key_arn) { "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012" }

  # Test basic container job definition synthesis
  it "synthesizes basic container job definition correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:basic_container, {
        job_definition_name: "basic-container-job",
        type: "container",
        container_properties: {
          image: "nginx:latest"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :basic_container)
    
    expect(job_def_config[:job_definition_name]).to eq("basic-container-job")
    expect(job_def_config[:type]).to eq("container")
    
    # Verify container properties structure
    container_props = job_def_config[:container_properties]
    expect(container_props).to be_a(Hash)
    expect(container_props[:image]).to eq("nginx:latest")
  end

  # Test container job with resource allocation
  it "synthesizes container job with resource allocation" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:resource_job, {
        job_definition_name: "resource-optimized-job",
        type: "container",
        container_properties: {
          image: "compute-app:v1",
          vcpus: 4,
          memory: 8192,
          job_role_arn: "arn:aws:iam::123456789012:role/batch-job-role"
        },
        retry_strategy: {
          attempts: 3
        },
        timeout: {
          attempt_duration_seconds: 3600
        }
      })
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :resource_job)
    
    container_props = job_def_config[:container_properties]
    expect(container_props[:vcpus]).to eq(4)
    expect(container_props[:memory]).to eq(8192)
    expect(container_props[:job_role_arn]).to eq("arn:aws:iam::123456789012:role/batch-job-role")
    
    expect(job_def_config[:retry_strategy][:attempts]).to eq(3)
    expect(job_def_config[:timeout][:attempt_duration_seconds]).to eq(3600)
  end

  # Test Fargate container job synthesis
  it "synthesizes Fargate container job with required configuration" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:fargate_job, {
        job_definition_name: "fargate-serverless-job",
        type: "container",
        platform_capabilities: ["FARGATE"],
        container_properties: {
          image: "serverless-app:v1",
          vcpus: 2,
          memory: 4096,
          execution_role_arn: "arn:aws:iam::123456789012:role/batch-execution-role",
          job_role_arn: "arn:aws:iam::123456789012:role/batch-job-role",
          network_configuration: {
            assign_public_ip: "DISABLED"
          },
          fargate_platform_configuration: {
            platform_version: "1.4.0"
          }
        }
      })
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :fargate_job)
    
    expect(job_def_config[:platform_capabilities]).to eq(["FARGATE"])
    
    container_props = job_def_config[:container_properties]
    expect(container_props[:execution_role_arn]).to eq("arn:aws:iam::123456789012:role/batch-execution-role")
    expect(container_props[:network_configuration][:assign_public_ip]).to eq("DISABLED")
    expect(container_props[:fargate_platform_configuration][:platform_version]).to eq("1.4.0")
  end

  # Test GPU container job synthesis
  it "synthesizes GPU container job with resource requirements" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:gpu_job, {
        job_definition_name: "gpu-training-job",
        type: "container",
        platform_capabilities: ["EC2"],
        container_properties: {
          image: "tensorflow:latest-gpu",
          vcpus: 8,
          memory: 32768,
          job_role_arn: "arn:aws:iam::123456789012:role/ml-job-role",
          resource_requirements: [
            {
              type: "GPU",
              value: "2"
            }
          ]
        },
        tags: {
          "Workload" => "ml-training",
          "Hardware" => "gpu"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :gpu_job)
    
    expect(job_def_config[:platform_capabilities]).to eq(["EC2"])
    
    container_props = job_def_config[:container_properties]
    resource_req = container_props[:resource_requirements][0]
    expect(resource_req[:type]).to eq("GPU")
    expect(resource_req[:value]).to eq("2")
    
    expect(job_def_config[:tags]["Workload"]).to eq("ml-training")
    expect(job_def_config[:tags]["Hardware"]).to eq("gpu")
  end

  # Test container job with environment variables
  it "synthesizes container job with environment variables" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:env_job, {
        job_definition_name: "environment-job",
        type: "container",
        container_properties: {
          image: "env-app:v1",
          environment: [
            { name: "NODE_ENV", value: "production" },
            { name: "LOG_LEVEL", value: "info" },
            { name: "BATCH_JOB_ID", value: "${AWS_BATCH_JOB_ID}" },
            { name: "BATCH_JOB_ATTEMPT", value: "${AWS_BATCH_JOB_ATTEMPT}" }
          ]
        }
      })
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :env_job)
    
    container_props = job_def_config[:container_properties]
    expect(container_props[:environment]).to be_an(Array)
    expect(container_props[:environment].size).to eq(4)
    
    env_vars = container_props[:environment]
    expect(env_vars[0][:name]).to eq("NODE_ENV")
    expect(env_vars[0][:value]).to eq("production")
    expect(env_vars[2][:value]).to eq("${AWS_BATCH_JOB_ID}")
  end

  # Test container job with volumes and mount points
  it "synthesizes container job with volumes and mount points" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:volume_job, {
        job_definition_name: "volume-job",
        type: "container",
        container_properties: {
          image: "data-processor:v1",
          volumes: [
            {
              name: "host-data",
              host: {
                source_path: "/opt/data"
              }
            },
            {
              name: "efs-shared",
              efs_volume_configuration: {
                file_system_id: "fs-12345678",
                root_directory: "/shared",
                transit_encryption: "ENABLED",
                authorization_config: {
                  access_point_id: "fsap-12345678",
                  iam: "ENABLED"
                }
              }
            }
          ],
          mount_points: [
            {
              source_volume: "host-data",
              container_path: "/app/data",
              read_only: false
            },
            {
              source_volume: "efs-shared",
              container_path: "/mnt/shared",
              read_only: true
            }
          ]
        }
      })
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :volume_job)
    
    container_props = job_def_config[:container_properties]
    
    # Verify volumes
    volumes = container_props[:volumes]
    expect(volumes.size).to eq(2)
    expect(volumes[0][:name]).to eq("host-data")
    expect(volumes[0][:host][:source_path]).to eq("/opt/data")
    
    efs_volume = volumes[1]
    expect(efs_volume[:name]).to eq("efs-shared")
    expect(efs_volume[:efs_volume_configuration][:file_system_id]).to eq("fs-12345678")
    expect(efs_volume[:efs_volume_configuration][:transit_encryption]).to eq("ENABLED")
    
    # Verify mount points
    mount_points = container_props[:mount_points]
    expect(mount_points.size).to eq(2)
    expect(mount_points[0][:read_only]).to be false
    expect(mount_points[1][:read_only]).to be true
  end

  # Test multinode job synthesis
  it "synthesizes multinode job with multiple node ranges" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:multinode_job, {
        job_definition_name: "mpi-processing-job",
        type: "multinode",
        platform_capabilities: ["EC2"],
        node_properties: {
          main_node: 0,
          num_nodes: 8,
          node_range_properties: [
            {
              target_nodes: "0",
              container: {
                image: "mpi-coordinator:v1",
                vcpus: 4,
                memory: 8192,
                job_role_arn: "arn:aws:iam::123456789012:role/mpi-coordinator-role",
                environment: [
                  { name: "NODE_TYPE", value: "coordinator" },
                  { name: "MPI_RANK", value: "${AWS_BATCH_JOB_NODE_INDEX}" }
                ]
              }
            },
            {
              target_nodes: "1:7",
              container: {
                image: "mpi-worker:v1",
                vcpus: 2,
                memory: 4096,
                job_role_arn: "arn:aws:iam::123456789012:role/mpi-worker-role",
                environment: [
                  { name: "NODE_TYPE", value: "worker" },
                  { name: "MPI_RANK", value: "${AWS_BATCH_JOB_NODE_INDEX}" }
                ]
              }
            }
          ]
        },
        retry_strategy: {
          attempts: 2
        },
        timeout: {
          attempt_duration_seconds: 7200
        }
      })
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :multinode_job)
    
    expect(job_def_config[:type]).to eq("multinode")
    expect(job_def_config[:platform_capabilities]).to eq(["EC2"])
    
    node_props = job_def_config[:node_properties]
    expect(node_props[:main_node]).to eq(0)
    expect(node_props[:num_nodes]).to eq(8)
    
    node_ranges = node_props[:node_range_properties]
    expect(node_ranges.size).to eq(2)
    
    # Coordinator node
    coordinator = node_ranges[0]
    expect(coordinator[:target_nodes]).to eq("0")
    expect(coordinator[:container][:image]).to eq("mpi-coordinator:v1")
    expect(coordinator[:container][:vcpus]).to eq(4)
    
    # Worker nodes
    worker = node_ranges[1]
    expect(worker[:target_nodes]).to eq("1:7")
    expect(worker[:container][:image]).to eq("mpi-worker:v1")
    expect(worker[:container][:vcpus]).to eq(2)
  end

  # Test container job with all optional properties
  it "synthesizes container job with all optional properties" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:comprehensive_job, {
        job_definition_name: "comprehensive-test-job",
        type: "container",
        platform_capabilities: ["EC2"],
        container_properties: {
          image: "comprehensive-app:v1",
          vcpus: 4,
          memory: 8192,
          job_role_arn: "arn:aws:iam::123456789012:role/batch-job-role",
          execution_role_arn: "arn:aws:iam::123456789012:role/batch-execution-role",
          command: ["/bin/bash", "-c", "echo Hello World"],
          user: "1000:1000",
          instance_type: "m5.xlarge",
          privileged: true,
          readonly_root_filesystem: false,
          environment: [
            { name: "ENV", value: "test" }
          ],
          resource_requirements: [
            { type: "GPU", value: "1" }
          ]
        },
        retry_strategy: {
          attempts: 5
        },
        timeout: {
          attempt_duration_seconds: 1800
        },
        propagate_tags: true,
        tags: {
          "Environment" => "test",
          "Team" => "engineering"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :comprehensive_job)
    
    container_props = job_def_config[:container_properties]
    expect(container_props[:command]).to eq(["/bin/bash", "-c", "echo Hello World"])
    expect(container_props[:user]).to eq("1000:1000")
    expect(container_props[:instance_type]).to eq("m5.xlarge")
    expect(container_props[:privileged]).to be true
    expect(container_props[:readonly_root_filesystem]).to be false
    
    expect(job_def_config[:propagate_tags]).to be true
    expect(job_def_config[:tags]["Team"]).to eq("engineering")
  end

  # Test job definition using template methods
  it "synthesizes job definition from simple_container_job template" do
    template_config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.simple_container_job(
      "template-job",
      "nginx:latest",
      {
        vcpus: 2,
        memory: 2048,
        retry_attempts: 3,
        timeout_seconds: 1200,
        tags: { "Source" => "template" }
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:template_job, template_config)
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :template_job)
    
    expect(job_def_config[:job_definition_name]).to eq("template-job")
    expect(job_def_config[:type]).to eq("container")
    
    container_props = job_def_config[:container_properties]
    expect(container_props[:image]).to eq("nginx:latest")
    expect(container_props[:vcpus]).to eq(2)
    expect(container_props[:memory]).to eq(2048)
    
    expect(job_def_config[:retry_strategy][:attempts]).to eq(3)
    expect(job_def_config[:timeout][:attempt_duration_seconds]).to eq(1200)
    expect(job_def_config[:tags]["Source"]).to eq("template")
  end

  # Test job definition using Fargate template
  it "synthesizes job definition from fargate_container_job template" do
    template_config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.fargate_container_job(
      "fargate-template-job",
      "serverless-app:v1",
      {
        vcpus: 1,
        memory: 2048,
        execution_role_arn: execution_role_arn,
        assign_public_ip: "ENABLED",
        platform_version: "1.4.0"
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:fargate_template_job, template_config)
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :fargate_template_job)
    
    expect(job_def_config[:platform_capabilities]).to eq(["FARGATE"])
    
    container_props = job_def_config[:container_properties]
    expect(container_props[:execution_role_arn]).to eq(execution_role_arn)
    expect(container_props[:network_configuration][:assign_public_ip]).to eq("ENABLED")
    expect(container_props[:fargate_platform_configuration][:platform_version]).to eq("1.4.0")
  end

  # Test job definition using GPU template
  it "synthesizes job definition from gpu_container_job template" do
    template_config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.gpu_container_job(
      "gpu-template-job",
      "tensorflow:latest-gpu",
      {
        vcpus: 8,
        memory: 32768,
        gpu_count: 4,
        job_role_arn: job_role_arn
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:gpu_template_job, template_config)
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :gpu_template_job)
    
    expect(job_def_config[:platform_capabilities]).to eq(["EC2"])
    
    container_props = job_def_config[:container_properties]
    expect(container_props[:vcpus]).to eq(8)
    expect(container_props[:memory]).to eq(32768)
    
    resource_req = container_props[:resource_requirements][0]
    expect(resource_req[:type]).to eq("GPU")
    expect(resource_req[:value]).to eq("4")
    
    expect(job_def_config[:tags][:Hardware]).to eq("gpu")
  end

  # Test job definition using multinode template
  it "synthesizes job definition from multinode_job template" do
    template_config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.multinode_job(
      "multinode-template-job",
      "mpi-app:latest",
      6,
      {
        main_node: 0,
        vcpus: 4,
        memory: 8192,
        job_role_arn: job_role_arn
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:multinode_template_job, template_config)
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :multinode_template_job)
    
    expect(job_def_config[:type]).to eq("multinode")
    expect(job_def_config[:platform_capabilities]).to eq(["EC2"])
    
    node_props = job_def_config[:node_properties]
    expect(node_props[:main_node]).to eq(0)
    expect(node_props[:num_nodes]).to eq(6)
    
    node_range = node_props[:node_range_properties][0]
    expect(node_range[:target_nodes]).to eq("0:5")
    expect(node_range[:container][:vcpus]).to eq(4)
    expect(node_range[:container][:memory]).to eq(8192)
    
    expect(job_def_config[:tags][:Type]).to eq("multinode")
  end

  # Test workload-specific template synthesis
  it "synthesizes job definition from data_processing_job template" do
    template_config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.data_processing_job(
      "etl-template-job",
      "etl-processor:v1",
      {
        vcpus: 4,
        memory: 16384,
        retry_attempts: 5,
        timeout_seconds: 14400,
        job_role_arn: job_role_arn
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:etl_template_job, template_config)
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :etl_template_job)
    
    container_props = job_def_config[:container_properties]
    expect(container_props[:vcpus]).to eq(4)
    expect(container_props[:memory]).to eq(16384)
    
    expect(job_def_config[:retry_strategy][:attempts]).to eq(5)
    expect(job_def_config[:timeout][:attempt_duration_seconds]).to eq(14400)
    
    expect(job_def_config[:tags][:Workload]).to eq("data-processing")
    expect(job_def_config[:tags][:Type]).to eq("cpu-intensive")
  end

  # Test ML training job template synthesis
  it "synthesizes job definition from ml_training_job template" do
    template_config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.ml_training_job(
      "training-template-job",
      "pytorch:latest-gpu",
      {
        vcpus: 16,
        memory: 65536,
        gpu_count: 8,
        job_role_arn: job_role_arn
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:training_template_job, template_config)
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :training_template_job)
    
    container_props = job_def_config[:container_properties]
    expect(container_props[:vcpus]).to eq(16)
    expect(container_props[:memory]).to eq(65536)
    
    resource_req = container_props[:resource_requirements][0]
    expect(resource_req[:type]).to eq("GPU")
    expect(resource_req[:value]).to eq("8")
    
    expect(job_def_config[:timeout][:attempt_duration_seconds]).to eq(14400)
    expect(job_def_config[:tags][:Workload]).to eq("ml-training")
    expect(job_def_config[:tags][:Hardware]).to eq("gpu")
  end

  # Test real-time job template synthesis
  it "synthesizes job definition from real_time_job template" do
    template_config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.real_time_job(
      "realtime-template-job",
      "realtime-processor:v1",
      {
        vcpus: 2,
        memory: 4096,
        execution_role_arn: execution_role_arn,
        job_role_arn: job_role_arn,
        assign_public_ip: "DISABLED"
      }
    )
    
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:realtime_template_job, template_config)
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :realtime_template_job)
    
    expect(job_def_config[:platform_capabilities]).to eq(["FARGATE"])
    
    container_props = job_def_config[:container_properties]
    expect(container_props[:execution_role_arn]).to eq(execution_role_arn)
    expect(container_props[:network_configuration][:assign_public_ip]).to eq("DISABLED")
    
    expect(job_def_config[:retry_strategy][:attempts]).to eq(1)
    expect(job_def_config[:timeout][:attempt_duration_seconds]).to eq(300)
    
    expect(job_def_config[:tags][:Workload]).to eq("real-time")
    expect(job_def_config[:tags][:Latency]).to eq("critical")
  end

  # Test multiple job definitions in single synthesis
  it "synthesizes multiple job definitions correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      # Basic container job
      aws_batch_job_definition(:basic_job, {
        job_definition_name: "basic-job",
        type: "container",
        container_properties: {
          image: "basic-app:v1"
        }
      })
      
      # GPU job
      aws_batch_job_definition(:gpu_job, {
        job_definition_name: "gpu-job",
        type: "container",
        platform_capabilities: ["EC2"],
        container_properties: {
          image: "gpu-app:v1",
          resource_requirements: [
            { type: "GPU", value: "1" }
          ]
        }
      })
      
      # Fargate job
      aws_batch_job_definition(:fargate_job, {
        job_definition_name: "fargate-job",
        type: "container",
        platform_capabilities: ["FARGATE"],
        container_properties: {
          image: "fargate-app:v1",
          execution_role_arn: "arn:aws:iam::123456789012:role/execution-role"
        }
      })
    end
    
    json_output = synthesizer.synthesis
    job_definitions = json_output.dig(:resource, :aws_batch_job_definition)
    
    expect(job_definitions.keys).to contain_exactly(:basic_job, :gpu_job, :fargate_job)
    
    # Verify each job definition has correct type and properties
    expect(job_definitions[:basic_job][:type]).to eq("container")
    expect(job_definitions[:gpu_job][:platform_capabilities]).to eq(["EC2"])
    expect(job_definitions[:fargate_job][:platform_capabilities]).to eq(["FARGATE"])
  end

  # Test synthesis with complex nested structure
  it "synthesizes complex nested container properties correctly" do
    synthesizer.instance_eval do
      extend Pangea::Resources::AWS
      
      aws_batch_job_definition(:complex_nested_job, {
        job_definition_name: "complex-nested-job",
        type: "container",
        container_properties: {
          image: "complex-app:v1",
          environment: [
            { name: "VAR1", value: "value1" },
            { name: "VAR2", value: "value2" },
            { name: "VAR3", value: "value3" }
          ],
          volumes: [
            {
              name: "volume1",
              host: { source_path: "/path1" }
            },
            {
              name: "volume2",
              efs_volume_configuration: {
                file_system_id: efs_file_system_id,
                root_directory: "/root",
                transit_encryption: "ENABLED",
                authorization_config: {
                  access_point_id: efs_access_point_id,
                  iam: "ENABLED"
                }
              }
            }
          ],
          mount_points: [
            {
              source_volume: "volume1",
              container_path: "/mnt/volume1",
              read_only: false
            },
            {
              source_volume: "volume2", 
              container_path: "/mnt/volume2",
              read_only: true
            }
          ],
          resource_requirements: [
            { type: "GPU", value: "2" }
          ]
        }
      })
    end
    
    json_output = synthesizer.synthesis
    job_def_config = json_output.dig(:resource, :aws_batch_job_definition, :complex_nested_job)
    
    container_props = job_def_config[:container_properties]
    
    # Verify nested environment variables
    expect(container_props[:environment].size).to eq(3)
    env_vars = container_props[:environment]
    expect(env_vars.map { |v| v[:name] }).to eq(["VAR1", "VAR2", "VAR3"])
    
    # Verify nested volumes
    expect(container_props[:volumes].size).to eq(2)
    volumes = container_props[:volumes]
    expect(volumes[1][:efs_volume_configuration][:authorization_config][:access_point_id]).to eq(efs_access_point_id)
    
    # Verify nested mount points
    expect(container_props[:mount_points].size).to eq(2)
    mount_points = container_props[:mount_points]
    expect(mount_points[0][:read_only]).to be false
    expect(mount_points[1][:read_only]).to be true
    
    # Verify nested resource requirements
    expect(container_props[:resource_requirements][0][:value]).to eq("2")
  end
end