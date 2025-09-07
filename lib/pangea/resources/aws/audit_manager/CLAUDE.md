# AWS Audit Manager Resources

## Overview

AWS Audit Manager resources enable automated compliance assessment and audit readiness through continuous evidence collection, control validation, and assessment reporting. These resources help organizations maintain compliance with standards like SOC 2, PCI DSS, GDPR, and custom compliance frameworks.

## Key Concepts

### Compliance Assessment Workflow
1. **Framework Definition**: Define compliance frameworks with grouped controls
2. **Assessment Creation**: Create assessments based on frameworks
3. **Evidence Collection**: Automatic collection of compliance evidence
4. **Control Validation**: Continuous validation of control effectiveness
5. **Report Generation**: Automated compliance reporting and audit trails

### Evidence Sources
- **AWS Config**: Configuration compliance checks
- **CloudTrail**: API activity and access logging
- **Security Hub**: Security findings and compliance status
- **Manual Evidence**: User-uploaded documentation and attestations
- **Custom Sources**: API-based evidence collection

### Role-Based Assessment Management
- **Process Owners**: Responsible for control implementation and monitoring
- **Resource Owners**: Own specific AWS resources and their compliance
- **Auditors**: External or internal audit teams requiring evidence access
- **Delegated Reviewers**: Team members assigned specific control sets

## Resources

### aws_auditmanager_assessment
Primary resource for creating and managing compliance assessments.

**Key Features:**
- Framework-based assessment structure
- Multi-account scope configuration
- Automated evidence collection
- Role-based assessment management

**Common Patterns:**
```ruby
# SOC 2 Type II assessment
aws_auditmanager_assessment(:soc2_assessment, {
  name: "SOC 2 Type II Assessment 2024",
  description: "Annual SOC 2 Type II compliance assessment for production workloads",
  framework_id: aws_auditmanager_framework(:soc2_framework).id,
  roles: [
    {
      role_arn: aws_iam_role(:compliance_manager).arn,
      role_type: "PROCESS_OWNER"
    },
    {
      role_arn: aws_iam_role(:security_team).arn,
      role_type: "RESOURCE_OWNER"
    }
  ],
  scope: {
    aws_accounts: [
      {
        id: production_account_id,
        email_address: "compliance@example.com"
      },
      {
        id: security_account_id,
        email_address: "security@example.com"
      }
    ],
    aws_services: [
      { service_name: "EC2" },
      { service_name: "S3" },
      { service_name: "RDS" },
      { service_name: "CloudTrail" },
      { service_name: "Config" }
    ]
  },
  assessment_reports_destination: {
    destination: aws_s3_bucket(:audit_reports).id,
    destination_type: "S3"
  },
  tags: {
    ComplianceStandard: "SOC2",
    AssessmentYear: "2024",
    Status: "active"
  }
})

# PCI DSS assessment with specific scope
aws_auditmanager_assessment(:pci_assessment, {
  name: "PCI DSS Compliance Assessment",
  description: "Payment Card Industry Data Security Standard compliance",
  framework_id: aws_auditmanager_framework(:pci_framework).id,
  roles: [
    {
      role_arn: aws_iam_role(:pci_compliance_officer).arn,
      role_type: "PROCESS_OWNER"
    }
  ],
  scope: {
    aws_accounts: payment_processing_accounts.map do |account|
      {
        id: account[:id],
        email_address: account[:email]
      }
    end,
    aws_services: [
      { service_name: "EC2" },
      { service_name: "ELB" },
      { service_name: "RDS" },
      { service_name: "KMS" },
      { service_name: "VPC" }
    ]
  },
  assessment_reports_destination: {
    destination: aws_s3_bucket(:pci_reports).id,
    destination_type: "S3"
  },
  tags: {
    ComplianceStandard: "PCI-DSS",
    Scope: "payment-processing"
  }
})

# Custom internal assessment
aws_auditmanager_assessment(:internal_security_assessment, {
  name: "Internal Security Controls Assessment Q4",
  description: "Quarterly internal security controls validation",
  framework_id: aws_auditmanager_framework(:internal_security_framework).id,
  roles: [
    {
      role_arn: aws_iam_role(:security_manager).arn,
      role_type: "PROCESS_OWNER"
    },
    {
      role_arn: aws_iam_role(:devops_team).arn,
      role_type: "RESOURCE_OWNER"
    }
  ],
  scope: {
    aws_accounts: all_organization_accounts,
    aws_services: critical_services
  },
  status: "ACTIVE",
  tags: {
    AssessmentType: "internal",
    Frequency: "quarterly"
  }
})
```

