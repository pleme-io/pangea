require 'terraform-synthesizer'
require 'pangea/renderer'
require 'pangea/config'
require 'pangea/utils'
require 'aws-sdk-s3'

module Pangea
  # ingests files and builds a context
  # for rendering Pangea programming
  module Processor
    class << self
      def register_action(action)
        permitted_actions = %i[plan apply show]
        @action = action if permitted_actions.map(&:to_s).include?(action.to_s)
        @action = 'plan' if @action.nil?
      end

      def process(content)
        instance_eval(content)
      end

      def synthesizer
        @synthesizer ||= TerraformSynthesizer.new
      end

      def config
        @config ||= Pangea::Utils.symbolize(
          Pangea::Config.config
        )
      end

      def namespace
        @namespace ||= ENV.fetch('PANGEA_NAMESPACE')
      end

      def s3
        @s3 = Aws::S3::Client.new
      end

      def bin
        'tofu'
      end

      def namespace_config
        sns = ''
        config[:namespaces].each_key do |ns|
          sns = config[:namespaces][ns] if ns.to_s.eql?(namespace.to_s)
        end
        @namespace_config ||= sns
      end

      def template(name, &block)
        prefix = "#{namespace}/#{name}"
        pangea_home = %(#{Dir.home}/.pangea/#{namespace})
        local_cache = File.join(pangea_home, prefix)
        `mkdir -p #{local_cache}` unless Dir.exist?(local_cache)
        synthesizer.synthesize(&block)
        sns = namespace_config
        unless synthesizer.synthesis[:terraform]
          synthesizer.synthesize do
            terraform do
              backend(
                s3: {
                  key: prefix,
                  dynamodb_table: sns[:state][:config][:lock].to_s,
                  bucket: sns[:state][:config][:bucket].to_s,
                  region: sns[:state][:config][:region].to_s,
                  encrypt: true
                }
              )
            end
          end
        end
        File.write(
          File.join(
            local_cache, 'main.tf.json'
          ), JSON[synthesizer.synthesis]
        )

        system("cd #{local_cache} && #{bin} init -input=false") unless File.exist?(
          File.join(
            local_cache,
            '.terraform.lock.hcl'
          )
        )

        system("cd #{local_cache} && #{bin} apply -auto-approve") if @action.to_s.eql?('apply')
        system("cd #{local_cache} && #{bin} plan") if @action.to_s.eql?('plan')
        system("cd #{local_cache} && #{bin} destroy -auto-approve") if @action.to_s.eql?('destroy')

        template = Pangea::Utils.symbolize(
          JSON[File.read(
            File.join(local_cache, 'main.tf.json')
          )]
        )
        puts JSON.pretty_generate(template) if @action.to_s.eql?('show')
        { template: template }
      end
    end
  end
end
