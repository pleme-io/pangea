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
require 'terraform-synthesizer'
require 'pangea/resources/cloudflare_ruleset/resource'
require 'pangea/resources/cloudflare_ruleset/types'

RSpec.describe 'cloudflare_ruleset synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:zone_id) { "023e105f4ecef8ad9ca31a8372d0c353" }
  let(:account_id) { "a" * 32 }

  describe 'WAF custom rules' do
    it 'synthesizes basic WAF ruleset' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_ruleset(:waf, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "Custom WAF Rules",
          description: "Block malicious traffic",
          kind: "zone",
          phase: "http_request_firewall_custom",
          rules: [{
            expression: '(ip.src eq 192.0.2.1)',
            action: "block",
            description: "Block specific IP"
          }]
        })
      end

      result = synthesizer.synthesis
      ruleset = result[:resource][:cloudflare_ruleset][:waf]

      expect(ruleset[:zone_id]).to eq(zone_id)
      expect(ruleset[:name]).to eq("Custom WAF Rules")
      expect(ruleset[:kind]).to eq("zone")
      expect(ruleset[:phase]).to eq("http_request_firewall_custom")
      expect(ruleset[:rules]).to be_an(Array)
      expect(ruleset[:rules].first[:expression]).to eq('(ip.src eq 192.0.2.1)')
      expect(ruleset[:rules].first[:action]).to eq("block")
    end

    it 'synthesizes multiple WAF rules' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_ruleset(:multi_waf, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "Multi-rule WAF",
          kind: "zone",
          phase: "http_request_firewall_custom",
          rules: [
            {
              expression: '(ip.src eq 192.0.2.1)',
              action: "block",
              description: "Block IP"
            },
            {
              expression: '(http.user_agent contains "badbot")',
              action: "challenge",
              description: "Challenge bad bots"
            }
          ]
        })
      end

      result = synthesizer.synthesis
      ruleset = result[:resource][:cloudflare_ruleset][:multi_waf]

      expect(ruleset[:rules].length).to eq(2)
      expect(ruleset[:rules][0][:action]).to eq("block")
      expect(ruleset[:rules][1][:action]).to eq("challenge")
    end
  end

  describe 'rate limiting rulesets' do
    it 'synthesizes rate limiting ruleset' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_ruleset(:ratelimit, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "API Rate Limiting",
          kind: "zone",
          phase: "http_ratelimit",
          rules: [{
            expression: '(http.request.uri.path matches "^/api/")',
            action: "block",
            ratelimit: {
              characteristics: ["cf.colo.id", "ip.src"],
              period: 10,
              requests_per_period: 100
            }
          }]
        })
      end

      result = synthesizer.synthesis
      ruleset = result[:resource][:cloudflare_ruleset][:ratelimit]

      expect(ruleset[:phase]).to eq("http_ratelimit")
      expect(ruleset[:rules].first[:ratelimit][:period]).to eq(10)
      expect(ruleset[:rules].first[:ratelimit][:requests_per_period]).to eq(100)
    end
  end

  describe 'cache rulesets' do
    it 'synthesizes cache configuration ruleset' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_ruleset(:cache, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "Cache Rules",
          kind: "zone",
          phase: "http_request_cache_settings",
          rules: [{
            expression: '(http.host eq "example.com")',
            action: "set_cache_settings",
            action_parameters: {
              edge_ttl: {
                mode: "override_origin",
                default: 7200
              },
              browser_ttl: {
                mode: "respect_origin"
              }
            }
          }]
        })
      end

      result = synthesizer.synthesis
      ruleset = result[:resource][:cloudflare_ruleset][:cache]

      expect(ruleset[:phase]).to eq("http_request_cache_settings")
      expect(ruleset[:rules].first[:action_parameters]).to be_a(Hash)
    end
  end

  describe 'redirect rulesets' do
    it 'synthesizes redirect ruleset' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_ruleset(:redirects, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "URL Redirects",
          kind: "zone",
          phase: "http_request_dynamic_redirect",
          rules: [{
            expression: '(http.request.uri.path eq "/old")',
            action: "redirect",
            action_parameters: {
              from_value: {
                target_url: {
                  value: "https://example.com/new"
                },
                status_code: 301
              }
            }
          }]
        })
      end

      result = synthesizer.synthesis
      ruleset = result[:resource][:cloudflare_ruleset][:redirects]

      expect(ruleset[:phase]).to eq("http_request_dynamic_redirect")
      expect(ruleset[:rules].first[:action]).to eq("redirect")
    end
  end

  describe 'account-scoped rulesets' do
    it 'synthesizes account-level ruleset' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_ruleset(:account_waf, {
          account_id: "a" * 32,
          name: "Account WAF",
          kind: "root",
          phase: "http_request_firewall_managed",
          rules: [{
            expression: "true",
            action: "execute",
            action_parameters: {
              id: "efb7b8c949ac4650a09736fc376e9aee"
            }
          }]
        })
      end

      result = synthesizer.synthesis
      ruleset = result[:resource][:cloudflare_ruleset][:account_waf]

      expect(ruleset[:account_id]).to eq(account_id)
      expect(ruleset[:kind]).to eq("root")
    end
  end

  describe 'rule references' do
    it 'synthesizes rules with refs for stable ordering' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_ruleset(:with_refs, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "Stable Rules",
          kind: "zone",
          phase: "http_request_firewall_custom",
          rules: [{
            ref: "rule-1",
            expression: '(ip.src eq 192.0.2.1)',
            action: "block"
          }]
        })
      end

      result = synthesizer.synthesis
      ruleset = result[:resource][:cloudflare_ruleset][:with_refs]

      expect(ruleset[:rules].first[:ref]).to eq("rule-1")
    end
  end

  describe 'enabled/disabled rules' do
    it 'synthesizes enabled rule' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_ruleset(:enabled, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "Test",
          kind: "zone",
          phase: "http_request_firewall_custom",
          rules: [{
            expression: "true",
            action: "block",
            enabled: true
          }]
        })
      end

      result = synthesizer.synthesis
      ruleset = result[:resource][:cloudflare_ruleset][:enabled]

      expect(ruleset[:rules].first[:enabled]).to be true
    end

    it 'synthesizes disabled rule' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_ruleset(:disabled, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "Test",
          kind: "zone",
          phase: "http_request_firewall_custom",
          rules: [{
            expression: "true",
            action: "block",
            enabled: false
          }]
        })
      end

      result = synthesizer.synthesis
      ruleset = result[:resource][:cloudflare_ruleset][:disabled]

      expect(ruleset[:rules].first[:enabled]).to be false
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_ruleset(:test, {
          zone_id: "023e105f4ecef8ad9ca31a8372d0c353",
          name: "Test",
          kind: "zone",
          phase: "http_request_firewall_custom",
          rules: [{
            expression: "true",
            action: "block"
          }]
        })
      end

      expect(ref.id).to eq("${cloudflare_ruleset.test.id}")
    end
  end

  describe 'validation' do
    it 'requires zone_id or account_id' do
      expect {
        Cloudflare::Types::RulesetAttributes.new(
          name: "Test",
          kind: "zone",
          phase: "http_request_firewall_custom",
          rules: [{ expression: "true", action: "block" }]
        )
      }.to raise_error(Dry::Struct::Error, /Either zone_id or account_id must be provided/)
    end

    it 'rejects both zone_id and account_id' do
      expect {
        Cloudflare::Types::RulesetAttributes.new(
          zone_id: zone_id,
          account_id: account_id,
          name: "Test",
          kind: "zone",
          phase: "http_request_firewall_custom",
          rules: [{ expression: "true", action: "block" }]
        )
      }.to raise_error(Dry::Struct::Error, /mutually exclusive/)
    end

    it 'requires at least one rule' do
      expect {
        Cloudflare::Types::RulesetAttributes.new(
          zone_id: zone_id,
          name: "Test",
          kind: "zone",
          phase: "http_request_firewall_custom",
          rules: []
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'helper methods' do
    it 'identifies zone-scoped ruleset' do
      attrs = Cloudflare::Types::RulesetAttributes.new(
        zone_id: zone_id,
        name: "Test",
        kind: "zone",
        phase: "http_request_firewall_custom",
        rules: [{ expression: "true", action: "block" }]
      )

      expect(attrs.zone_scoped?).to be true
      expect(attrs.account_scoped?).to be false
    end

    it 'identifies WAF ruleset' do
      attrs = Cloudflare::Types::RulesetAttributes.new(
        zone_id: zone_id,
        name: "Test",
        kind: "zone",
        phase: "http_request_firewall_custom",
        rules: [{ expression: "true", action: "block" }]
      )

      expect(attrs.waf_ruleset?).to be true
    end

    it 'identifies rate limiting ruleset' do
      attrs = Cloudflare::Types::RulesetAttributes.new(
        zone_id: zone_id,
        name: "Test",
        kind: "zone",
        phase: "http_ratelimit",
        rules: [{ expression: "true", action: "block" }]
      )

      expect(attrs.ratelimit_ruleset?).to be true
    end

    it 'identifies cache ruleset' do
      attrs = Cloudflare::Types::RulesetAttributes.new(
        zone_id: zone_id,
        name: "Test",
        kind: "zone",
        phase: "http_request_cache_settings",
        rules: [{ expression: "true", action: "set_cache_settings" }]
      )

      expect(attrs.cache_ruleset?).to be true
    end
  end
end