### aws_auditmanager_framework
Defines compliance frameworks with organized control sets.

**Key Features:**
- Standard and custom framework types
- Hierarchical control organization
- Reusable across multiple assessments
- Framework sharing capabilities

**Common Patterns:**
```ruby
# SOC 2 compliance framework
aws_auditmanager_framework(:soc2_framework, {
  name: "SOC 2 Type II Framework",
  description: "Service Organization Control 2 Type II compliance framework",
  compliance_type: "SOC2",
  control_sets: [
    {
      name: "Security Controls",
      controls: [
        { id: aws_auditmanager_control(:access_control).id },
        { id: aws_auditmanager_control(:network_security).id },
        { id: aws_auditmanager_control(:encryption_at_rest).id }
      ]
    },
    {
      name: "Availability Controls", 
      controls: [
        { id: aws_auditmanager_control(:backup_procedures).id },
        { id: aws_auditmanager_control(:disaster_recovery).id },
        { id: aws_auditmanager_control(:monitoring_alerting).id }
      ]
    },
    {
      name: "Processing Integrity Controls",
      controls: [
        { id: aws_auditmanager_control(:data_validation).id },
        { id: aws_auditmanager_control(:error_handling).id }
      ]
    }
  ],
  tags: {
    Standard: "SOC2",
    Version: "2024",
    Type: "TypeII"
  }
})

# Custom internal security framework
aws_auditmanager_framework(:internal_security_framework, {
  name: "Internal Security Framework v2.0",
  description: "Company-specific security controls framework",
  compliance_type: "InternalSecurity",
  control_sets: [
    {
      name: "Infrastructure Security",
      controls: security_infrastructure_controls.map { |c| { id: c } }
    },
    {
      name: "Application Security",
      controls: application_security_controls.map { |c| { id: c } }
    },
    {
      name: "Data Protection",
      controls: data_protection_controls.map { |c| { id: c } }
    },
    {
      name: "Identity and Access Management",
      controls: iam_controls.map { |c| { id: c } }
    }
  ],
  type: "Custom",
  tags: {
    Framework: "internal",
    Version: "2.0",
    Owner: "security-team"
  }
})

# Regulatory compliance framework (GDPR)
aws_auditmanager_framework(:gdpr_framework, {
  name: "GDPR Compliance Framework",
  description: "General Data Protection Regulation compliance framework",
  compliance_type: "GDPR",
  control_sets: [
    {
      name: "Data Subject Rights",
      controls: [
        { id: aws_auditmanager_control(:data_access_rights).id },
        { id: aws_auditmanager_control(:data_portability).id },
        { id: aws_auditmanager_control(:data_erasure).id }
      ]
    },
    {
      name: "Data Protection by Design",
      controls: [
        { id: aws_auditmanager_control(:privacy_by_design).id },
        { id: aws_auditmanager_control(:data_minimization).id },
        { id: aws_auditmanager_control(:consent_management).id }
      ]
    },
    {
      name: "Data Processing Records",
      controls: [
        { id: aws_auditmanager_control(:processing_records).id },
        { id: aws_auditmanager_control(:data_inventory).id }
      ]
    }
  ],
  tags: {
    Regulation: "GDPR",
    Jurisdiction: "EU",
    Version: "current"
  }
})
```

### aws_auditmanager_control
Defines individual compliance controls with automated testing procedures.

**Key Features:**
- Multiple evidence source types
- Automated and manual testing procedures
- Configurable testing frequencies
- Detailed action plans and troubleshooting

