# AWS Application Integration Resources

This document provides an overview of all AWS Application Integration resources implemented in Pangea, focusing on GraphQL APIs, email delivery, message brokers, and application integration patterns.

## Resource Overview

### AppSync Resources (GraphQL APIs)
- **aws_appsync_graphql_api** - GraphQL API with multiple authentication methods
- **aws_appsync_datasource** - Data sources connecting APIs to backends
- **aws_appsync_resolver** - Field resolvers with VTL and JavaScript support

### SES Resources (Email Services)
- **aws_ses_domain_identity** - Domain verification for email sending
- **aws_ses_email_identity** - Individual email address verification
- **aws_ses_configuration_set** - Email sending configuration and tracking

### MQ Resources (Message Brokers)
- **aws_mq_broker** - ActiveMQ and RabbitMQ message brokers
- **aws_mq_configuration** - Broker configuration management

## Complete Application Integration Example

```ruby
template :application_integration_stack do
  provider :aws do
    region "us-east-1"
  end

  # GraphQL API with multiple data sources
  api = aws_appsync_graphql_api(:main_api, {
    name: "ApplicationAPI",
    authentication_type: "API_KEY",
    additional_authentication_providers: [
      {
        authentication_type: "AMAZON_COGNITO_USER_POOLS",
        user_pool_config: {
          user_pool_id: cognito_pool.id,
          aws_region: "us-east-1"
        }
      }
    ],
    xray_enabled: true,
    schema: <<-GRAPHQL
      type Query {
        getUser(id: ID!): User
        searchPosts(query: String!): [Post!]!
        getMessages(channelId: ID!): [Message!]!
      }
      
      type Mutation {
        createUser(input: CreateUserInput!): User
        sendEmail(input: EmailInput!): EmailResponse
        publishMessage(input: MessageInput!): Message
      }
      
      type Subscription {
        onMessageAdded(channelId: ID!): Message
          @aws_subscribe(mutations: ["publishMessage"])
      }
      
      type User {
        id: ID!
        name: String!
        email: String!
        posts: [Post!]!
      }
      
      type Post {
        id: ID!
        title: String!
        content: String!
        author: User!
      }
      
      type Message {
        id: ID!
        content: String!
        channelId: ID!
        userId: ID!
        timestamp: AWSDateTime!
      }
      
      input CreateUserInput {
        name: String!
        email: String!
      }
      
      input EmailInput {
        to: String!
        subject: String!
        body: String!
      }
      
      input MessageInput {
        content: String!
        channelId: ID!
      }
      
      type EmailResponse {
        messageId: String!
        status: String!
      }
      
      schema {
        query: Query
        mutation: Mutation
        subscription: Subscription
      }
    GRAPHQL
  })

  # DynamoDB data source for user data
  user_datasource = aws_appsync_datasource(:users_ds, {
    api_id: api.id,
    name: "UsersDataSource",
    type: "AMAZON_DYNAMODB",
    dynamodb_config: {
      table_name: users_table.name,
      region: "us-east-1"
    },
    service_role_arn: appsync_dynamodb_role.arn
  })

  # Lambda data source for email sending
  email_datasource = aws_appsync_datasource(:email_ds, {
    api_id: api.id,
    name: "EmailDataSource", 
    type: "AWS_LAMBDA",
    lambda_config: {
      function_arn: email_lambda.arn
    },
    service_role_arn: appsync_lambda_role.arn
  })

  # Message queue data source
  mq_datasource = aws_appsync_datasource(:mq_ds, {
    api_id: api.id,
    name: "MessageQueueDataSource",
    type: "HTTP",
    http_config: {
      endpoint: "https://#{message_broker.endpoints.0}",
      authorization_config: {
        authorization_type: "AWS_IAM"
      }
    }
  })

  # User query resolver
  user_resolver = aws_appsync_resolver(:get_user, {
    api_id: api.id,
    type: "Query",
    field: "getUser",
    data_source: user_datasource.name,
    request_template: <<-VTL
      {
        "version": "2018-05-29",
        "operation": "GetItem",
        "key": {
          "id": $util.dynamodb.toDynamoDBJson($ctx.args.id)
        }
      }
    VTL,
    response_template: "$util.toJson($ctx.result)"
  })

  # Email mutation resolver
  email_resolver = aws_appsync_resolver(:send_email, {
    api_id: api.id,
    type: "Mutation",
    field: "sendEmail",
    data_source: email_datasource.name,
    request_template: <<-VTL
      {
        "version": "2018-05-29",
        "operation": "Invoke",
        "payload": {
          "field": "sendEmail",
          "arguments": $util.toJson($ctx.args),
          "identity": $util.toJson($ctx.identity)
        }
      }
    VTL,
    response_template: "$util.toJson($ctx.result)"
  })

  # Message publication resolver
  message_resolver = aws_appsync_resolver(:publish_message, {
    api_id: api.id,
    type: "Mutation",
    field: "publishMessage",
    data_source: mq_datasource.name,
    runtime: {
      name: "APPSYNC_JS",
      runtime_version: "1.0.0"
    },
    code: <<-JS
      import { util } from '@aws-appsync/utils';
      
      export function request(ctx) {
        const { content, channelId } = ctx.args.input;
        const userId = ctx.identity.sub;
        
        const message = {
          id: util.autoId(),
          content,
          channelId,
          userId,
          timestamp: util.time.nowISO8601()
        };
        
        return {
          method: 'POST',
          resourcePath: '/channels/' + channelId + '/messages',
          params: {
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify(message)
          }
        };
      }
      
      export function response(ctx) {
        if (ctx.error) {
          util.error(ctx.error.message, ctx.error.type);
        }
        
        return JSON.parse(ctx.result.body);
      }
    JS
  })

  # SES domain identity for email sending
  domain_identity = aws_ses_domain_identity(:company_domain, {
    domain: "company.com"
  })

  # SES configuration set for tracking
  email_config_set = aws_ses_configuration_set(:main_config, {
    name: "main-email-config",
    delivery_options: {
      tls_policy: "Require"
    },
    reputation_metrics_enabled: true
  })

  # Message broker for real-time messaging
  message_broker = aws_mq_broker(:message_queue, {
    broker_name: "app-message-broker",
    engine_type: "RabbitMQ",
    engine_version: "3.11.20",
    host_instance_type: "mq.t3.micro",
    users: [
      {
        username: "app-user",
        password: "SecurePassword123!",
        console_access: false
      }
    ],
    subnet_ids: [private_subnet.id],
    security_groups: [mq_security_group.id]
  })

  # MQ configuration for message routing
  mq_config = aws_mq_configuration(:routing_config, {
    name: "message-routing-config",
    engine_type: "RabbitMQ",
    engine_version: "3.11.20",
    data: <<-CONFIG
      [
        {
          "name": "channels.direct",
          "vhost": "/",
          "type": "direct",
          "durable": true,
          "auto_delete": false,
          "internal": false,
          "arguments": {}
        },
        {
          "name": "messages.queue",
          "vhost": "/",
          "type": "queue",
          "durable": true,
          "auto_delete": false,
          "arguments": {
            "x-message-ttl": 3600000
          }
        }
      ]
    CONFIG
  })

  # Output API endpoint and connection details
  output :api_endpoint do
    value api.uris["GRAPHQL"]
    description "GraphQL API endpoint"
  end

  output :api_key do
    value api_key.key  # Assuming API key resource exists
    description "API key for GraphQL access"
    sensitive true
  end

  output :broker_console do
    value message_broker.console_url
    description "Message broker management console"
  end

  output :domain_verification_token do
    value domain_identity.verification_token
    description "DNS verification token for SES domain"
  end
end
```

