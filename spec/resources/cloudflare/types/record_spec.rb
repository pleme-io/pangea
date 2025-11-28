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


require_relative '../../../spec_helper'

RSpec.describe Pangea::Resources::Cloudflare::Types::RecordAttributes do
  let(:zone_id) { "a" * 32 }

  describe "type validation and creation" do
    it "creates valid A record with required attributes" do
      record_attrs = described_class.new(
        zone_id: zone_id,
        name: "www",
        type: "A",
        value: "192.0.2.1"
      )

      expect(record_attrs.zone_id).to eq(zone_id)
      expect(record_attrs.name).to eq("www")
      expect(record_attrs.type).to eq("A")
      expect(record_attrs.value).to eq("192.0.2.1")
      expect(record_attrs.ttl).to eq(1)  # default automatic
      expect(record_attrs.proxied).to be false  # default
    end

    it "creates proxied A record" do
      record_attrs = described_class.new(
        zone_id: zone_id,
        name: "www",
        type: "A",
        value: "192.0.2.1",
        proxied: true
      )

      expect(record_attrs.proxied).to be true
      expect(record_attrs.ttl).to eq(1)  # automatic for proxied
    end

    it "creates MX record with priority" do
      record_attrs = described_class.new(
        zone_id: zone_id,
        name: "@",
        type: "MX",
        value: "mail.example.com",
        priority: 10
      )

      expect(record_attrs.type).to eq("MX")
      expect(record_attrs.priority).to eq(10)
    end

    it "creates TXT record" do
      record_attrs = described_class.new(
        zone_id: zone_id,
        name: "@",
        type: "TXT",
        value: "v=spf1 include:_spf.google.com ~all"
      )

      expect(record_attrs.type).to eq("TXT")
      expect(record_attrs.value).to match(/spf1/)
    end

    it "rejects MX record without priority" do
      expect {
        described_class.new(
          zone_id: zone_id,
          name: "@",
          type: "MX",
          value: "mail.example.com"
        )
      }.to raise_error(Dry::Struct::Error, /MX records require a priority/)
    end

    it "rejects proxied record for incompatible types" do
      expect {
        described_class.new(
          zone_id: zone_id,
          name: "@",
          type: "MX",
          value: "mail.example.com",
          priority: 10,
          proxied: true
        )
      }.to raise_error(Dry::Struct::Error, /Proxied.*only.*A, AAAA, and CNAME/)
    end

    it "rejects proxied record with custom TTL" do
      expect {
        described_class.new(
          zone_id: zone_id,
          name: "www",
          type: "A",
          value: "192.0.2.1",
          proxied: true,
          ttl: 3600
        )
      }.to raise_error(Dry::Struct::Error, /Proxied records must use TTL=1/)
    end
  end

  describe "computed properties" do
    it "identifies proxied records" do
      proxied_record = described_class.new(
        zone_id: zone_id,
        name: "www",
        type: "A",
        value: "192.0.2.1",
        proxied: true
      )

      dns_only_record = described_class.new(
        zone_id: zone_id,
        name: "www",
        type: "A",
        value: "192.0.2.1",
        proxied: false
      )

      expect(proxied_record.is_proxied?).to be true
      expect(dns_only_record.is_proxied?).to be false
    end

    it "identifies root domain records" do
      root_record = described_class.new(
        zone_id: zone_id,
        name: "@",
        type: "A",
        value: "192.0.2.1"
      )

      subdomain_record = described_class.new(
        zone_id: zone_id,
        name: "www",
        type: "A",
        value: "192.0.2.1"
      )

      expect(root_record.is_root_domain?).to be true
      expect(subdomain_record.is_root_domain?).to be false
    end

    it "identifies records that can be proxied" do
      a_record = described_class.new(zone_id: zone_id, name: "www", type: "A", value: "192.0.2.1")
      aaaa_record = described_class.new(zone_id: zone_id, name: "www", type: "AAAA", value: "2001:db8::1")
      cname_record = described_class.new(zone_id: zone_id, name: "www", type: "CNAME", value: "example.com")
      mx_record = described_class.new(zone_id: zone_id, name: "@", type: "MX", value: "mail.example.com", priority: 10)

      expect(a_record.can_be_proxied?).to be true
      expect(aaaa_record.can_be_proxied?).to be true
      expect(cname_record.can_be_proxied?).to be true
      expect(mx_record.can_be_proxied?).to be false
    end

    it "identifies record types correctly" do
      txt_record = described_class.new(zone_id: zone_id, name: "@", type: "TXT", value: "test")
      mx_record = described_class.new(zone_id: zone_id, name: "@", type: "MX", value: "mail.example.com", priority: 10)

      expect(txt_record.is_txt_record?).to be true
      expect(mx_record.is_mx_record?).to be true
    end
  end

  describe "real-world usage scenarios" do
    it "supports typical web hosting configuration" do
      web_record = described_class.new(
        zone_id: zone_id,
        name: "www",
        type: "A",
        value: "192.0.2.1",
        proxied: true,
        comment: "Main website"
      )

      expect(web_record.is_proxied?).to be true
      expect(web_record.can_be_proxied?).to be true
      expect(web_record.comment).to eq("Main website")
    end

    it "supports email configuration" do
      mx_record = described_class.new(
        zone_id: zone_id,
        name: "@",
        type: "MX",
        value: "aspmx.l.google.com",
        priority: 1,
        comment: "Google Workspace primary"
      )

      expect(mx_record.is_mx_record?).to be true
      expect(mx_record.requires_priority?).to be true
      expect(mx_record.priority).to eq(1)
    end
  end
end