**Common Patterns:**
```ruby
# Network security control with Config rule
aws_auditmanager_control(:network_security, {
  name: "Network Security Controls",
  description: "Ensures proper network security configurations including security groups and NACLs",
  testing_information: "Automated testing via AWS Config rules for security group and NACL configurations",
  action_plan_title: "Network Security Remediation",
  action_plan_instructions: "1. Review security group rules for overly permissive access\n2. Validate NACL configurations\n3. Ensure network segmentation is properly implemented",
  control_mapping_sources: [
    {
      source_name: "Security Group Rules Check",
      source_description: "Validates security group configurations",
      source_set_up_option: "System_Controls_Mapping",
      source_type: "AWS_Config",
      source_keyword: [
        {
          keyword_input_type: "SELECT_FROM_LIST",
          keyword_value: "ec2-security-group-attached-to-eni"
        }
      ],
      source_frequency: "DAILY",
      troubleshooting_text: "Check Config rule compliance status and remediate non-compliant security groups"
    },
    {
      source_name: "Network ACL Configuration",
      source_description: "Monitors NACL rule changes",
      source_set_up_option: "System_Controls_Mapping",
      source_type: "AWS_Cloudtrail",
      source_keyword: [
        {
          keyword_input_type: "INPUT_TEXT",
          keyword_value: "CreateNetworkAcl"
        },
        {
          keyword_input_type: "INPUT_TEXT", 
          keyword_value: "CreateNetworkAclEntry"
        }
      ],
      source_frequency: "DAILY"
    }
  ],
  tags: {
    ControlType: "security",
    Domain: "network",
    Automation: "full"
  }
})

# Data encryption control
aws_auditmanager_control(:encryption_at_rest, {
  name: "Data Encryption at Rest",
  description: "Ensures all sensitive data is encrypted at rest using appropriate encryption methods",
  testing_information: "Validates encryption settings for S3, RDS, EBS, and other data stores",
  action_plan_title: "Encryption Implementation",
  action_plan_instructions: "1. Enable encryption for all S3 buckets containing sensitive data\n2. Configure RDS encryption for all databases\n3. Enable EBS volume encryption",
  control_mapping_sources: [
    {
      source_name: "S3 Bucket Encryption",
      source_description: "Checks S3 bucket encryption configuration",
      source_set_up_option: "System_Controls_Mapping",
      source_type: "AWS_Config",
      source_keyword: [
        {
          keyword_input_type: "SELECT_FROM_LIST",
          keyword_value: "s3-bucket-server-side-encryption-enabled"
        }
      ],
      source_frequency: "DAILY"
    },
    {
      source_name: "RDS Encryption Check",
      source_description: "Validates RDS instance encryption",
      source_set_up_option: "System_Controls_Mapping",
      source_type: "AWS_Config",
      source_keyword: [
        {
          keyword_input_type: "SELECT_FROM_LIST",
          keyword_value: "rds-storage-encrypted"
        }
      ],
      source_frequency: "DAILY"
    }
  ],
  tags: {
    ControlType: "security",
    Domain: "encryption",
    Priority: "high"
  }
})

# Manual control with procedural validation
aws_auditmanager_control(:incident_response_plan, {
  name: "Incident Response Plan Documentation",
  description: "Maintains current incident response procedures and validates through regular testing",
  testing_information: "Manual review of incident response documentation and testing procedures",
  action_plan_title: "Incident Response Plan Maintenance",
  action_plan_instructions: "1. Review incident response plan quarterly\n2. Conduct tabletop exercises\n3. Update procedures based on lessons learned",
  control_mapping_sources: [
    {
      source_name: "Incident Response Documentation",
      source_description: "Manual review of incident response procedures",
      source_set_up_option: "Procedural_Controls_Mapping",
      source_type: "MANUAL",
      source_frequency: "MONTHLY",
      troubleshooting_text: "Ensure documentation is current and accessible to incident response team"
    },
    {
      source_name: "Incident Response Testing",
      source_description: "Evidence of incident response plan testing",
      source_set_up_option: "Procedural_Controls_Mapping", 
      source_type: "MANUAL",
      source_keyword: [
        {
          keyword_input_type: "UPLOAD_FILE",
          keyword_value: "incident-response-test-results"
        }
      ],
      source_frequency: "MONTHLY"
    }
  ],
  type: "Custom",
  tags: {
    ControlType: "operational",
    Domain: "incident-response",
    TestingRequired: "yes"
  }
})
```

