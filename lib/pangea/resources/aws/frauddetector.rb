# frozen_string_literal: true

require_relative 'frauddetector/detector'

module Pangea
  module Resources
    module AWS
      # Amazon Fraud Detector resources for fraud detection and prevention
      module FraudDetector
        include Detector
      end
    end
  end
end