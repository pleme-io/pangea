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
require 'pangea/resources/cloudflare_workers_cron_trigger/resource'
require 'pangea/resources/cloudflare_workers_cron_trigger/types'

RSpec.describe 'cloudflare_workers_cron_trigger synthesis' do
  include Pangea::Resources::Cloudflare

  let(:synthesizer) { TerraformSynthesizer.new }
  let(:account_id) { "a" * 32 }

  describe 'terraform synthesis' do
    it 'synthesizes cron trigger running every 30 minutes' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_cron_trigger(:frequent, {
          account_id: "a" * 32,
          script_name: "cleanup-worker",
          schedules: ["*/30 * * * *"]
        })
      end

      result = synthesizer.synthesis
      trigger = result[:resource][:cloudflare_workers_cron_trigger][:frequent]

      expect(trigger).to include(
        account_id: account_id,
        script_name: "cleanup-worker",
        schedules: ["*/30 * * * *"]
      )
    end

    it 'synthesizes daily cron trigger at 2 AM' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_cron_trigger(:daily, {
          account_id: "a" * 32,
          script_name: "daily-report",
          schedules: ["0 2 * * *"]
        })
      end

      result = synthesizer.synthesis
      trigger = result[:resource][:cloudflare_workers_cron_trigger][:daily]

      expect(trigger[:schedules]).to eq(["0 2 * * *"])
    end

    it 'synthesizes hourly cron trigger' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_cron_trigger(:hourly, {
          account_id: "a" * 32,
          script_name: "hourly-sync",
          schedules: ["0 * * * *"]
        })
      end

      result = synthesizer.synthesis
      trigger = result[:resource][:cloudflare_workers_cron_trigger][:hourly]

      expect(trigger[:schedules]).to eq(["0 * * * *"])
    end

    it 'synthesizes cron trigger with multiple schedules' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_cron_trigger(:multi, {
          account_id: "a" * 32,
          script_name: "sync-worker",
          schedules: [
            "0 8 * * *",   # 8 AM
            "0 12 * * *",  # Noon
            "0 20 * * *"   # 8 PM
          ]
        })
      end

      result = synthesizer.synthesis
      trigger = result[:resource][:cloudflare_workers_cron_trigger][:multi]

      expect(trigger[:schedules]).to eq([
        "0 8 * * *",
        "0 12 * * *",
        "0 20 * * *"
      ])
    end

    it 'synthesizes weekly cron trigger' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_cron_trigger(:weekly, {
          account_id: "a" * 32,
          script_name: "weekly-cleanup",
          schedules: ["0 3 * * 0"]  # Sunday at 3 AM
        })
      end

      result = synthesizer.synthesis
      trigger = result[:resource][:cloudflare_workers_cron_trigger][:weekly]

      expect(trigger[:schedules]).to eq(["0 3 * * 0"])
    end

    it 'synthesizes monthly cron trigger' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_cron_trigger(:monthly, {
          account_id: "a" * 32,
          script_name: "monthly-report",
          schedules: ["0 0 1 * *"]  # First day of month at midnight
        })
      end

      result = synthesizer.synthesis
      trigger = result[:resource][:cloudflare_workers_cron_trigger][:monthly]

      expect(trigger[:schedules]).to eq(["0 0 1 * *"])
    end

    it 'synthesizes every 5 minutes cron trigger' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_cron_trigger(:very_frequent, {
          account_id: "a" * 32,
          script_name: "polling-worker",
          schedules: ["*/5 * * * *"]
        })
      end

      result = synthesizer.synthesis
      trigger = result[:resource][:cloudflare_workers_cron_trigger][:very_frequent]

      expect(trigger[:schedules]).to eq(["*/5 * * * *"])
    end

    it 'synthesizes business hours cron trigger' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_cron_trigger(:business_hours, {
          account_id: "a" * 32,
          script_name: "business-worker",
          schedules: ["0 9-17 * * 1-5"]  # 9 AM to 5 PM on weekdays
        })
      end

      result = synthesizer.synthesis
      trigger = result[:resource][:cloudflare_workers_cron_trigger][:business_hours]

      expect(trigger[:schedules]).to eq(["0 9-17 * * 1-5"])
    end
  end

  describe 'resource composition' do
    it 'creates worker with cron trigger' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Create worker script
        cloudflare_worker_script(:cleanup, {
          account_id: "a" * 32,
          name: "cleanup-worker",
          content: "export default { async scheduled(event, env, ctx) { console.log('Running cleanup') } }"
        })

        # Create cron trigger for the worker
        cloudflare_workers_cron_trigger(:cleanup_schedule, {
          account_id: "a" * 32,
          script_name: "cleanup-worker",
          schedules: ["0 2 * * *"]
        })
      end

      result = synthesizer.synthesis

      expect(result[:resource][:cloudflare_worker_script]).to have_key(:cleanup)
      expect(result[:resource][:cloudflare_workers_cron_trigger]).to have_key(:cleanup_schedule)
    end

    it 'creates multiple cron triggers for different workers' do
      synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare

        # Daily cleanup
        cloudflare_workers_cron_trigger(:daily_cleanup, {
          account_id: "a" * 32,
          script_name: "cleanup-worker",
          schedules: ["0 2 * * *"]
        })

        # Hourly sync
        cloudflare_workers_cron_trigger(:hourly_sync, {
          account_id: "a" * 32,
          script_name: "sync-worker",
          schedules: ["0 * * * *"]
        })

        # Weekly report
        cloudflare_workers_cron_trigger(:weekly_report, {
          account_id: "a" * 32,
          script_name: "report-worker",
          schedules: ["0 9 * * 1"]  # Monday at 9 AM
        })
      end

      result = synthesizer.synthesis
      triggers = result[:resource][:cloudflare_workers_cron_trigger]

      expect(triggers).to have_key(:daily_cleanup)
      expect(triggers).to have_key(:hourly_sync)
      expect(triggers).to have_key(:weekly_report)
    end
  end

  describe 'resource references' do
    it 'provides correct terraform interpolation strings' do
      ref = synthesizer.instance_eval do
        extend Pangea::Resources::Cloudflare
        cloudflare_workers_cron_trigger(:test, {
          account_id: "a" * 32,
          script_name: "test-worker",
          schedules: ["0 * * * *"]
        })
      end

      expect(ref.id).to eq("${cloudflare_workers_cron_trigger.test.id}")
      expect(ref.outputs[:trigger_id]).to eq("${cloudflare_workers_cron_trigger.test.id}")
    end
  end
end