### aws_auditmanager_assessment_report
Generates compliance reports for completed assessments.

**Key Features:**
- Automated report generation
- Comprehensive evidence compilation
- Audit-ready documentation
- Integration with assessment workflows

**Common Patterns:**
```ruby
# Final SOC 2 assessment report
aws_auditmanager_assessment_report(:soc2_final_report, {
  name: "SOC 2 Type II Final Report Q4 2024",
  assessment_id: aws_auditmanager_assessment(:soc2_assessment).id,
  description: "Final SOC 2 Type II assessment report for external audit",
  author: "compliance@example.com",
  status: "COMPLETE"
})

# Quarterly internal report
aws_auditmanager_assessment_report(:quarterly_internal_report, {
  name: "Q4 Internal Security Assessment Report",
  assessment_id: aws_auditmanager_assessment(:internal_security_assessment).id,
  description: "Quarterly internal security controls assessment summary",
  author: "security-manager@example.com"
})

# Automated report generation pattern
current_assessments.each do |assessment|
  aws_auditmanager_assessment_report(:"#{assessment[:name]}_report", {
    name: "#{assessment[:name]} - #{Time.now.strftime('%Y-%m-%d')}",
    assessment_id: assessment[:id],
    description: "Automated compliance report for #{assessment[:name]}",
    author: assessment[:primary_contact]
  })
end

# Pre-audit report for external auditors
aws_auditmanager_assessment_report(:pre_audit_report, {
  name: "Pre-Audit Evidence Package",
  assessment_id: aws_auditmanager_assessment(:soc2_assessment).id,
  description: "Comprehensive evidence package for external auditor review",
  author: "audit-coordinator@example.com",
  status: "IN_PROGRESS"
})
```

### aws_auditmanager_assessment_delegation
Manages delegation of assessment controls to specific users or roles.

**Key Features:**
- Control set delegation
- Role-based assignment
- Delegation tracking
- Comment and communication support

**Common Patterns:**
```ruby
# Delegate infrastructure controls to DevOps team
aws_auditmanager_assessment_delegation(:devops_delegation, {
  assessment_id: aws_auditmanager_assessment(:soc2_assessment).id,
  control_set_id: "infrastructure-controls",
  comment: "DevOps team responsible for infrastructure security controls validation",
  role_arn: aws_iam_role(:devops_team).arn,
  role_type: "RESOURCE_OWNER"
})

# Delegate application security to development team
aws_auditmanager_assessment_delegation(:dev_team_delegation, {
  assessment_id: aws_auditmanager_assessment(:internal_security_assessment).id,
  control_set_id: "application-security",
  comment: "Development team owns application security controls and evidence collection",
  role_arn: aws_iam_role(:development_team).arn,
  role_type: "RESOURCE_OWNER"
})

# Delegate data protection controls to data privacy officer
aws_auditmanager_assessment_delegation(:dpo_delegation, {
  assessment_id: aws_auditmanager_assessment(:gdpr_assessment).id,
  control_set_id: "data-protection-controls",
  comment: "Data Privacy Officer responsible for GDPR compliance controls",
  role_arn: aws_iam_role(:data_privacy_officer).arn,
  role_type: "PROCESS_OWNER"
})

# Bulk delegation pattern for large assessments
control_set_assignments = [
  { control_set: "network-security", team: "network_team", role_type: "RESOURCE_OWNER" },
  { control_set: "data-security", team: "data_team", role_type: "RESOURCE_OWNER" },
  { control_set: "access-management", team: "identity_team", role_type: "PROCESS_OWNER" }
]

control_set_assignments.each do |assignment|
  aws_auditmanager_assessment_delegation(:"#{assignment[:team]}_delegation", {
    assessment_id: aws_auditmanager_assessment(:comprehensive_assessment).id,
    control_set_id: assignment[:control_set],
    comment: "#{assignment[:team]} assigned responsibility for #{assignment[:control_set]}",
    role_arn: team_roles[assignment[:team]],
    role_type: assignment[:role_type]
  })
end
```

