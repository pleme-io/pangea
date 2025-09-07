# frozen_string_literal: true

require_relative 'sagemaker/model_package_group'
require_relative 'sagemaker/feature_group'
require_relative 'sagemaker/pipeline'

module Pangea
  module Resources
    module AWS
      # Amazon SageMaker Extended resources for machine learning workflows
      module SageMaker
        include ModelPackageGroup
        include FeatureGroup
        include Pipeline
      end
    end
  end
end