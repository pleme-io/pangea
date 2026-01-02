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
  module Resources
    module AWS
      module LoadBalancing
        # Attachment related resource methods
        module Attachments
          def aws_alb_target_group_attachment(name, attributes = {})
            resource = LoadBalancing::AlbTargetGroupAttachment.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::AlbTargetGroupAttachment::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          def aws_lb_target_group_attachment(name, attributes = {})
            resource = LoadBalancing::LbTargetGroupAttachment.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::LbTargetGroupAttachment::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          def aws_elb_attachment(name, attributes = {})
            resource = LoadBalancing::ElbAttachment.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::ElbAttachment::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end

          def aws_elb_service_account(name, attributes = {})
            resource = LoadBalancing::ElbServiceAccount.new(
              name: name,
              synthesizer: synthesizer,
              attributes: LoadBalancing::ElbServiceAccount::Attributes.new(attributes)
            )
            resource.synthesize
            resource.reference
          end
        end
      end
    end
  end
end
