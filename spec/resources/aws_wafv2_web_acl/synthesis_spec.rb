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
require 'pangea/resources/aws_wafv2_web_acl/resource'

RSpec.describe "aws_wafv2_web_acl synthesis" do
  include Pangea::Resources::AWS

  let(:synthesizer) { TerraformSynthesizer.new }

  describe "terraform generation" do
    it "generates valid terraform JSON with allow default action" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_web_acl(:allow_acl, {
          name: "allow-web-acl",
          scope: "REGIONAL",
          default_action: { allow: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "allow-web-acl-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: { Environment: "production" }
        })
      end

      result = synthesizer.synthesis

      expect(result).to have_key("resource")
      expect(result["resource"]).to have_key("aws_wafv2_web_acl")
      expect(result["resource"]["aws_wafv2_web_acl"]).to have_key("allow_acl")

      web_acl = result["resource"]["aws_wafv2_web_acl"]["allow_acl"]
      expect(web_acl["name"]).to eq("allow-web-acl")
      expect(web_acl["scope"]).to eq("regional")
    end

    it "generates valid terraform JSON with block default action" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_web_acl(:block_acl, {
          name: "block-web-acl",
          scope: "REGIONAL",
          default_action: { block: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "block-web-acl-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      web_acl = result["resource"]["aws_wafv2_web_acl"]["block_acl"]

      expect(web_acl["name"]).to eq("block-web-acl")
    end

    it "generates web ACL with geo match rule" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_web_acl(:geo_acl, {
          name: "geo-web-acl",
          scope: "REGIONAL",
          default_action: { allow: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "geo-web-acl-metric",
            sampled_requests_enabled: true
          },
          rules: [
            {
              name: "block-countries",
              priority: 1,
              action: { block: {} },
              statement: {
                geo_match_statement: {
                  country_codes: ["CN", "RU", "KP"]
                }
              },
              visibility_config: {
                cloudwatch_metrics_enabled: true,
                metric_name: "block-countries-metric",
                sampled_requests_enabled: true
              }
            }
          ],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      web_acl = result["resource"]["aws_wafv2_web_acl"]["geo_acl"]

      expect(web_acl["name"]).to eq("geo-web-acl")
    end

    it "generates web ACL with rate based rule" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_web_acl(:rate_acl, {
          name: "rate-limited-acl",
          scope: "REGIONAL",
          default_action: { allow: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "rate-acl-metric",
            sampled_requests_enabled: true
          },
          rules: [
            {
              name: "rate-limit",
              priority: 1,
              action: { block: {} },
              statement: {
                rate_based_statement: {
                  limit: 2000,
                  aggregate_key_type: "IP"
                }
              },
              visibility_config: {
                cloudwatch_metrics_enabled: true,
                metric_name: "rate-limit-metric",
                sampled_requests_enabled: true
              }
            }
          ],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      web_acl = result["resource"]["aws_wafv2_web_acl"]["rate_acl"]

      expect(web_acl["name"]).to eq("rate-limited-acl")
    end

    it "generates web ACL with managed rule group" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_web_acl(:managed_acl, {
          name: "managed-rules-acl",
          scope: "REGIONAL",
          default_action: { allow: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "managed-acl-metric",
            sampled_requests_enabled: true
          },
          rules: [
            {
              name: "aws-managed-common",
              priority: 1,
              action: { count: {} },
              statement: {
                managed_rule_group_statement: {
                  vendor_name: "AWS",
                  name: "AWSManagedRulesCommonRuleSet"
                }
              },
              visibility_config: {
                cloudwatch_metrics_enabled: true,
                metric_name: "aws-managed-common-metric",
                sampled_requests_enabled: true
              }
            }
          ],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      web_acl = result["resource"]["aws_wafv2_web_acl"]["managed_acl"]

      expect(web_acl["name"]).to eq("managed-rules-acl")
    end

    it "includes description when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_web_acl(:described_acl, {
          name: "described-acl",
          description: "Web ACL with comprehensive security rules",
          scope: "REGIONAL",
          default_action: { allow: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "described-acl-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      web_acl = result["resource"]["aws_wafv2_web_acl"]["described_acl"]

      expect(web_acl).to have_key("description")
      expect(web_acl["description"]).to eq("Web ACL with comprehensive security rules")
    end

    it "supports CLOUDFRONT scope" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_web_acl(:cloudfront_acl, {
          name: "cloudfront-acl",
          scope: "CLOUDFRONT",
          default_action: { allow: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "cloudfront-acl-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      web_acl = result["resource"]["aws_wafv2_web_acl"]["cloudfront_acl"]

      expect(web_acl["scope"]).to eq("cloudfront")
    end

    it "includes tags when provided" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_web_acl(:tagged_acl, {
          name: "tagged-acl",
          scope: "REGIONAL",
          default_action: { allow: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "tagged-acl-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: { Environment: "production", Team: "security", CostCenter: "12345" }
        })
      end

      result = synthesizer.synthesis
      web_acl = result["resource"]["aws_wafv2_web_acl"]["tagged_acl"]

      expect(web_acl).to have_key("tags")
      expect(web_acl["tags"]["Environment"]).to eq("production")
      expect(web_acl["tags"]["Team"]).to eq("security")
    end

    it "generates web ACL with IP set reference" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_web_acl(:ip_set_acl, {
          name: "ip-set-acl",
          scope: "REGIONAL",
          default_action: { allow: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "ip-set-acl-metric",
            sampled_requests_enabled: true
          },
          rules: [
            {
              name: "block-ip-set",
              priority: 1,
              action: { block: {} },
              statement: {
                ip_set_reference_statement: {
                  arn: "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/blocked-ips/12345678-1234-1234-1234-123456789012"
                }
              },
              visibility_config: {
                cloudwatch_metrics_enabled: true,
                metric_name: "block-ip-set-metric",
                sampled_requests_enabled: true
              }
            }
          ],
          tags: {}
        })
      end

      result = synthesizer.synthesis
      web_acl = result["resource"]["aws_wafv2_web_acl"]["ip_set_acl"]

      expect(web_acl["name"]).to eq("ip-set-acl")
    end
  end

  describe "resource references" do
    it "returns a ResourceReference with correct outputs" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_wafv2_web_acl(:ref_test, {
          name: "ref-test-acl",
          scope: "REGIONAL",
          default_action: { allow: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "ref-test-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: {}
        })
      end

      expect(ref).to be_a(Pangea::Resources::ResourceReference)
      expect(ref.outputs[:id]).to eq("${aws_wafv2_web_acl.ref_test.id}")
      expect(ref.outputs[:arn]).to eq("${aws_wafv2_web_acl.ref_test.arn}")
      expect(ref.outputs[:capacity]).to eq("${aws_wafv2_web_acl.ref_test.capacity}")
      expect(ref.outputs[:lock_token]).to eq("${aws_wafv2_web_acl.ref_test.lock_token}")
    end

    it "returns computed properties" do
      ref = nil
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        ref = aws_wafv2_web_acl(:computed_test, {
          name: "computed-test-acl",
          scope: "REGIONAL",
          default_action: { allow: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "computed-test-metric",
            sampled_requests_enabled: true
          },
          rules: [
            {
              name: "geo-rule",
              priority: 1,
              action: { block: {} },
              statement: {
                geo_match_statement: {
                  country_codes: ["CN"]
                }
              },
              visibility_config: {
                cloudwatch_metrics_enabled: true,
                metric_name: "geo-rule-metric",
                sampled_requests_enabled: true
              }
            },
            {
              name: "rate-rule",
              priority: 2,
              action: { block: {} },
              statement: {
                rate_based_statement: {
                  limit: 2000,
                  aggregate_key_type: "IP"
                }
              },
              visibility_config: {
                cloudwatch_metrics_enabled: true,
                metric_name: "rate-rule-metric",
                sampled_requests_enabled: true
              }
            }
          ],
          tags: {}
        })
      end

      expect(ref.computed[:rule_count]).to eq(2)
      expect(ref.computed[:has_geo_blocking]).to eq(true)
      expect(ref.computed[:has_rate_limiting]).to eq(true)
      expect(ref.computed[:scope]).to eq("REGIONAL")
    end
  end

  describe "terraform validation" do
    it "produces valid terraform structure" do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_wafv2_web_acl(:validation_test, {
          name: "validation-test",
          scope: "REGIONAL",
          default_action: { allow: {} },
          visibility_config: {
            cloudwatch_metrics_enabled: true,
            metric_name: "validation-test-metric",
            sampled_requests_enabled: true
          },
          rules: [],
          tags: {}
        })
      end

      result = synthesizer.synthesis

      expect(result).to be_a(Hash)
      expect(result["resource"]).to be_a(Hash)
      expect(result["resource"]["aws_wafv2_web_acl"]).to be_a(Hash)
      expect(result["resource"]["aws_wafv2_web_acl"]["validation_test"]).to be_a(Hash)

      web_acl = result["resource"]["aws_wafv2_web_acl"]["validation_test"]
      expect(web_acl).to have_key("name")
      expect(web_acl).to have_key("scope")
      expect(web_acl).to have_key("default_action")
      expect(web_acl).to have_key("visibility_config")
    end
  end
end
