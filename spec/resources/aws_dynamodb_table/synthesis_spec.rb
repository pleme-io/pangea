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
require 'pangea/resources/aws_dynamodb_table/resource'

RSpec.describe 'aws_dynamodb_table synthesis' do
  let(:synthesizer) { TerraformSynthesizer.new }

  describe 'terraform synthesis' do
    it 'synthesizes basic DynamoDB table' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_dynamodb_table(:users, {
          name: 'users-table',
          billing_mode: 'PAY_PER_REQUEST',
          hash_key: 'user_id',
          attribute: [{ name: 'user_id', type: 'S' }]
        })
      end

      result = synthesizer.synthesis
      table = result[:resource][:aws_dynamodb_table][:users]

      expect(table[:table_name]).to eq('users-table')
      expect(table[:billing_mode]).to eq('PAY_PER_REQUEST')
      expect(table[:hash_key]).to eq('user_id')
    end

    it 'synthesizes table with range key' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_dynamodb_table(:orders, {
          name: 'orders-table',
          billing_mode: 'PAY_PER_REQUEST',
          hash_key: 'user_id',
          range_key: 'order_id',
          attribute: [
            { name: 'user_id', type: 'S' },
            { name: 'order_id', type: 'S' }
          ]
        })
      end

      result = synthesizer.synthesis
      table = result[:resource][:aws_dynamodb_table][:orders]

      expect(table[:hash_key]).to eq('user_id')
      expect(table[:range_key]).to eq('order_id')
    end

    it 'synthesizes table with provisioned capacity' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_dynamodb_table(:provisioned, {
          name: 'provisioned-table',
          billing_mode: 'PROVISIONED',
          hash_key: 'id',
          attribute: [{ name: 'id', type: 'S' }],
          read_capacity: 5,
          write_capacity: 5
        })
      end

      result = synthesizer.synthesis
      table = result[:resource][:aws_dynamodb_table][:provisioned]

      expect(table[:billing_mode]).to eq('PROVISIONED')
      expect(table[:read_capacity]).to eq(5)
      expect(table[:write_capacity]).to eq(5)
    end

    it 'synthesizes table with tags' do
      synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_dynamodb_table(:tagged, {
          name: 'tagged-table',
          billing_mode: 'PAY_PER_REQUEST',
          hash_key: 'id',
          attribute: [{ name: 'id', type: 'S' }],
          tags: { Environment: 'production' }
        })
      end

      result = synthesizer.synthesis
      table = result[:resource][:aws_dynamodb_table][:tagged]

      expect(table[:tags][:Environment]).to eq('production')
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::AWS
        aws_dynamodb_table(:test, {
          name: 'test-table',
          billing_mode: 'PAY_PER_REQUEST',
          hash_key: 'id',
          attribute: [{ name: 'id', type: 'S' }]
        })
      end

      expect(ref.outputs[:arn]).to eq('${aws_dynamodb_table.test.arn}')
      expect(ref.outputs[:stream_arn]).to eq('${aws_dynamodb_table.test.stream_arn}')
    end
  end
end
