# Example: Robotics and Specialized Services Infrastructure
# This demonstrates usage of AWS RoboMaker, Clean Rooms, Supply Chain,
# Private 5G, and Verified Permissions resources

template :robotics_development_platform do
  provider :aws do
    region "us-east-1"
  end

  # Create robot application for development
  robot_app = aws_robomaker_robot_application(:myrobot_app, {
    name: "MyRobot-Application",
    sources: [{
      s3_bucket: "my-robotics-bucket",
      s3_key: "robot-app.tar.gz",
      architecture: "X86_64"
    }],
    tags: {
      Environment: "development",
      Team: "robotics"
    }
  })

  # Create simulation application
  sim_app = aws_robomaker_simulation_application(:myrobot_sim, {
    name: "MyRobot-Simulation",
    simulation_software_suite: {
      name: "Gazebo",
      version: "9"
    },
    robot_software_suite: {
      name: "ROS",
      version: "Melodic"
    },
    sources: [{
      s3_bucket: "my-robotics-bucket",
      s3_key: "simulation-app.tar.gz",
      architecture: "X86_64"
    }],
    tags: {
      Environment: "development",
      Team: "robotics"
    }
  })

  # Create fleet for robot management
  robot_fleet = aws_robomaker_fleet(:production_fleet, {
    name: "production-robot-fleet",
    tags: {
      Environment: "production",
      Team: "operations"
    }
  })

  output :robot_application_arn do
    value robot_app.arn
  end

  output :simulation_application_arn do
    value sim_app.arn
  end

  output :fleet_arn do
    value robot_fleet.arn
  end
end

template :data_collaboration_platform do
  provider :aws do
    region "us-east-1"
  end

  # Create Clean Rooms collaboration for privacy-preserving analytics
  collaboration = aws_cleanrooms_collaboration(:marketing_analysis, {
    name: "marketing-data-collaboration",
    description: "Privacy-preserving marketing data analysis",
    creator_member_abilities: ["CAN_QUERY", "CAN_RECEIVE_RESULTS"],
    query_log_status: "ENABLED",
    members: [{
      account_id: "123456789012",
      display_name: "Partner Company",
      member_abilities: ["CAN_QUERY"]
    }],
    tags: {
      Department: "marketing",
      DataType: "customer-analytics"
    }
  })

  # Create configured table for the collaboration
  configured_table = aws_cleanrooms_configured_table(:customer_data, {
    name: "customer-purchase-data",
    description: "Customer purchase history for analysis",
    table_reference: {
      glue: {
        table_name: "customer_purchases",
        database_name: "marketing_data"
      }
    },
    allowed_columns: ["customer_id", "purchase_date", "amount", "category"],
    analysis_method: "DIRECT_QUERY",
    tags: {
      DataClassification: "confidential"
    }
  })

  output :collaboration_arn do
    value collaboration.arn
  end

  output :configured_table_arn do
    value configured_table.arn
  end
end

template :supply_chain_optimization do
  provider :aws do
    region "us-east-1"
  end

  # Create Supply Chain instance
  supply_chain = aws_supplychain_instance(:main_supply_chain, {
    instance_name: "main-supply-chain",
    instance_description: "Main supply chain optimization platform",
    tags: {
      Department: "logistics",
      Environment: "production"
    }
  })

  # Create data lake dataset for supply chain data
  supply_data = aws_supplychain_data_lake_dataset(:inventory_dataset, {
    name: "inventory-levels",
    namespace: "supply-chain",
    description: "Real-time inventory level data",
    instance_id: supply_chain.id,
    schema: {
      name: "InventorySchema",
      fields: [
        { name: "item_id", type: "string" },
        { name: "quantity", type: "integer" },
        { name: "location", type: "string" },
        { name: "last_updated", type: "timestamp" }
      ]
    }
  })

  # Create data integration flow
  data_flow = aws_supplychain_data_integration_flow(:inventory_flow, {
    name: "inventory-data-flow",
    instance_id: supply_chain.id,
    sources: [{
      source_type: "S3",
      source_name: "inventory-raw-data",
      s3_source: {
        bucket_name: "supply-chain-raw-data",
        prefix: "inventory/"
      }
    }],
    transformation: {
      transformation_type: "SQL",
      sql_transformation: {
        query: "SELECT item_id, quantity, location, CURRENT_TIMESTAMP as last_updated FROM inventory_raw"
      }
    },
    target: {
      target_type: "DATASET",
      dataset_target: {
        dataset_name: "inventory-levels"
      }
    }
  })

  output :supply_chain_arn do
    value supply_chain.arn
  end

  output :supply_chain_web_app do
    value supply_chain.web_app_dns_domain
  end
end

template :private_5g_network do
  provider :aws do
    region "us-west-2"  # Private 5G availability varies by region
  end

  # Create private 5G network
  private_network = aws_private5g_network(:factory_network, {
    network_name: "factory-5g-network",
    description: "Private 5G network for manufacturing facility",
    tags: {
      Location: "manufacturing-plant-1",
      Department: "operations"
    }
  })

  # Create network site
  network_site = aws_private5g_network_site(:factory_site, {
    network_arn: private_network.arn,
    network_site_name: "factory-site-1",
    description: "Main manufacturing floor network site",
    availability_zone: "us-west-2a"
  })

  # Create device identifier for IoT devices
  device_id = aws_private5g_device_identifier(:sensor_device, {
    network_arn: private_network.arn,
    imsi: "123456789012345",
    iccid: "12345678901234567890",
    order_arn: "arn:aws:private5g:us-west-2:123456789012:order/example-order"
  })

  output :private_network_arn do
    value private_network.arn
  end

  output :network_site_arn do
    value network_site.arn
  end
end

template :fine_grained_authorization do
  provider :aws do
    region "us-east-1"
  end

  # Create policy store for fine-grained permissions
  policy_store = aws_verifiedpermissions_policy_store(:app_permissions, {
    validation_settings: {
      mode: "STRICT"
    },
    description: "Application-level fine-grained permissions"
  })

  # Create schema for the authorization model
  auth_schema = aws_verifiedpermissions_schema(:app_schema, {
    policy_store_id: policy_store.policy_store_id,
    definition: {
      cedarJson: JSON.generate({
        "MyApp": {
          "entityTypes": {
            "User": {
              "shape": {
                "type": "Record",
                "attributes": {
                  "department": { "type": "String" },
                  "role": { "type": "String" }
                }
              }
            },
            "Document": {
              "shape": {
                "type": "Record", 
                "attributes": {
                  "owner": { "type": "String" },
                  "confidential": { "type": "Boolean" }
                }
              }
            }
          },
          "actions": {
            "ViewDocument": {},
            "EditDocument": {},
            "DeleteDocument": {}
          }
        }
      })
    }
  })

  # Create authorization policy
  view_policy = aws_verifiedpermissions_policy(:document_view_policy, {
    policy_store_id: policy_store.policy_store_id,
    definition: {
      static: {
        statement: 'permit(principal, action == Action::"ViewDocument", resource) when { principal.department == "engineering" };'
      }
    }
  })

  # Create policy template for reusable authorization patterns
  owner_template = aws_verifiedpermissions_policy_template(:owner_permissions, {
    policy_store_id: policy_store.policy_store_id,
    description: "Template for resource owner permissions",
    statement: 'permit(principal == ?principal, action, resource) when { resource.owner == ?principal };'
  })

  output :policy_store_id do
    value policy_store.policy_store_id
  end

  output :policy_store_arn do
    value policy_store.arn
  end
end