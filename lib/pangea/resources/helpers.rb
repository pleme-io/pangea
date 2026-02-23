# frozen_string_literal: true

module Pangea
  module Resources
    # Helper functions available in template context
    module Helpers
      def ref(resource_type, resource_name, attribute)
        "${#{resource_type}.#{resource_name}.#{attribute}}"
      end

      def data_ref(data_type, data_name, attribute)
        "${data.#{data_type}.#{data_name}.#{attribute}}"
      end

      def var(var_name)
        "${var.#{var_name}}"
      end

      def local(local_name)
        "${local.#{local_name}}"
      end
    end
  end
end
