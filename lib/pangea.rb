require 'pangea/config'
require 'pangea/state'
require 'pangea/utils'
require 'pangea/cli'
require 'json'

module Pangea
  autoload :Module, File.join(__dir__, 'pangea', 'module')

  module App
    class << self
      def cfg
        @cfg ||= Pangea::Utils.symbolize(
          Pangea::Config.config
        )
      end

      def run
        Pangea::Cli.start(ARGV)
      end
    end
  end
end
