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

# Load aws_batch_job_definition resource and types for testing
require 'pangea/resources/aws_batch_job_definition/resource'
require 'pangea/resources/aws_batch_job_definition/types'

RSpec.describe "aws_batch_job_definition resource function" do
  # Create a test class that includes the AWS module and mocks terraform-synthesizer
  let(:test_class) do
    Class.new do
      include Pangea::Resources::AWS
      
      # Mock the terraform-synthesizer resource method
      def resource(type, name)
        @resources ||= {}
        resource_data = { type: type, name: name, attributes: {} }
        
        yield if block_given?
        
        @resources["#{type}.#{name}"] = resource_data
        resource_data
      end
      
      # Method missing to capture terraform attributes
      def method_missing(method_name, *args, &block)
        # Don't capture certain methods that might interfere
        return super if [:expect, :be_a, :eq].include?(method_name)
        # For terraform-synthesizer attribute calls, just return the value
        args.first if args.any?
      end
      
      def respond_to_missing?(method_name, include_private = false)
        true
      end
    end
  end
  
  let(:test_instance) { test_class.new }
  
  # Test ARN values for various resources
  let(:job_role_arn) { "arn:aws:iam::123456789012:role/batch-job-role" }
  let(:execution_role_arn) { "arn:aws:iam::123456789012:role/batch-execution-role" }
  let(:efs_file_system_id) { "fs-12345678" }
  let(:efs_access_point_id) { "fsap-12345678" }

  describe "BatchJobDefinitionAttributes validation" do
    it "accepts basic container job configuration" do
      job_def = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "basic-job",
        type: "container",
        container_properties: {
          image: "nginx:latest"
        }
      })
      
      expect(job_def.job_definition_name).to eq("basic-job")
      expect(job_def.type).to eq("container")
      expect(job_def.is_container_job?).to be true
      expect(job_def.is_multinode_job?).to be false
      expect(job_def.supports_ec2?).to be true
      expect(job_def.supports_fargate?).to be false
    end
    
    it "accepts container job with resource allocation" do
      job_def = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "resource-job",
        type: "container",
        container_properties: {
          image: "myapp:v1",
          vcpus: 4,
          memory: 8192
        }
      })
      
      expect(job_def.estimated_vcpus).to eq(4)
      expect(job_def.estimated_memory_mb).to eq(8192)
    end
    
    it "accepts container job with environment variables" do
      job_def = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "env-job",
        type: "container",
        container_properties: {
          image: "myapp:v1",
          environment: [
            { name: "NODE_ENV", value: "production" },
            { name: "LOG_LEVEL", value: "info" },
            { name: "BATCH_JOB_ID", value: "${AWS_BATCH_JOB_ID}" }
          ]
        }
      })
      
      env_vars = job_def.container_properties[:environment]
      expect(env_vars.size).to eq(3)
      expect(env_vars[0][:name]).to eq("NODE_ENV")
      expect(env_vars[0][:value]).to eq("production")
      expect(env_vars[2][:value]).to eq("${AWS_BATCH_JOB_ID}")
    end
    
    it "accepts container job with volumes and mount points" do
      job_def = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "volume-job",
        type: "container",
        container_properties: {
          image: "myapp:v1",
          volumes: [
            {
              name: "data-volume",
              host: { source_path: "/opt/data" }
            },
            {
              name: "efs-volume",
              efs_volume_configuration: {
                file_system_id: efs_file_system_id,
                root_directory: "/mnt/efs",
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
              source_volume: "data-volume",
              container_path: "/app/data",
              read_only: false
            },
            {
              source_volume: "efs-volume",
              container_path: "/mnt/shared",
              read_only: true
            }
          ]
        }
      })
      
      volumes = job_def.container_properties[:volumes]
      mount_points = job_def.container_properties[:mount_points]
      
      expect(volumes.size).to eq(2)
      expect(volumes[0][:name]).to eq("data-volume")
      expect(volumes[1][:efs_volume_configuration][:file_system_id]).to eq(efs_file_system_id)
      
      expect(mount_points.size).to eq(2)
      expect(mount_points[0][:read_only]).to be false
      expect(mount_points[1][:read_only]).to be true
    end
    
    it "accepts container job with GPU resource requirements" do
      job_def = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "gpu-job",
        type: "container",
        platform_capabilities: ["EC2"],
        container_properties: {
          image: "tensorflow:latest-gpu",
          vcpus: 8,
          memory: 16384,
          resource_requirements: [
            { type: "GPU", value: "2" }
          ]
        }
      })
      
      gpu_req = job_def.container_properties[:resource_requirements][0]
      expect(gpu_req[:type]).to eq("GPU")
      expect(gpu_req[:value]).to eq("2")
      expect(job_def.supports_ec2?).to be true
    end
    
    it "accepts Fargate container job with network configuration" do
      job_def = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "fargate-job",
        type: "container",
        platform_capabilities: ["FARGATE"],
        container_properties: {
          image: "myapp:v1",
          vcpus: 2,
          memory: 4096,
          execution_role_arn: execution_role_arn,
          network_configuration: {
            assign_public_ip: "DISABLED"
          },
          fargate_platform_configuration: {
            platform_version: "1.4.0"
          }
        }
      })
      
      expect(job_def.supports_fargate?).to be true
      expect(job_def.supports_ec2?).to be false
      network_config = job_def.container_properties[:network_configuration]
      expect(network_config[:assign_public_ip]).to eq("DISABLED")
    end
    
    it "accepts multinode job configuration" do
      job_def = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "multinode-job",
        type: "multinode",
        platform_capabilities: ["EC2"],
        node_properties: {
          main_node: 0,
          num_nodes: 4,
          node_range_properties: [
            {
              target_nodes: "0:3",
              container: {
                image: "mpi-app:latest",
                vcpus: 4,
                memory: 8192,
                environment: [
                  { name: "MPI_RANK", value: "${AWS_BATCH_JOB_NODE_INDEX}" }
                ]
              }
            }
          ]
        }
      })
      
      expect(job_def.is_multinode_job?).to be true
      expect(job_def.is_container_job?).to be false
      
      node_props = job_def.node_properties
      expect(node_props[:main_node]).to eq(0)
      expect(node_props[:num_nodes]).to eq(4)
      expect(node_props[:node_range_properties][0][:target_nodes]).to eq("0:3")
    end
    
    it "accepts job with retry strategy" do
      job_def = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "retry-job",
        type: "container",
        container_properties: {
          image: "myapp:v1"
        },
        retry_strategy: {
          attempts: 3
        }
      })
      
      expect(job_def.has_retry_strategy?).to be true
      expect(job_def.retry_strategy[:attempts]).to eq(3)
    end
    
    it "accepts job with timeout configuration" do
      job_def = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "timeout-job",
        type: "container",
        container_properties: {
          image: "myapp:v1"
        },
        timeout: {
          attempt_duration_seconds: 3600
        }
      })
      
      expect(job_def.has_timeout?).to be true
      expect(job_def.timeout[:attempt_duration_seconds]).to eq(3600)
    end
    
    it "accepts job with tags and propagate tags" do
      job_def = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "tagged-job",
        type: "container",
        container_properties: {
          image: "myapp:v1"
        },
        propagate_tags: true,
        tags: {
          "Environment" => "production",
          "Team" => "data-science",
          "Project" => "ml-training"
        }
      })
      
      expect(job_def.propagate_tags).to be true
      expect(job_def.tags["Environment"]).to eq("production")
      expect(job_def.tags["Team"]).to eq("data-science")
    end
  end

  describe "job definition name validation" do
    it "accepts valid job definition names" do
      valid_names = [
        "basic-job",
        "my_job_123",
        "JobDefinition",
        "a",
        "a" * 128  # Exactly 128 characters
      ]
      
      valid_names.each do |name|
        expect {
          Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
            job_definition_name: name,
            type: "container",
            container_properties: { image: "test:latest" }
          })
        }.not_to raise_error, "Failed for name: #{name}"
      end
    end
    
    it "rejects invalid job definition names" do
      invalid_names = [
        "",                    # Empty string
        "a" * 129,            # Too long (129 characters)
        "invalid@name",       # Invalid character @
        "invalid.name",       # Invalid character .
        "invalid name",       # Space not allowed
        "invalid/name",       # Invalid character /
        "invalid#name"        # Invalid character #
      ]
      
      invalid_names.each do |name|
        expect {
          Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
            job_definition_name: name,
            type: "container",
            container_properties: { image: "test:latest" }
          })
        }.to raise_error(Dry::Struct::Error), "Should have failed for name: #{name}"
      end
    end
  end

  describe "job type validation" do
    it "accepts valid job types" do
      ["container", "multinode"].each do |type|
        expect {
          Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
            job_definition_name: "test-job",
            type: type,
            container_properties: { image: "test:latest" }
          })
        }.not_to raise_error, "Failed for type: #{type}"
      end
    end
    
    it "rejects invalid job types" do
      ["invalid", "Container", "CONTAINER", "multi-node", ""].each do |type|
        expect {
          Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
            job_definition_name: "test-job",
            type: type,
            container_properties: { image: "test:latest" }
          })
        }.to raise_error(Dry::Struct::Error), "Should have failed for type: #{type}"
      end
    end
  end

  describe "container properties validation" do
    it "requires image field for container properties" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            vcpus: 2,
            memory: 2048
          }
        })
      }.to raise_error(Dry::Struct::Error, /must include a non-empty 'image' field/)
    end
    
    it "rejects empty image field" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: ""
          }
        })
      }.to raise_error(Dry::Struct::Error, /must include a non-empty 'image' field/)
    end
    
    it "validates vCPUs must be positive integer" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            vcpus: 0
          }
        })
      }.to raise_error(Dry::Struct::Error, /vCPUs must be a positive integer/)
      
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            vcpus: -1
          }
        })
      }.to raise_error(Dry::Struct::Error, /vCPUs must be a positive integer/)
    end
    
    it "validates memory must be positive integer" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            memory: 0
          }
        })
      }.to raise_error(Dry::Struct::Error, /Memory must be a positive integer/)
      
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            memory: -512
          }
        })
      }.to raise_error(Dry::Struct::Error, /Memory must be a positive integer/)
    end
    
    it "validates IAM role ARN format" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            job_role_arn: "invalid-arn"
          }
        })
      }.to raise_error(Dry::Struct::Error, /Job role ARN must be a valid IAM role ARN/)
      
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            execution_role_arn: "not-an-arn"
          }
        })
      }.to raise_error(Dry::Struct::Error, /Execution role ARN must be a valid IAM role ARN/)
    end
  end

  describe "environment variables validation" do
    it "validates environment variables structure" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            environment: "not-an-array"
          }
        })
      }.to raise_error(Dry::Struct::Error, /Environment variables must be an array/)
    end
    
    it "validates environment variable fields" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            environment: [
              { name: "VAR1" }  # Missing value
            ]
          }
        })
      }.to raise_error(Dry::Struct::Error, /must have 'name' and 'value' fields/)
      
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            environment: [
              { value: "value1" }  # Missing name
            ]
          }
        })
      }.to raise_error(Dry::Struct::Error, /must have 'name' and 'value' fields/)
    end
  end

  describe "mount points validation" do
    it "validates mount points structure" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            mount_points: "not-an-array"
          }
        })
      }.to raise_error(Dry::Struct::Error, /Mount points must be an array/)
    end
    
    it "validates mount point required fields" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            mount_points: [
              { container_path: "/app/data" }  # Missing source_volume
            ]
          }
        })
      }.to raise_error(Dry::Struct::Error, /must include non-empty 'source_volume'/)
      
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            mount_points: [
              { source_volume: "data-vol" }  # Missing container_path
            ]
          }
        })
      }.to raise_error(Dry::Struct::Error, /must include non-empty 'container_path'/)
    end
  end

  describe "volumes validation" do
    it "validates volumes structure" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            volumes: "not-an-array"
          }
        })
      }.to raise_error(Dry::Struct::Error, /Volumes must be an array/)
    end
    
    it "validates volume name field" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: {
            image: "test:latest",
            volumes: [
              { host: { source_path: "/data" } }  # Missing name
            ]
          }
        })
      }.to raise_error(Dry::Struct::Error, /must have a 'name' field/)
    end
  end

  describe "multinode properties validation" do
    it "validates main_node field" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "multinode",
          node_properties: {
            # Missing main_node
            num_nodes: 4,
            node_range_properties: []
          }
        })
      }.to raise_error(Dry::Struct::Error, /must include a non-negative main_node index/)
      
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "multinode",
          node_properties: {
            main_node: -1,  # Negative value
            num_nodes: 4,
            node_range_properties: []
          }
        })
      }.to raise_error(Dry::Struct::Error, /must include a non-negative main_node index/)
    end
    
    it "validates num_nodes field" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "multinode",
          node_properties: {
            main_node: 0,
            num_nodes: 0,  # Must be positive
            node_range_properties: []
          }
        })
      }.to raise_error(Dry::Struct::Error, /must include a positive num_nodes value/)
    end
    
    it "validates node_range_properties field" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "multinode",
          node_properties: {
            main_node: 0,
            num_nodes: 4
            # Missing node_range_properties
          }
        })
      }.to raise_error(Dry::Struct::Error, /must include node_range_properties array/)
      
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "multinode",
          node_properties: {
            main_node: 0,
            num_nodes: 4,
            node_range_properties: [
              {
                # Missing target_nodes
                container: { image: "test:latest" }
              }
            ]
          }
        })
      }.to raise_error(Dry::Struct::Error, /must include target_nodes string/)
    end
  end

  describe "retry strategy validation" do
    it "validates retry strategy structure" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: { image: "test:latest" },
          retry_strategy: "not-a-hash"
        })
      }.to raise_error(Dry::Struct::Error, /Retry strategy must be a hash/)
    end
    
    it "validates retry attempts range" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: { image: "test:latest" },
          retry_strategy: { attempts: 0 }
        })
      }.to raise_error(Dry::Struct::Error, /Retry attempts must be between 1 and 10/)
      
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: { image: "test:latest" },
          retry_strategy: { attempts: 11 }
        })
      }.to raise_error(Dry::Struct::Error, /Retry attempts must be between 1 and 10/)
    end
  end

  describe "timeout validation" do
    it "validates timeout structure" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: { image: "test:latest" },
          timeout: "not-a-hash"
        })
      }.to raise_error(Dry::Struct::Error, /Timeout must be a hash/)
    end
    
    it "validates timeout duration minimum" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: { image: "test:latest" },
          timeout: { attempt_duration_seconds: 59 }
        })
      }.to raise_error(Dry::Struct::Error, /Timeout duration must be at least 60 seconds/)
    end
  end

  describe "platform capabilities validation" do
    it "validates platform capabilities structure" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: { image: "test:latest" },
          platform_capabilities: "not-an-array"
        })
      }.to raise_error(Dry::Struct::Error, /Platform capabilities must be an array/)
    end
    
    it "validates valid platform capabilities" do
      expect {
        Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
          job_definition_name: "test-job",
          type: "container",
          container_properties: { image: "test:latest" },
          platform_capabilities: ["INVALID"]
        })
      }.to raise_error(Dry::Struct::Error, /Invalid platform capability 'INVALID'/)
    end
    
    it "accepts valid platform capabilities" do
      ["EC2", "FARGATE"].each do |capability|
        expect {
          Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
            job_definition_name: "test-job",
            type: "container",
            container_properties: { image: "test:latest" },
            platform_capabilities: [capability]
          })
        }.not_to raise_error
      end
    end
  end

  describe "template system" do
    describe "simple_container_job template" do
      it "creates basic container job configuration" do
        config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.simple_container_job(
          "simple-job",
          "nginx:latest"
        )
        
        expect(config[:job_definition_name]).to eq("simple-job")
        expect(config[:type]).to eq("container")
        expect(config[:container_properties][:image]).to eq("nginx:latest")
        expect(config[:container_properties][:vcpus]).to eq(1)
        expect(config[:container_properties][:memory]).to eq(512)
      end
      
      it "accepts custom options" do
        config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.simple_container_job(
          "custom-job",
          "myapp:v1",
          {
            vcpus: 4,
            memory: 8192,
            job_role_arn: job_role_arn,
            retry_attempts: 3,
            timeout_seconds: 1800,
            tags: { "Team" => "backend" }
          }
        )
        
        expect(config[:container_properties][:vcpus]).to eq(4)
        expect(config[:container_properties][:memory]).to eq(8192)
        expect(config[:container_properties][:job_role_arn]).to eq(job_role_arn)
        expect(config[:retry_strategy][:attempts]).to eq(3)
        expect(config[:timeout][:attempt_duration_seconds]).to eq(1800)
        expect(config[:tags]["Team"]).to eq("backend")
      end
    end
    
    describe "fargate_container_job template" do
      it "creates Fargate-optimized container job" do
        config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.fargate_container_job(
          "fargate-job",
          "myapp:v1",
          {
            execution_role_arn: execution_role_arn,
            assign_public_ip: "ENABLED"
          }
        )
        
        expect(config[:platform_capabilities]).to eq(["FARGATE"])
        expect(config[:container_properties][:execution_role_arn]).to eq(execution_role_arn)
        expect(config[:container_properties][:network_configuration][:assign_public_ip]).to eq("ENABLED")
        expect(config[:container_properties][:fargate_platform_configuration][:platform_version]).to eq("LATEST")
      end
    end
    
    describe "gpu_container_job template" do
      it "creates GPU-enabled container job" do
        config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.gpu_container_job(
          "gpu-job",
          "tensorflow:latest-gpu",
          {
            gpu_count: 2,
            vcpus: 8,
            memory: 16384
          }
        )
        
        expect(config[:platform_capabilities]).to eq(["EC2"])
        expect(config[:container_properties][:vcpus]).to eq(8)
        expect(config[:container_properties][:memory]).to eq(16384)
        expect(config[:container_properties][:resource_requirements][0][:type]).to eq("GPU")
        expect(config[:container_properties][:resource_requirements][0][:value]).to eq("2")
        expect(config[:tags][:Hardware]).to eq("gpu")
      end
    end
    
    describe "multinode_job template" do
      it "creates multinode job configuration" do
        config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.multinode_job(
          "mpi-job",
          "mpi-app:latest",
          4,
          {
            vcpus: 4,
            memory: 8192,
            job_role_arn: job_role_arn
          }
        )
        
        expect(config[:type]).to eq("multinode")
        expect(config[:platform_capabilities]).to eq(["EC2"])
        expect(config[:node_properties][:main_node]).to eq(0)
        expect(config[:node_properties][:num_nodes]).to eq(4)
        expect(config[:node_properties][:node_range_properties][0][:target_nodes]).to eq("0:3")
        expect(config[:tags][:Type]).to eq("multinode")
      end
    end
    
    describe "workload-specific templates" do
      it "creates data processing job" do
        config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.data_processing_job(
          "etl-job",
          "etl-processor:v1",
          {
            vcpus: 4,
            memory: 8192,
            retry_attempts: 5
          }
        )
        
        expect(config[:container_properties][:vcpus]).to eq(4)
        expect(config[:container_properties][:memory]).to eq(8192)
        expect(config[:retry_strategy][:attempts]).to eq(5)
        expect(config[:timeout][:attempt_duration_seconds]).to eq(3600)
        expect(config[:tags][:Workload]).to eq("data-processing")
        expect(config[:tags][:Type]).to eq("cpu-intensive")
      end
      
      it "creates ML training job" do
        config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.ml_training_job(
          "training-job",
          "pytorch:latest-gpu",
          {
            gpu_count: 4,
            vcpus: 16,
            memory: 65536
          }
        )
        
        expect(config[:container_properties][:vcpus]).to eq(16)
        expect(config[:container_properties][:memory]).to eq(65536)
        expect(config[:container_properties][:resource_requirements][0][:value]).to eq("4")
        expect(config[:timeout][:attempt_duration_seconds]).to eq(14400)
        expect(config[:tags][:Workload]).to eq("ml-training")
        expect(config[:tags][:Hardware]).to eq("gpu")
      end
      
      it "creates batch processing job" do
        config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.batch_processing_job(
          "batch-job",
          "batch-processor:v1",
          {
            retry_attempts: 10,
            timeout_seconds: 10800
          }
        )
        
        expect(config[:retry_strategy][:attempts]).to eq(10)
        expect(config[:timeout][:attempt_duration_seconds]).to eq(10800)
        expect(config[:platform_capabilities]).to eq(["EC2"])
        expect(config[:tags][:Workload]).to eq("batch-processing")
        expect(config[:tags][:Priority]).to eq("background")
      end
      
      it "creates real-time job" do
        config = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.real_time_job(
          "realtime-job",
          "realtime-processor:v1",
          {
            execution_role_arn: execution_role_arn,
            vcpus: 4,
            memory: 4096
          }
        )
        
        expect(config[:platform_capabilities]).to eq(["FARGATE"])
        expect(config[:container_properties][:execution_role_arn]).to eq(execution_role_arn)
        expect(config[:retry_strategy][:attempts]).to eq(1)
        expect(config[:timeout][:attempt_duration_seconds]).to eq(300)
        expect(config[:tags][:Workload]).to eq("real-time")
        expect(config[:tags][:Latency]).to eq("critical")
      end
    end
  end

  describe "helper methods" do
    describe "standard_environment_variables" do
      it "creates standard environment variables" do
        env_vars = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.standard_environment_variables({
          region: "us-west-2",
          custom_vars: [
            { name: "CUSTOM_VAR", value: "custom_value" }
          ]
        })
        
        expect(env_vars.size).to eq(4)
        expect(env_vars[0][:name]).to eq("AWS_DEFAULT_REGION")
        expect(env_vars[0][:value]).to eq("us-west-2")
        expect(env_vars[1][:value]).to eq("${AWS_BATCH_JOB_ID}")
        expect(env_vars[3][:name]).to eq("CUSTOM_VAR")
      end
    end
    
    describe "common_resource_requirements" do
      it "creates GPU resource requirements" do
        requirements = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.common_resource_requirements(2)
        
        expect(requirements.size).to eq(1)
        expect(requirements[0][:type]).to eq("GPU")
        expect(requirements[0][:value]).to eq("2")
      end
      
      it "returns empty array without GPU" do
        requirements = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.common_resource_requirements
        
        expect(requirements).to eq([])
      end
    end
    
    describe "volume helpers" do
      it "creates EFS volume configuration" do
        volume = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.efs_volume(
          "efs-data",
          efs_file_system_id,
          {
            root_directory: "/data",
            transit_encryption: "DISABLED",
            authorization_config: {
              access_point_id: efs_access_point_id,
              iam: "ENABLED"
            }
          }
        )
        
        expect(volume[:name]).to eq("efs-data")
        expect(volume[:efs_volume_configuration][:file_system_id]).to eq(efs_file_system_id)
        expect(volume[:efs_volume_configuration][:root_directory]).to eq("/data")
        expect(volume[:efs_volume_configuration][:transit_encryption]).to eq("DISABLED")
        expect(volume[:efs_volume_configuration][:authorization_config][:access_point_id]).to eq(efs_access_point_id)
      end
      
      it "creates host volume configuration" do
        volume = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.host_volume(
          "host-data",
          "/opt/data"
        )
        
        expect(volume[:name]).to eq("host-data")
        expect(volume[:host][:source_path]).to eq("/opt/data")
      end
      
      it "creates standard mount point" do
        mount_point = Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.standard_mount_point(
          "data-vol",
          "/app/data",
          true
        )
        
        expect(mount_point[:source_volume]).to eq("data-vol")
        expect(mount_point[:container_path]).to eq("/app/data")
        expect(mount_point[:read_only]).to be true
      end
    end
  end

  describe "computed properties" do
    let(:container_job) do
      Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "test-job",
        type: "container",
        platform_capabilities: ["EC2", "FARGATE"],
        container_properties: {
          image: "test:latest",
          vcpus: 4,
          memory: 8192
        },
        retry_strategy: { attempts: 3 },
        timeout: { attempt_duration_seconds: 1800 }
      })
    end
    
    let(:multinode_job) do
      Pangea::Resources::AWS::Types::BatchJobDefinitionAttributes.new({
        job_definition_name: "mpi-job",
        type: "multinode",
        platform_capabilities: ["EC2"],
        node_properties: {
          main_node: 0,
          num_nodes: 4,
          node_range_properties: [
            {
              target_nodes: "0:3",
              container: { image: "mpi:latest" }
            }
          ]
        }
      })
    end
    
    it "correctly identifies job types" do
      expect(container_job.is_container_job?).to be true
      expect(container_job.is_multinode_job?).to be false
      
      expect(multinode_job.is_container_job?).to be false
      expect(multinode_job.is_multinode_job?).to be true
    end
    
    it "correctly identifies platform support" do
      expect(container_job.supports_ec2?).to be true
      expect(container_job.supports_fargate?).to be true
      
      expect(multinode_job.supports_ec2?).to be true
      expect(multinode_job.supports_fargate?).to be false
    end
    
    it "correctly identifies retry and timeout configuration" do
      expect(container_job.has_retry_strategy?).to be true
      expect(container_job.has_timeout?).to be true
      
      expect(multinode_job.has_retry_strategy?).to be false
      expect(multinode_job.has_timeout?).to be false
    end
    
    it "correctly estimates resource requirements" do
      expect(container_job.estimated_vcpus).to eq(4)
      expect(container_job.estimated_memory_mb).to eq(8192)
      
      expect(multinode_job.estimated_vcpus).to be_nil
      expect(multinode_job.estimated_memory_mb).to be_nil
    end
  end

  describe "resource function integration" do
    it "returns ResourceReference" do
      ref = test_instance.aws_batch_job_definition(:test_job, {
        job_definition_name: "test-job",
        type: "container",
        container_properties: {
          image: "nginx:latest"
        }
      })
      
      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.name).to eq(:test_job)
      expect(ref.resource_type).to eq(:aws_batch_job_definition)
    end
    
    it "handles complex job definition with all properties" do
      expect {
        test_instance.aws_batch_job_definition(:complex_job, {
          job_definition_name: "complex-job",
          type: "container",
          platform_capabilities: ["FARGATE"],
          container_properties: {
            image: "myapp:v1",
            vcpus: 2,
            memory: 4096,
            execution_role_arn: execution_role_arn,
            job_role_arn: job_role_arn,
            environment: [
              { name: "ENV", value: "production" }
            ],
            network_configuration: {
              assign_public_ip: "DISABLED"
            },
            fargate_platform_configuration: {
              platform_version: "1.4.0"
            }
          },
          retry_strategy: { attempts: 2 },
          timeout: { attempt_duration_seconds: 600 },
          propagate_tags: true,
          tags: {
            "Environment" => "production",
            "Service" => "batch-processing"
          }
        })
      }.not_to raise_error
    end
    
    it "handles multinode job with multiple node ranges" do
      expect {
        test_instance.aws_batch_job_definition(:multinode_job, {
          job_definition_name: "multinode-processing",
          type: "multinode",
          platform_capabilities: ["EC2"],
          node_properties: {
            main_node: 0,
            num_nodes: 8,
            node_range_properties: [
              {
                target_nodes: "0",
                container: {
                  image: "coordinator:latest",
                  vcpus: 4,
                  memory: 8192,
                  job_role_arn: job_role_arn,
                  environment: [
                    { name: "NODE_TYPE", value: "coordinator" }
                  ]
                }
              },
              {
                target_nodes: "1:7",
                container: {
                  image: "worker:latest",
                  vcpus: 2,
                  memory: 4096,
                  job_role_arn: job_role_arn,
                  environment: [
                    { name: "NODE_TYPE", value: "worker" }
                  ]
                }
              }
            ]
          },
          retry_strategy: { attempts: 1 },
          timeout: { attempt_duration_seconds: 7200 }
        })
      }.not_to raise_error
    end
  end

  describe "edge cases and error handling" do
    it "handles validation errors gracefully" do
      expect {
        test_instance.aws_batch_job_definition(:invalid_job, {
          job_definition_name: "invalid@name",
          type: "container",
          container_properties: { image: "test:latest" }
        })
      }.to raise_error(Dry::Struct::Error, /can only contain letters, numbers, hyphens, and underscores/)
    end
    
    it "handles missing required fields" do
      expect {
        test_instance.aws_batch_job_definition(:incomplete_job, {
          job_definition_name: "incomplete-job",
          type: "container"
          # Missing container_properties
        })
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles empty attributes hash" do
      expect {
        test_instance.aws_batch_job_definition(:empty_job, {})
      }.to raise_error(Dry::Struct::Error)
    end
    
    it "handles nil attributes" do
      expect {
        test_instance.aws_batch_job_definition(:nil_job, nil)
      }.to raise_error(Dry::Struct::Error)
    end
  end
end