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
require 'pangea/resources/cloudflare_queue/resource'
require 'pangea/resources/cloudflare_queue/types'
require 'pangea/resources/cloudflare_worker_script/resource'

RSpec.describe 'cloudflare_queue synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }

  describe 'terraform synthesis' do
    it 'synthesizes basic queue with minimal configuration' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_queue(:tasks, {
          account_id: "a" * 32,
          queue_name: "background-tasks"
        })
      end

      result = synthesizer.synthesis
      queue = result[:resource][:cloudflare_queue][:tasks]

      expect(queue).to include(
        account_id: account_id,
        name: "background-tasks"
      )
      expect(queue).not_to have_key(:max_concurrency)
      expect(queue).not_to have_key(:max_retries)
    end

    it 'synthesizes queue with concurrency and retry settings' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_queue(:email, {
          account_id: "a" * 32,
          queue_name: "email-delivery",
          max_concurrency: 20,
          max_retries: 5,
          retry_delay: 60
        })
      end

      result = synthesizer.synthesis
      queue = result[:resource][:cloudflare_queue][:email]

      expect(queue[:name]).to eq("email-delivery")
      expect(queue[:max_concurrency]).to eq(20)
      expect(queue[:max_retries]).to eq(5)
      expect(queue[:retry_delay]).to eq(60)
    end

    it 'synthesizes queue with all optional parameters' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_queue(:analytics, {
          account_id: "a" * 32,
          queue_name: "analytics-events",
          max_concurrency: 100,
          max_retries: 3,
          max_wait_time_ms: 60000,
          retry_delay: 30,
          visibility_timeout_ms: 30000,
          message_retention_period: 604800  # 7 days
        })
      end

      result = synthesizer.synthesis
      queue = result[:resource][:cloudflare_queue][:analytics]

      expect(queue).to include(
        name: "analytics-events",
        max_concurrency: 100,
        max_retries: 3,
        max_wait_time_ms: 60000,
        retry_delay: 30,
        visibility_timeout_ms: 30000,
        message_retention_period: 604800
      )
    end

    it 'synthesizes queue with long retention period' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_queue(:audit_logs, {
          account_id: "a" * 32,
          queue_name: "audit-log-processing",
          message_retention_period: 1209600  # 14 days (maximum)
        })
      end

      result = synthesizer.synthesis
      queue = result[:resource][:cloudflare_queue][:audit_logs]

      expect(queue[:message_retention_period]).to eq(1209600)
    end

    it 'synthesizes multiple queues for different purposes' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        cloudflare_queue(:high_priority, {
          account_id: "a" * 32,
          queue_name: "high-priority-tasks",
          max_concurrency: 50,
          max_retries: 5
        })

        cloudflare_queue(:low_priority, {
          account_id: "a" * 32,
          queue_name: "low-priority-tasks",
          max_concurrency: 10,
          max_retries: 3
        })

        cloudflare_queue(:dead_letter, {
          account_id: "a" * 32,
          queue_name: "failed-tasks",
          max_retries: 0,
          message_retention_period: 1209600
        })
      end

      result = synthesizer.synthesis
      queues = result[:resource][:cloudflare_queue]

      expect(queues).to have_key(:high_priority)
      expect(queues).to have_key(:low_priority)
      expect(queues).to have_key(:dead_letter)
      expect(queues[:high_priority][:max_concurrency]).to eq(50)
      expect(queues[:dead_letter][:max_retries]).to eq(0)
    end

    it 'synthesizes queues for environment-specific workloads' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Production queue - high capacity, long retention
        cloudflare_queue(:prod_queue, {
          account_id: "a" * 32,
          queue_name: "production-tasks",
          max_concurrency: 100,
          max_retries: 5,
          message_retention_period: 604800  # 7 days
        })

        # Staging queue - medium capacity
        cloudflare_queue(:staging_queue, {
          account_id: "a" * 32,
          queue_name: "staging-tasks",
          max_concurrency: 20,
          max_retries: 3
        })

        # Development queue - low capacity, short retention
        cloudflare_queue(:dev_queue, {
          account_id: "a" * 32,
          queue_name: "development-tasks",
          max_concurrency: 5,
          max_retries: 1,
          message_retention_period: 3600  # 1 hour
        })
      end

      result = synthesizer.synthesis
      queues = result[:resource][:cloudflare_queue]

      expect(queues[:prod_queue][:max_concurrency]).to eq(100)
      expect(queues[:staging_queue][:max_concurrency]).to eq(20)
      expect(queues[:dev_queue][:max_concurrency]).to eq(5)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_queue(:test, {
          account_id: "a" * 32,
          queue_name: "test-queue"
        })
      end

      expect(ref.id).to eq("${cloudflare_queue.test.id}")
      expect(ref.outputs[:queue_id]).to eq("${cloudflare_queue.test.id}")
      expect(ref.outputs[:queue_name]).to eq("${cloudflare_queue.test.name}")
    end

    it 'enables queue reference in worker scripts' do
      queue_ref = nil

      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Create queue
        queue_ref = cloudflare_queue(:tasks, {
          account_id: "a" * 32,
          queue_name: "background-tasks"
        })

        # Create worker that uses the queue
        cloudflare_worker_script(:processor, {
          account_id: "a" * 32,
          name: "task-processor",
          content: "export default { async fetch() { return new Response('OK') } }",
          queue_bindings: [
            { name: "TASK_QUEUE", queue_name: queue_ref.queue_name }
          ]
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:cloudflare_queue]).to have_key(:tasks)
      expect(result[:resource][:cloudflare_worker_script]).to have_key(:processor)

      worker = result[:resource][:cloudflare_worker_script][:processor]
      # Bindings are always Arrays in Terraform JSON format
      expect(worker[:queue_binding]).to be_an(Array)
      expect(worker[:queue_binding].length).to eq(1)
      expect(worker[:queue_binding][0][:name]).to eq("TASK_QUEUE")
      expect(worker[:queue_binding][0][:queue_name]).to eq("${cloudflare_queue.tasks.name}")
    end
  end

  describe 'resource composition' do
    it 'creates complete async processing infrastructure' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Main task queue
        cloudflare_queue(:main_queue, {
          account_id: "a" * 32,
          queue_name: "main-tasks",
          max_concurrency: 50,
          max_retries: 3
        })

        # Retry queue with longer delays
        cloudflare_queue(:retry_queue, {
          account_id: "a" * 32,
          queue_name: "retry-tasks",
          max_concurrency: 10,
          max_retries: 5,
          retry_delay: 300
        })

        # Dead letter queue for failed tasks
        cloudflare_queue(:dlq, {
          account_id: "a" * 32,
          queue_name: "failed-tasks",
          max_retries: 0,
          message_retention_period: 1209600  # 14 days
        })
      end

      result = synthesizer.synthesis
      queues = result[:resource][:cloudflare_queue]

      expect(queues).to have_key(:main_queue)
      expect(queues).to have_key(:retry_queue)
      expect(queues).to have_key(:dlq)
      expect(queues[:retry_queue][:retry_delay]).to eq(300)
      expect(queues[:dlq][:max_retries]).to eq(0)
    end
  end
end
