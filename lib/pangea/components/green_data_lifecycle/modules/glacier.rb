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

module Pangea
  module Components
    module GreenDataLifecycle
      # Glacier vault resources for Green Data Lifecycle component
      module Glacier
        private

        def create_glacier_vault(input)
          aws_glacier_vault(:"#{input.name}-vault", {
            name: "#{input.name}-deep-archive",
            access_policy: glacier_access_policy,
            notification: glacier_notification_config(input),
            tags: component_tags(input)
          })
        end

        def glacier_access_policy
          JSON.pretty_generate({
            Version: "2012-10-17",
            Statement: [{
              Effect: "Allow",
              Principal: { AWS: "*" },
              Action: ["glacier:UploadArchive"],
              Resource: "*",
              Condition: {
                StringEquals: {
                  "glacier:ArchiveDescription": ["green-lifecycle-archive"]
                }
              }
            }]
          })
        end

        def glacier_notification_config(input)
          {
            sns_topic: ref(:aws_sns_topic, :"#{input.name}-glacier-notifications", :arn),
            events: ["ArchiveRetrievalCompleted", "InventoryRetrievalCompleted"]
          }
        end
      end
    end
  end
end
