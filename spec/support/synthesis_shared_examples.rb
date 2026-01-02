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

# Shared examples for synthesis tests
# These can be included in resource synthesis specs to reduce duplication

# Example usage:
#   it_behaves_like 'synthesizes terraform correctly', :cloudflare_zone

RSpec.shared_examples 'synthesizes terraform correctly' do |resource_type|
  it 'generates valid terraform resource structure' do
    result = synthesizer.synthesis
    expect(result).to be_a(Hash)
    expect(result[:resource]).to be_a(Hash)
    expect(result[:resource][resource_type]).to be_a(Hash)
  end

  it 'uses the correct resource name' do
    result = synthesizer.synthesis
    expect(result[:resource][resource_type]).to have_key(resource_name)
  end
end

# Example usage:
#   it_behaves_like 'provides terraform outputs', [:id, :arn]

RSpec.shared_examples 'provides terraform outputs' do |output_keys|
  it 'returns a ResourceReference with expected outputs' do
    expect(resource_ref).to be_a(Pangea::Resources::ResourceReference)
    expect(resource_ref.outputs).to be_a(Hash)

    output_keys.each do |key|
      expect(resource_ref.outputs).to have_key(key),
        "Expected output '#{key}' to be present"
    end
  end

  it 'provides valid terraform interpolation strings' do
    output_keys.each do |key|
      value = resource_ref.outputs[key]
      expect(value).to match(/\$\{[^}]+\}/),
        "Output '#{key}' should be a terraform interpolation string"
    end
  end
end

# Example usage:
#   it_behaves_like 'validates required attributes', [:name, :vpc_id]

RSpec.shared_examples 'validates required attributes' do |required_attrs|
  required_attrs.each do |attr|
    it "requires #{attr} attribute" do
      invalid_attrs = valid_attributes.dup
      invalid_attrs.delete(attr)

      expect {
        type_class.new(invalid_attrs)
      }.to raise_error(Dry::Struct::Error)
    end
  end
end

# Example usage:
#   it_behaves_like 'supports resource references'

RSpec.shared_examples 'supports resource references' do
  it 'provides id interpolation string' do
    expect(resource_ref.id).to match(/\$\{#{resource_type}\.#{resource_name}\.id\}/)
  end

  it 'provides outputs hash' do
    expect(resource_ref.outputs).to be_a(Hash)
    expect(resource_ref.outputs).not_to be_empty
  end
end

# Example usage:
#   it_behaves_like 'handles terraform interpolation in attributes', :zone_id

RSpec.shared_examples 'handles terraform interpolation in attributes' do |interpolated_attr|
  it "accepts terraform interpolation for #{interpolated_attr}" do
    interpolated_value = "${some_resource.name.id}"
    attrs_with_interpolation = valid_attributes.merge(
      interpolated_attr => interpolated_value
    )

    expect {
      type_class.new(attrs_with_interpolation)
    }.not_to raise_error
  end
end

# Example usage:
#   it_behaves_like 'applies tags correctly'

RSpec.shared_examples 'applies tags correctly' do
  it 'includes tags in synthesized output' do
    result = synthesizer.synthesis
    resource = result[:resource][resource_type][resource_name]

    expect(resource).to have_key(:tags)
    expect(resource[:tags]).to be_a(Hash)
  end

  it 'merges default and custom tags' do
    result = synthesizer.synthesis
    resource = result[:resource][resource_type][resource_name]

    custom_tags.each do |key, value|
      expect(resource[:tags][key]).to eq(value)
    end
  end
end

# Example usage:
#   it_behaves_like 'composition with zone', :cloudflare_zone

RSpec.shared_examples 'composition with zone' do |zone_resource_type|
  it 'correctly references zone_id' do
    result = synthesizer.synthesis
    resource = result[:resource][resource_type][resource_name]

    expect(resource[:zone_id]).to match(/\$\{#{zone_resource_type}\.\w+\.id\}/)
  end
end