### aws_auditmanager_organization_admin_account
Designates the Audit Manager administrator account for AWS Organizations.

**Common Patterns:**
```ruby
# Designate compliance account as Audit Manager admin
aws_auditmanager_organization_admin_account(:audit_admin, {
  admin_account_id: compliance_account_id
})

# Security-focused organization setup
aws_auditmanager_organization_admin_account(:security_admin, {
  admin_account_id: security_account_id
})
```

### aws_auditmanager_account_registration
Enables Audit Manager functionality in AWS accounts.

**Common Patterns:**
```ruby
# Basic account registration
aws_auditmanager_account_registration(:enable_audit_manager, {})

# Account registration with KMS encryption
aws_auditmanager_account_registration(:secure_audit_manager, {
  kms_key: aws_kms_key(:audit_manager_key).arn
})

# Delegated admin setup
aws_auditmanager_account_registration(:delegated_setup, {
  kms_key: aws_kms_key(:audit_key).arn,
  delegated_admin_account: compliance_account_id
})
```

## Best Practices

### Framework Design
1. **Modular Control Sets**
   - Group related controls logically
   - Design for reusability across assessments
   - Maintain clear control boundaries

2. **Evidence Automation**
   - Prefer automated evidence collection
   - Use Config rules for configuration validation
   - Implement CloudTrail for activity monitoring

3. **Documentation Standards**
   - Maintain clear control descriptions
   - Provide actionable remediation steps
   - Include troubleshooting guidance

### Assessment Management
1. **Scope Definition**
   - Clearly define assessment boundaries
   - Include all relevant accounts and services
   - Document scope limitations

2. **Role Assignment**
   - Assign appropriate process and resource owners
   - Delegate control sets to subject matter experts
   - Maintain clear accountability chains

3. **Evidence Review**
   - Establish regular evidence review cycles
   - Validate automated evidence collection
   - Maintain audit trails for manual evidence

### Compliance Operations
1. **Continuous Monitoring**
   - Implement real-time compliance monitoring
   - Set up alerting for control failures
   - Regular assessment of control effectiveness

2. **Report Generation**
   - Automate report generation where possible
   - Maintain consistent reporting schedules
   - Archive reports for audit purposes

3. **Framework Evolution**
   - Regular review and update of frameworks
   - Incorporate new compliance requirements
   - Share frameworks across organization

## Integration Examples