## Integration Patterns

### 1. Event-Driven Architecture
Combine AppSync subscriptions with MQ brokers for real-time event processing:

```ruby
# Real-time notifications via GraphQL subscriptions
subscription_resolver = aws_appsync_resolver(:notifications, {
  api_id: api.id,
  type: "Subscription", 
  field: "onNotification",
  data_source: none_datasource.name,
  request_template: <<-VTL
    {
      "version": "2018-05-29",
      "payload": {
        "userId": $util.toJson($ctx.identity.sub)
      }
    }
  VTL
})
```

### 2. Microservices Communication
Use HTTP data sources to connect GraphQL to microservices:

```ruby
microservice_datasource = aws_appsync_datasource(:user_service, {
  api_id: api.id,
  name: "UserMicroservice",
  type: "HTTP",
  http_config: {
    endpoint: "https://user-service.internal.com",
    authorization_config: {
      authorization_type: "AWS_IAM"
    }
  }
})
```

### 3. Email Integration Workflows
Combine GraphQL mutations with SES for email workflows:

```ruby
# Lambda function that uses SES configuration set
email_lambda = aws_lambda_function(:email_sender, {
  function_name: "graphql-email-sender",
  runtime: "python3.11",
  handler: "index.handler",
  code: <<-PYTHON
import boto3
import json

ses = boto3.client('ses')

def handler(event, context):
    email_args = event['arguments']
    
    response = ses.send_email(
        Source='noreply@company.com',
        Destination={'ToAddresses': [email_args['to']]},
        Message={
            'Subject': {'Data': email_args['subject']},
            'Body': {'Text': {'Data': email_args['body']}}
        },
        ConfigurationSetName='main-email-config'
    )
    
    return {
        'messageId': response['MessageId'],
        'status': 'SENT'
    }
  PYTHON,
  role: lambda_role.arn
})
```

## Security Best Practices

### 1. API Authentication
Use multiple authentication providers for different access patterns:
- API_KEY for public/development access
- AMAZON_COGNITO_USER_POOLS for user authentication  
- AWS_IAM for service-to-service communication

### 2. Data Source Security
Implement least-privilege IAM roles for each data source:
- DynamoDB roles with table-specific permissions
- Lambda roles with minimal function access
- HTTP data sources with signed requests

### 3. Network Security
Deploy brokers in private subnets with appropriate security groups:
- Restrict MQ access to application subnets only
- Use VPC endpoints for AWS services
- Enable encryption in transit and at rest

## Monitoring and Observability

### 1. X-Ray Tracing
Enable distributed tracing across all components:
```ruby
api = aws_appsync_graphql_api(:traced_api, {
  name: "TracedAPI",
  authentication_type: "API_KEY",
  xray_enabled: true
})
```

### 2. CloudWatch Logging
Configure comprehensive logging:
```ruby
api = aws_appsync_graphql_api(:logged_api, {
  name: "LoggedAPI",
  authentication_type: "API_KEY",
  log_config: {
    cloudwatch_logs_role_arn: logging_role.arn,
    field_log_level: "ALL"
  }
})
```

### 3. Message Broker Monitoring
Enable broker logging and monitoring:
```ruby
broker = aws_mq_broker(:monitored_broker, {
  broker_name: "monitored-broker",
  engine_type: "RabbitMQ",
  logs: {
    general: true,
    audit: true
  }
})
```

This comprehensive application integration stack provides real-time GraphQL APIs, reliable message queuing, and professional email delivery - essential components for modern application architectures.