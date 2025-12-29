# frozen_string_literal: true

module Pangea
  module CLI
    module Commands
      module Agent
        # Security scanning
        module Security
          def security_scan(file, template: nil, namespace: nil)
            return { error: 'File required' } unless file

            compiler = Compilation::TemplateCompiler.new
            templates = compiler.extract_templates(file)

            security_issues = []

            templates.each do |t|
              content = t[:content]
              security_issues.concat(scan_template_security(t[:name], content))
            end

            {
              issues_found: security_issues.count,
              issues: security_issues,
              summary: {
                high: security_issues.count { |i| i[:severity] == 'high' },
                medium: security_issues.count { |i| i[:severity] == 'medium' },
                low: security_issues.count { |i| i[:severity] == 'low' }
              }
            }
          end

          private

          def scan_template_security(template_name, content)
            issues = []

            if content.match(/ingress.*from_port\s*[=:]\s*0.*to_port\s*[=:]\s*65535/m)
              issues << {
                template: template_name,
                severity: 'high',
                issue: 'Security group allows all ports',
                recommendation: 'Restrict to specific required ports'
              }
            end

            if content.match(/cidr_blocks\s*[=:]\s*\[?\s*["']0\.0\.0\.0\/0/)
              issues << {
                template: template_name,
                severity: 'medium',
                issue: 'Security group allows traffic from anywhere',
                recommendation: 'Restrict to known IP ranges'
              }
            end

            if content.include?('aws_s3_bucket') && !content.include?('encryption')
              issues << {
                template: template_name,
                severity: 'medium',
                issue: 'S3 bucket without encryption',
                recommendation: 'Enable server-side encryption'
              }
            end

            issues
          end
        end
      end
    end
  end
end