### Complete SOC 2 Compliance Program
```ruby
# Comprehensive SOC 2 compliance implementation
template :soc2_compliance_program do
  # Account registration with encryption
  aws_auditmanager_account_registration(:soc2_registration, {
    kms_key: aws_kms_key(:audit_manager_key).arn
  })

  # Core security controls
  security_controls = [
    {
      name: "access_control",
      description: "User access management and authentication controls",
      mappings: [
        {
          source_name: "IAM Policy Compliance",
          source_type: "AWS_Config",
          keyword: "iam-policy-no-statements-with-admin-access"
        }
      ]
    },
    {
      name: "network_security", 
      description: "Network security and segmentation controls",
      mappings: [
        {
          source_name: "Security Group Compliance",
          source_type: "AWS_Config",
          keyword: "ec2-security-group-attached-to-eni"
        }
      ]
    }
  ]

  # Create controls
  control_refs = security_controls.map do |control_spec|
    aws_auditmanager_control(control_spec[:name].to_sym, {
      name: control_spec[:name].titleize,
      description: control_spec[:description],
      testing_information: "Automated testing via AWS Config and CloudTrail",
      action_plan_title: "#{control_spec[:name].titleize} Remediation",
      action_plan_instructions: "Review and remediate non-compliant resources",
      control_mapping_sources: control_spec[:mappings].map do |mapping|
        {
          source_name: mapping[:source_name],
          source_set_up_option: "System_Controls_Mapping",
          source_type: mapping[:source_type],
          source_keyword: [
            {
              keyword_input_type: "SELECT_FROM_LIST",
              keyword_value: mapping[:keyword]
            }
          ],
          source_frequency: "DAILY"
        }
      end,
      tags: {
        Framework: "SOC2",
        Automation: "enabled"
      }
    })
  end

  # SOC 2 Framework
  soc2_framework = aws_auditmanager_framework(:soc2_framework, {
    name: "SOC 2 Type II Framework v2024",
    description: "Service Organization Control 2 Type II compliance framework",
    compliance_type: "SOC2_TypeII",
    control_sets: [
      {
        name: "Security Controls",
        controls: control_refs.map { |c| { id: c.id } }
      }
    ],
    tags: {
      Standard: "SOC2",
      Type: "TypeII", 
      Version: "2024"
    }
  })

  # SOC 2 Assessment
  soc2_assessment = aws_auditmanager_assessment(:soc2_assessment, {
    name: "SOC 2 Type II Assessment 2024",
    description: "Annual SOC 2 Type II compliance assessment",
    framework_id: soc2_framework.id,
    roles: [
      {
        role_arn: aws_iam_role(:compliance_manager).arn,
        role_type: "PROCESS_OWNER"
      },
      {
        role_arn: aws_iam_role(:security_team).arn,
        role_type: "RESOURCE_OWNER"
      }
    ],
    scope: {
      aws_accounts: production_accounts.map do |account|
        {
          id: account[:id],
          email_address: account[:email]
        }
      end,
      aws_services: [
        { service_name: "EC2" },
        { service_name: "S3" },
        { service_name: "RDS" },
        { service_name: "IAM" },
        { service_name: "CloudTrail" }
      ]
    },
    assessment_reports_destination: {
      destination: aws_s3_bucket(:soc2_reports).id,
      destination_type: "S3"
    },
    tags: {
      ComplianceStandard: "SOC2",
      AssessmentYear: "2024"
    }
  })

  # Control set delegations
  delegations = [
    {
      control_set: "security-controls",
      role: aws_iam_role(:security_team).arn,
      role_type: "RESOURCE_OWNER",
      comment: "Security team owns technical security controls"
    }
  ]

  delegations.each_with_index do |delegation, index|
    aws_auditmanager_assessment_delegation(:"delegation_#{index}", {
      assessment_id: soc2_assessment.id,
      control_set_id: delegation[:control_set],
      comment: delegation[:comment],
      role_arn: delegation[:role],
      role_type: delegation[:role_type]
    })
  end

  # Assessment report
  aws_auditmanager_assessment_report(:soc2_report, {
    name: "SOC 2 Type II Assessment Report 2024",
    assessment_id: soc2_assessment.id,
    description: "Final SOC 2 Type II assessment report for external audit",
    author: "compliance@example.com"
  })
end
```

## Common Pitfalls and Solutions

### Evidence Collection Issues
**Problem**: Inconsistent or missing automated evidence
**Solution**:
- Validate Config rule deployment across all accounts
- Ensure proper IAM permissions for evidence collection
- Implement monitoring for evidence collection failures

### Assessment Scope Creep
**Problem**: Unclear or expanding assessment scope
**Solution**:
- Define clear boundaries at assessment creation
- Document scope limitations and exclusions
- Regular scope review and validation

### Control Validation Complexity
**Problem**: Complex manual control validation processes
**Solution**:
- Maximize use of automated evidence sources
- Standardize manual evidence collection procedures
- Implement review and approval workflows

### Framework Maintenance Overhead
**Problem**: Difficulty maintaining custom frameworks
**Solution**:
- Use version control for framework definitions
- Implement change management processes
- Regular framework review and updates