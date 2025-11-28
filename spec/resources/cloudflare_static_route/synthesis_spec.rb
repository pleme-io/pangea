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
require 'pangea/resources/cloudflare_static_route/resource'
require 'pangea/resources/cloudflare_static_route/types'

RSpec.describe 'cloudflare_static_route synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }

  describe 'basic static routes' do
    it 'synthesizes minimal route' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_static_route(:basic, {
          account_id: "a" * 32,
          prefix: "192.0.2.0/24",
          nexthop: "10.0.0.1",
          priority: 100
        })
      end

      result = synthesizer.synthesis
      route = result[:resource][:cloudflare_magic_wan_static_route][:basic]

      expect(route[:account_id]).to eq(account_id)
      expect(route[:prefix]).to eq("192.0.2.0/24")
      expect(route[:nexthop]).to eq("10.0.0.1")
      expect(route[:priority]).to eq(100)
    end

    it 'synthesizes route with description' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_static_route(:described, {
          account_id: "a" * 32,
          prefix: "192.0.2.0/24",
          nexthop: "10.0.0.1",
          priority: 100,
          description: "Route to datacenter A"
        })
      end

      result = synthesizer.synthesis
      route = result[:resource][:cloudflare_magic_wan_static_route][:described]

      expect(route[:description]).to eq("Route to datacenter A")
    end
  end

  describe 'priority levels' do
    it 'synthesizes high priority route' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_static_route(:high_priority, {
          account_id: "a" * 32,
          prefix: "192.0.2.0/24",
          nexthop: "10.0.0.1",
          priority: 10
        })
      end

      result = synthesizer.synthesis
      route = result[:resource][:cloudflare_magic_wan_static_route][:high_priority]

      expect(route[:priority]).to eq(10)
    end

    it 'synthesizes low priority route' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_static_route(:low_priority, {
          account_id: "a" * 32,
          prefix: "192.0.2.0/24",
          nexthop: "10.0.0.1",
          priority: 200
        })
      end

      result = synthesizer.synthesis
      route = result[:resource][:cloudflare_magic_wan_static_route][:low_priority]

      expect(route[:priority]).to eq(200)
    end
  end

  describe 'ECMP with weights' do
    it 'synthesizes route with weight' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_static_route(:weighted, {
          account_id: "a" * 32,
          prefix: "192.0.2.0/24",
          nexthop: "10.0.0.1",
          priority: 100,
          weight: 128
        })
      end

      result = synthesizer.synthesis
      route = result[:resource][:cloudflare_magic_wan_static_route][:weighted]

      expect(route[:weight]).to eq(128)
    end

    it 'synthesizes multiple ECMP routes' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        cloudflare_static_route(:ecmp1, {
          account_id: "a" * 32,
          prefix: "192.0.2.0/24",
          nexthop: "10.0.0.1",
          priority: 100,
          weight: 200
        })

        cloudflare_static_route(:ecmp2, {
          account_id: "a" * 32,
          prefix: "192.0.2.0/24",
          nexthop: "10.0.0.2",
          priority: 100,
          weight: 56
        })
      end

      result = synthesizer.synthesis
      routes = result[:resource][:cloudflare_magic_wan_static_route]

      expect(routes[:ecmp1][:weight]).to eq(200)
      expect(routes[:ecmp2][:weight]).to eq(56)
      expect(routes[:ecmp1][:priority]).to eq(routes[:ecmp2][:priority])
    end
  end

  describe 'scoped routes' do
    it 'synthesizes route scoped to region' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_static_route(:regional, {
          account_id: "a" * 32,
          prefix: "192.0.2.0/24",
          nexthop: "10.0.0.1",
          priority: 50,
          scope: { colo_regions: ["APAC", "EEUR"] }
        })
      end

      result = synthesizer.synthesis
      route = result[:resource][:cloudflare_magic_wan_static_route][:regional]

      expect(route[:scope][:colo_regions]).to eq(["APAC", "EEUR"])
    end

    it 'synthesizes route scoped to specific colos' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_static_route(:colo_specific, {
          account_id: "a" * 32,
          prefix: "192.0.2.0/24",
          nexthop: "10.0.0.1",
          priority: 50,
          scope: { colo_names: ["SJC", "LAX"] }
        })
      end

      result = synthesizer.synthesis
      route = result[:resource][:cloudflare_magic_wan_static_route][:colo_specific]

      expect(route[:scope][:colo_names]).to eq(["SJC", "LAX"])
    end
  end

  describe 'different network prefixes' do
    it 'synthesizes /32 host route' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_static_route(:host_route, {
          account_id: "a" * 32,
          prefix: "192.0.2.1/32",
          nexthop: "10.0.0.1",
          priority: 100
        })
      end

      result = synthesizer.synthesis
      route = result[:resource][:cloudflare_magic_wan_static_route][:host_route]

      expect(route[:prefix]).to eq("192.0.2.1/32")
    end

    it 'synthesizes /8 class A route' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_static_route(:class_a, {
          account_id: "a" * 32,
          prefix: "10.0.0.0/8",
          nexthop: "172.16.0.1",
          priority: 100
        })
      end

      result = synthesizer.synthesis
      route = result[:resource][:cloudflare_magic_wan_static_route][:class_a]

      expect(route[:prefix]).to eq("10.0.0.0/8")
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_static_route(:test, {
          account_id: "a" * 32,
          prefix: "192.0.2.0/24",
          nexthop: "10.0.0.1",
          priority: 100
        })
      end

      expect(ref.id).to eq("${cloudflare_magic_wan_static_route.test.id}")
    end
  end

  describe 'validation' do
    it 'validates CIDR format' do
      expect {
        Cloudflare::Types::StaticRouteAttributes.new(
          account_id: account_id,
          prefix: "invalid-cidr",
          nexthop: "10.0.0.1",
          priority: 100
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'validates nexthop IP format' do
      expect {
        Cloudflare::Types::StaticRouteAttributes.new(
          account_id: account_id,
          prefix: "192.0.2.0/24",
          nexthop: "invalid-ip",
          priority: 100
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'validates weight range' do
      expect {
        Cloudflare::Types::StaticRouteAttributes.new(
          account_id: account_id,
          prefix: "192.0.2.0/24",
          nexthop: "10.0.0.1",
          priority: 100,
          weight: 300  # Too high
        )
      }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  describe 'helper methods' do
    it 'identifies routes with weight' do
      attrs = Cloudflare::Types::StaticRouteAttributes.new(
        account_id: account_id,
        prefix: "192.0.2.0/24",
        nexthop: "10.0.0.1",
        priority: 100,
        weight: 128
      )

      expect(attrs.has_weight?).to be true
    end

    it 'identifies scoped routes' do
      attrs = Cloudflare::Types::StaticRouteAttributes.new(
        account_id: account_id,
        prefix: "192.0.2.0/24",
        nexthop: "10.0.0.1",
        priority: 100,
        scope: { colo_regions: ["APAC"] }
      )

      expect(attrs.scoped?).to be true
    end

    it 'provides priority level description' do
      high = Cloudflare::Types::StaticRouteAttributes.new(
        account_id: account_id,
        prefix: "192.0.2.0/24",
        nexthop: "10.0.0.1",
        priority: 10
      )

      medium = Cloudflare::Types::StaticRouteAttributes.new(
        account_id: account_id,
        prefix: "192.0.2.0/24",
        nexthop: "10.0.0.1",
        priority: 100
      )

      low = Cloudflare::Types::StaticRouteAttributes.new(
        account_id: account_id,
        prefix: "192.0.2.0/24",
        nexthop: "10.0.0.1",
        priority: 200
      )

      expect(high.priority_level).to eq("high")
      expect(medium.priority_level).to eq("medium")
      expect(low.priority_level).to eq("low")
    end
  end
end
