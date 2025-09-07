# frozen_string_literal: true

require_relative 'lookout/equipment'
require_relative 'lookout/metrics'

module Pangea
  module Resources
    module AWS
      # Amazon Lookout services for anomaly detection and predictive analytics
      module Lookout
        include Equipment
        include Metrics
      end
    end
  end
end