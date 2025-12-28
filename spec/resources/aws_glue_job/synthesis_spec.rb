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
require 'terraform-synthesizer'
require 'pangea/resources/aws_glue_job/resource'

RSpec.describe "aws_glue_job synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_job(:test, {
          name: "test_job",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://scripts-bucket/scripts/etl.py"
          }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_glue_job")
      expect(result["resource"]["aws_glue_job"]).to have_key("test")
    end

    it "includes required command block" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_job(:test, {
          name: "etl_job",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://bucket/script.py",
            name: "glueetl",
            python_version: "3"
          }
        })
      end

      result = synthesizer.synthesis
      job_config = result["resource"]["aws_glue_job"]["test"]

      expect(job_config).to have_key("command")
      expect(job_config["command"]["script_location"]).to eq("s3://bucket/script.py")
      expect(job_config["command"]["name"]).to eq("glueetl")
      expect(job_config["command"]["python_version"]).to eq("3")
    end

    it "includes role_arn" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_job(:test, {
          name: "job_with_role",
          role_arn: "arn:aws:iam::123456789012:role/CustomGlueRole",
          command: {
            script_location: "s3://bucket/script.py"
          }
        })
      end

      result = synthesizer.synthesis
      job_config = result["resource"]["aws_glue_job"]["test"]

      expect(job_config["role_arn"]).to eq("arn:aws:iam::123456789012:role/CustomGlueRole")
    end

    it "supports worker configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_job(:test, {
          name: "worker_configured_job",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://bucket/script.py"
          },
          worker_type: "G.2X",
          number_of_workers: 10
        })
      end

      result = synthesizer.synthesis
      job_config = result["resource"]["aws_glue_job"]["test"]

      expect(job_config["worker_type"]).to eq("G.2X")
      expect(job_config["number_of_workers"]).to eq(10)
    end

    it "supports glue_version" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_job(:test, {
          name: "versioned_job",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://bucket/script.py"
          },
          glue_version: "4.0"
        })
      end

      result = synthesizer.synthesis
      job_config = result["resource"]["aws_glue_job"]["test"]

      expect(job_config["glue_version"]).to eq("4.0")
    end

    it "supports timeout and max_retries" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_job(:test, {
          name: "retry_job",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://bucket/script.py"
          },
          timeout: 120,
          max_retries: 3
        })
      end

      result = synthesizer.synthesis
      job_config = result["resource"]["aws_glue_job"]["test"]

      expect(job_config["timeout"]).to eq(120)
      expect(job_config["max_retries"]).to eq(3)
    end

    it "supports default_arguments" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_job(:test, {
          name: "job_with_args",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://bucket/script.py"
          },
          default_arguments: {
            "--enable-metrics" => "",
            "--job-bookmark-option" => "job-bookmark-enable"
          }
        })
      end

      result = synthesizer.synthesis
      job_config = result["resource"]["aws_glue_job"]["test"]

      expect(job_config).to have_key("default_arguments")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_job(:test, {
          name: "tagged_job",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://bucket/script.py"
          },
          tags: { Name: "etl-job", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      job_config = result["resource"]["aws_glue_job"]["test"]

      expect(job_config).to have_key("tags")
      expect(job_config["tags"]["Name"]).to eq("etl-job")
      expect(job_config["tags"]["Environment"]).to eq("production")
    end

    it "supports connections" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_job(:test, {
          name: "job_with_connections",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://bucket/script.py"
          },
          connections: ["jdbc-connection", "redshift-connection"]
        })
      end

      result = synthesizer.synthesis
      job_config = result["resource"]["aws_glue_job"]["test"]

      expect(job_config["connections"]).to eq(["jdbc-connection", "redshift-connection"])
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_glue_job(:test, {
          name: "valid_job",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://bucket/script.py"
          }
        })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_glue_job"]).to be_a(Hash)
      expect(result["resource"]["aws_glue_job"]["test"]).to be_a(Hash)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_job(:test, {
          name: "ref_test_job",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://bucket/script.py"
          }
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_glue_job.test.id}")
      expect(ref.outputs[:name]).to eq("${aws_glue_job.test.name}")
      expect(ref.outputs[:arn]).to eq("${aws_glue_job.test.arn}")
    end

    it "returns computed properties for worker configuration" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_job(:test, {
          name: "worker_job",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://bucket/script.py"
          },
          worker_type: "G.1X",
          number_of_workers: 5
        })
      end

      expect(ref.computed_properties[:uses_worker_configuration]).to eq(true)
      expect(ref.computed_properties[:estimated_dpu_capacity]).to eq(5.0)
    end

    it "returns computed properties for streaming jobs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_glue_job(:test, {
          name: "streaming_job",
          role_arn: "arn:aws:iam::123456789012:role/GlueJobRole",
          command: {
            script_location: "s3://bucket/streaming.py",
            name: "gluestreaming"
          },
          worker_type: "G.1X",
          number_of_workers: 2
        })
      end

      expect(ref.computed_properties[:is_streaming_job]).to eq(true)
      expect(ref.computed_properties[:is_etl_job]).to eq(false)
    end
  end
end
