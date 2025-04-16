require 'terraform-synthesizer'
require 'pangea/processor'
require 'pangea/renderer'
require 'pangea/config'
require 'pangea/state'
require 'pangea/utils'
require 'thor'

module TheseUtils
  class << self
    def cfg
      @cfg ||= Pangea::Utils.symbolize(Pangea::Config.config)
    end

    def state_init
      state = Pangea::S3State.new
      cfg[:namespaces].each_key do |nk|
        ns_config = cfg[:namespaces][nk]
        case ns_config[:state][:type].to_sym
        when :s3
          bucket_name    = ns_config[:state][:config][:bucket]
          region         = ns_config[:state][:config][:region]
          lock_table_name = ns_config[:state][:config][:lock]
          state.create_bucket(name: bucket_name, region: region)
          state.create_dynamodb_table_for_lock(name: lock_table_name, region: region)
        end
      end
    end
  end
end

module Pangea
  class Cli < Thor
    desc 'apply FILE', 'apply a FILE of pangea code'
    def apply(file)
      Pangea::Processor.register_action('plan')
      Pangea::Processor.process(File.read(file))
    end

    desc 'show FILE', 'transpile a FILE of pangea code to json'
    def show(file)
      Pangea::Processor.register_action('show')
      Pangea::Processor.process(File.read(file))
    end

    desc 'plan FILE', 'plan a FILE of pangea code'
    def plan(file)
      Pangea::Processor.register_action('plan')
      Pangea::Processor.process(File.read(file))
    end

    desc 'destroy FILE', 'destroy a FILE of pangea code'
    def destroy(file)
      Pangea::Processor.register_action('destroy')
      Pangea::Processor.process(File.read(file))
    end

    desc 'init', 'initialize an s3 state configuation according to pangea.yml'
    def init
      TheseUtils.state_init
    end
  end
end
