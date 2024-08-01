module Shell
  module Terraform
    BIN = ENV[%(TERRAFORM_BIN)] || %(terraform).freeze

    class << self
      def run(terraform_cmd)
        cmd = []
        # cmd << %(cd)
        # cmd << Dir.pwd
        # cmd << %(&&)
        cmd << BIN
        cmd << terraform_cmd
        system cmd.join(%( ))
      end

      def plan
        run(%(plan))
      end
    end
  end
end
