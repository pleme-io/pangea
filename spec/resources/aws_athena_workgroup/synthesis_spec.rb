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
require 'pangea/resources/aws_athena_workgroup/resource'

RSpec.describe "aws_athena_workgroup synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, {
          name: "test_workgroup"
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_athena_workgroup")
      expect(result["resource"]["aws_athena_workgroup"]).to have_key("test")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, {
          name: "described_workgroup",
          description: "Workgroup for analytics queries"
        })
      end

      result = synthesizer.synthesis
      wg_config = result["resource"]["aws_athena_workgroup"]["test"]

      expect(wg_config["description"]).to eq("Workgroup for analytics queries")
    end

    it "supports state configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, {
          name: "disabled_workgroup",
          state: "DISABLED"
        })
      end

      result = synthesizer.synthesis
      wg_config = result["resource"]["aws_athena_workgroup"]["test"]

      expect(wg_config["state"]).to eq("DISABLED")
    end

    it "supports force_destroy flag" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, {
          name: "destroyable_workgroup",
          force_destroy: true
        })
      end

      result = synthesizer.synthesis
      wg_config = result["resource"]["aws_athena_workgroup"]["test"]

      expect(wg_config["force_destroy"]).to eq(true)
    end

    it "supports configuration with result_configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, {
          name: "configured_workgroup",
          configuration: {
            result_configuration: {
              output_location: "s3://my-bucket/athena-results/"
            }
          }
        })
      end

      result = synthesizer.synthesis
      wg_config = result["resource"]["aws_athena_workgroup"]["test"]

      expect(wg_config).to have_key("configuration")
      expect(wg_config["configuration"]).to have_key("result_configuration")
      expect(wg_config["configuration"]["result_configuration"]["output_location"]).to eq("s3://my-bucket/athena-results/")
    end

    it "supports encryption configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, {
          name: "encrypted_workgroup",
          configuration: {
            result_configuration: {
              output_location: "s3://encrypted-bucket/results/",
              encryption_configuration: {
                encryption_option: "SSE_KMS",
                kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
              }
            }
          }
        })
      end

      result = synthesizer.synthesis
      wg_config = result["resource"]["aws_athena_workgroup"]["test"]

      expect(wg_config["configuration"]["result_configuration"]).to have_key("encryption_configuration")
    end

    it "supports enforce_workgroup_configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, {
          name: "enforced_workgroup",
          configuration: {
            enforce_workgroup_configuration: true,
            result_configuration: {
              output_location: "s3://my-bucket/results/"
            }
          }
        })
      end

      result = synthesizer.synthesis
      wg_config = result["resource"]["aws_athena_workgroup"]["test"]

      expect(wg_config["configuration"]["enforce_workgroup_configuration"]).to eq(true)
    end

    it "supports publish_cloudwatch_metrics_enabled" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, {
          name: "metrics_workgroup",
          configuration: {
            publish_cloudwatch_metrics_enabled: true
          }
        })
      end

      result = synthesizer.synthesis
      wg_config = result["resource"]["aws_athena_workgroup"]["test"]

      expect(wg_config["configuration"]["publish_cloudwatch_metrics_enabled"]).to eq(true)
    end

    it "supports bytes_scanned_cutoff_per_query" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, {
          name: "limited_workgroup",
          configuration: {
            bytes_scanned_cutoff_per_query: 10_737_418_240 # 10GB
          }
        })
      end

      result = synthesizer.synthesis
      wg_config = result["resource"]["aws_athena_workgroup"]["test"]

      expect(wg_config["configuration"]["bytes_scanned_cutoff_per_query"]).to eq(10_737_418_240)
    end

    it "supports engine_version configuration" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, {
          name: "versioned_workgroup",
          configuration: {
            engine_version: {
              selected_engine_version: "Athena engine version 3"
            }
          }
        })
      end

      result = synthesizer.synthesis
      wg_config = result["resource"]["aws_athena_workgroup"]["test"]

      expect(wg_config["configuration"]).to have_key("engine_version")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, {
          name: "tagged_workgroup",
          tags: { Name: "analytics-workgroup", Environment: "production" }
        })
      end

      result = synthesizer.synthesis
      wg_config = result["resource"]["aws_athena_workgroup"]["test"]

      expect(wg_config).to have_key("tags")
      expect(wg_config["tags"]["Name"]).to eq("analytics-workgroup")
      expect(wg_config["tags"]["Environment"]).to eq("production")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_athena_workgroup(:test, { name: "valid_workgroup" })
      end

      result = synthesizer.synthesis

      # Validate structure
      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_athena_workgroup"]).to be_a(Hash)
      expect(result["resource"]["aws_athena_workgroup"]["test"]).to be_a(Hash)
    end
  end

  describe "resource references" do
    it "returns a resource reference with outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_workgroup(:test, { name: "ref_test_workgroup" })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_athena_workgroup.test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_athena_workgroup.test.arn}")
    end

    it "returns computed properties for enabled workgroups" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_workgroup(:test, {
          name: "enabled_workgroup",
          state: "ENABLED"
        })
      end

      expect(ref.computed_properties[:enabled]).to eq(true)
    end

    it "returns computed properties for workgroups with output location" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_workgroup(:test, {
          name: "output_workgroup",
          configuration: {
            result_configuration: {
              output_location: "s3://bucket/results/"
            }
          }
        })
      end

      expect(ref.computed_properties[:has_output_location]).to eq(true)
    end

    it "returns computed properties for workgroups with KMS encryption" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_workgroup(:test, {
          name: "kms_workgroup",
          configuration: {
            result_configuration: {
              output_location: "s3://bucket/results/",
              encryption_configuration: {
                encryption_option: "SSE_KMS",
                kms_key_id: "arn:aws:kms:us-east-1:123456789012:key/12345678"
              }
            }
          }
        })
      end

      expect(ref.computed_properties[:encryption_type]).to eq("SSE_KMS")
      expect(ref.computed_properties[:uses_kms]).to eq(true)
    end

    it "returns computed properties for workgroups with query limits" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_workgroup(:test, {
          name: "limited_workgroup",
          configuration: {
            bytes_scanned_cutoff_per_query: 1_073_741_824 # 1GB
          }
        })
      end

      expect(ref.computed_properties[:has_query_limits]).to eq(true)
      expect(ref.computed_properties[:query_limit_gb]).to be_within(0.01).of(1.0)
    end

    it "returns computed properties for enforced configuration" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_athena_workgroup(:test, {
          name: "enforced_workgroup",
          configuration: {
            enforce_workgroup_configuration: true
          }
        })
      end

      expect(ref.computed_properties[:enforces_configuration]).to eq(true)
    end
  end
end
