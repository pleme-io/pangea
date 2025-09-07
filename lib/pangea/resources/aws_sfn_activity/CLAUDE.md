# AWS Step Functions Activity Implementation

## Overview

This implementation provides a type-safe interface for AWS Step Functions activities, enabling worker-based task execution patterns with proper validation and naming conventions.

## Architecture

### Type System
- **SfnActivityAttributes**: Main dry-struct with activity name validation
- **Name Validators**: AWS naming requirement enforcement
- **Pattern Generators**: Pre-built naming patterns for common scenarios
- **Integration Helpers**: Methods for state machine integration

### Validation Layers

1. **Name Format Validation**: Ensures AWS naming requirements
2. **Length Validation**: 1-80 character limit enforcement
3. **Character Validation**: Alphanumeric, hyphens, underscores only
4. **Pattern Validation**: No leading/trailing hyphens

## Activity Naming System

### AWS Requirements
- **Length**: 1-80 characters maximum
- **Characters**: `[a-zA-Z0-9\-_]` only
- **Constraints**: Cannot start or end with hyphen
- **Case**: Case-sensitive but lowercase recommended

### Validation Implementation
```ruby
def self.validate_activity_name(name)
  # Length check
  if name.length < 1 || name.length > 80
    raise Dry::Struct::Error, "Activity name must be between 1 and 80 characters"
  end
  
  # Character validation
  unless name.match?(/^[a-zA-Z0-9\-_]+$/)
    raise Dry::Struct::Error, "Activity name can only contain letters, numbers, hyphens, and underscores"
  end
  
  # Hyphen constraints
  if name.start_with?('-') || name.end_with?('-')
    raise Dry::Struct::Error, "Activity name cannot start or end with a hyphen"
  end
  
  true
end
```

## Naming Pattern System

### Pre-built Patterns
```ruby
def self.activity_name_patterns
  {
    data_processing: "data-processing-activity",
    file_processing: "file-processing-activity", 
    image_processing: "image-processing-activity",
    email_sending: "email-sending-activity",
    report_generation: "report-generation-activity",
    data_validation: "data-validation-activity",
    backup_task: "backup-task-activity",
    cleanup_task: "cleanup-task-activity",
    monitoring_check: "monitoring-check-activity",
    health_check: "health-check-activity",
    batch_job: "batch-job-activity",
    etl_process: "etl-process-activity",
    ml_training: "ml-training-activity",
    ml_inference: "ml-inference-activity",
    api_integration: "api-integration-activity"
  }
end
```

### Dynamic Pattern Generators

**Worker Activities**:
```ruby
def self.worker_activity(worker_type, environment = nil)
  base_name = "#{worker_type}-worker-activity"
  environment ? "#{base_name}-#{environment}" : base_name
end

# Examples:
worker_activity("data", "prod")     # "data-worker-activity-prod"
worker_activity("ml")               # "ml-worker-activity"
```

**Batch Activities**:
```ruby
def self.batch_activity(batch_type)
  "#{batch_type}-batch-activity"
end

# Examples:
batch_activity("etl")               # "etl-batch-activity"
batch_activity("image-resize")      # "image-resize-batch-activity"
```

**Integration Activities**:
```ruby
def self.integration_activity(service_name, action)
  "#{service_name}-#{action}-activity"
end

# Examples:
integration_activity("s3", "upload")       # "s3-upload-activity"
integration_activity("dynamodb", "query")  # "dynamodb-query-activity"
```

## Worker Integration Patterns

### Basic Activity Task Loop

```ruby
# State machine definition using activity
{
  Type: "Task",
  Resource: "arn:aws:states:us-east-1:123456789012:activity:my-activity",
  TimeoutSeconds: 300,
  HeartbeatSeconds: 60,
  End: true
}
```

**Corresponding Worker Implementation**:
```python
import boto3
import json
import threading
import time

class ActivityWorker:
    def __init__(self, activity_arn, worker_name):
        self.activity_arn = activity_arn
        self.worker_name = worker_name
        self.client = boto3.client('stepfunctions')
        self.running = True
        
    def start(self):
        while self.running:
            try:
                # Poll for task
                response = self.client.get_activity_task(
                    activityArn=self.activity_arn,
                    workerName=self.worker_name
                )
                
                if 'taskToken' in response:
                    self.process_task(response)
                    
            except Exception as e:
                print(f"Worker error: {e}")
                time.sleep(5)  # Brief pause before retry
                
    def process_task(self, task):
        task_token = task['taskToken']
        input_data = json.loads(task['input'])
        
        # Start heartbeat for long-running tasks
        heartbeat_stop = threading.Event()
        heartbeat_thread = threading.Thread(
            target=self.send_heartbeats,
            args=(task_token, heartbeat_stop)
        )
        heartbeat_thread.start()
        
        try:
            # Process the task
            result = self.do_work(input_data)
            
            # Stop heartbeat and send success
            heartbeat_stop.set()
            heartbeat_thread.join()
            
            self.client.send_task_success(
                taskToken=task_token,
                output=json.dumps(result)
            )
            
        except Exception as e:
            # Stop heartbeat and send failure
            heartbeat_stop.set()
            heartbeat_thread.join()
            
            self.client.send_task_failure(
                taskToken=task_token,
                error=type(e).__name__,
                cause=str(e)
            )
            
    def send_heartbeats(self, task_token, stop_event):
        while not stop_event.wait(30):  # Send every 30 seconds
            try:
                self.client.send_task_heartbeat(taskToken=task_token)
            except Exception as e:
                print(f"Heartbeat error: {e}")
                break
                
    def do_work(self, input_data):
        # Implement your business logic here
        time.sleep(60)  # Simulate work
        return {"status": "completed", "processed_items": 100}
        
    def stop(self):
        self.running = False
```

### Multi-Activity Worker

```python
class MultiActivityWorker:
    def __init__(self, activities):
        """
        activities: dict of {"activity_name": "activity_arn"}
        """
        self.activities = activities
        self.client = boto3.client('stepfunctions')
        self.workers = {}
        
    def start_all(self):
        for name, arn in self.activities.items():
            worker = ActivityWorker(arn, f"{name}-worker")
            thread = threading.Thread(target=worker.start)
            thread.start()
            self.workers[name] = (worker, thread)
            
    def stop_all(self):
        for name, (worker, thread) in self.workers.items():
            worker.stop()
            thread.join()
```

## Activity Lifecycle Management

### Activity States
1. **Created**: Activity resource exists in AWS
2. **Polling**: Workers are polling for tasks
3. **Processing**: Task is being executed
4. **Completed**: Task finished successfully
5. **Failed**: Task execution failed

### Monitoring Integration

**CloudWatch Metrics**:
- `ActivitiesStarted`: Number of activity tasks started
- `ActivitiesSucceeded`: Number of successful completions
- `ActivitiesFailed`: Number of failed tasks
- `ActivitiesTimedOut`: Number of timed out tasks

**Custom Metrics in Workers**:
```python
import boto3

cloudwatch = boto3.client('cloudwatch')

def send_custom_metric(metric_name, value, unit='Count'):
    cloudwatch.put_metric_data(
        Namespace='StepFunctions/Activities',
        MetricData=[{
            'MetricName': metric_name,
            'Value': value,
            'Unit': unit,
            'Dimensions': [
                {'Name': 'ActivityName', 'Value': 'my-activity'},
                {'Name': 'WorkerName', 'Value': 'worker-1'}
            ]
        }]
    )

# Usage in worker
send_custom_metric('TaskProcessingTime', processing_time, 'Seconds')
send_custom_metric('TasksProcessed', 1)
```

## Error Handling Strategies

### Task-Level Error Handling

**In State Machine**:
```json
{
  "Type": "Task",
  "Resource": "arn:aws:states:us-east-1:123456789012:activity:processor",
  "Retry": [{
    "ErrorEquals": ["States.TaskFailed"],
    "IntervalSeconds": 5,
    "MaxAttempts": 3,
    "BackoffRate": 2.0
  }],
  "Catch": [{
    "ErrorEquals": ["ProcessingError"],
    "Next": "HandleProcessingError",
    "ResultPath": "$.error"
  }, {
    "ErrorEquals": ["States.ALL"],
    "Next": "HandleGenericError"
  }]
}
```

**In Worker**:
```python
class ProcessingError(Exception):
    pass

def process_with_error_handling(input_data):
    try:
        # Validate input
        if not validate_input(input_data):
            raise ProcessingError("Invalid input data")
            
        # Process data
        result = process_data(input_data)
        
        # Validate output
        if not validate_output(result):
            raise ProcessingError("Invalid output data")
            
        return result
        
    except ProcessingError:
        raise  # Re-raise processing errors
    except Exception as e:
        # Wrap unexpected errors
        raise ProcessingError(f"Unexpected error: {str(e)}")
```

### Worker-Level Error Handling

**Graceful Shutdown**:
```python
import signal
import sys

class GracefulWorker(ActivityWorker):
    def __init__(self, activity_arn, worker_name):
        super().__init__(activity_arn, worker_name)
        signal.signal(signal.SIGTERM, self.handle_shutdown)
        signal.signal(signal.SIGINT, self.handle_shutdown)
        
    def handle_shutdown(self, signum, frame):
        print(f"Received signal {signum}, shutting down gracefully...")
        self.running = False
        sys.exit(0)
```

**Connection Resilience**:
```python
import backoff

class ResilientWorker(ActivityWorker):
    @backoff.on_exception(
        backoff.expo,
        Exception,
        max_tries=5,
        max_time=300
    )
    def get_activity_task(self):
        return self.client.get_activity_task(
            activityArn=self.activity_arn,
            workerName=self.worker_name
        )
```

## Deployment Patterns

### Containerized Workers

**Dockerfile**:
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY worker.py .

CMD ["python", "worker.py"]
```

**ECS Task Definition**:
```ruby
aws_ecs_task_definition(:activity_worker, {
  family: "activity-worker",
  cpu: "256",
  memory: "512",
  network_mode: "awsvpc",
  requires_compatibilities: ["FARGATE"],
  execution_role_arn: execution_role.arn,
  task_role_arn: task_role.arn,
  container_definitions: [
    {
      name: "worker",
      image: "my-repo/activity-worker:latest",
      environment: [
        { name: "ACTIVITY_ARN", value: activity.arn },
        { name: "WORKER_NAME", value: "ecs-worker" }
      ],
      log_configuration: {
        log_driver: "awslogs",
        options: {
          "awslogs-group": log_group.name,
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "worker"
        }
      }
    }
  ]
})
```

### Lambda-Based Polling

**Note**: Lambda is not ideal for activity polling due to 15-minute execution limit. Use for short tasks only.

```python
import json

def lambda_handler(event, context):
    client = boto3.client('stepfunctions')
    
    # Single poll attempt
    response = client.get_activity_task(
        activityArn=event['activity_arn'],
        workerName=f"lambda-{context.aws_request_id}"
    )
    
    if 'taskToken' not in response:
        return {'statusCode': 200, 'body': 'No tasks available'}
        
    # Process quickly (must complete within 15 minutes)
    task_token = response['taskToken']
    input_data = json.loads(response['input'])
    
    try:
        result = quick_process(input_data)
        
        client.send_task_success(
            taskToken=task_token,
            output=json.dumps(result)
        )
        
        return {'statusCode': 200, 'body': 'Task completed'}
        
    except Exception as e:
        client.send_task_failure(
            taskToken=task_token,
            error=type(e).__name__,
            cause=str(e)
        )
        
        return {'statusCode': 500, 'body': 'Task failed'}
```

## Performance Considerations

### Polling Strategy
- **Frequency**: Balance between responsiveness and cost
- **Parallel Workers**: Multiple workers can poll same activity
- **Regional Distribution**: Deploy workers in multiple regions if needed

### Task Distribution
- **Load Balancing**: Step Functions automatically distributes tasks
- **Worker Identification**: Use unique worker names for monitoring
- **Scaling**: Scale workers based on activity metrics

### Resource Optimization
- **Worker Sizing**: Right-size workers for expected task duration
- **Connection Pooling**: Reuse AWS SDK connections
- **Batch Processing**: Process multiple items per task when possible

## Security Considerations

### IAM Permissions

**Activity Execution Role** (for State Machine):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "states:SendTaskSuccess",
      "states:SendTaskFailure",
      "states:SendTaskHeartbeat"
    ],
    "Resource": "*"
  }]
}
```

**Worker Role**:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "states:GetActivityTask",
      "states:SendTaskSuccess",
      "states:SendTaskFailure", 
      "states:SendTaskHeartbeat"
    ],
    "Resource": "arn:aws:states:*:*:activity:*"
  }]
}
```

### Network Security
- **VPC**: Deploy workers in private subnets
- **Security Groups**: Restrict outbound access to required services
- **Endpoints**: Use VPC endpoints for Step Functions if needed

## Monitoring and Observability

### CloudWatch Integration
```python
import logging
import boto3
from pythonjsonlogger import jsonlogger

# Structured logging setup
logger = logging.getLogger()
handler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.INFO)

class ObservableWorker(ActivityWorker):
    def process_task(self, task):
        task_token = task['taskToken']
        start_time = time.time()
        
        logger.info("task_started", extra={
            "task_token": task_token[:10],  # Partial token for privacy
            "activity_arn": self.activity_arn,
            "worker_name": self.worker_name
        })
        
        try:
            result = super().process_task(task)
            
            logger.info("task_completed", extra={
                "task_token": task_token[:10],
                "duration": time.time() - start_time,
                "status": "success"
            })
            
        except Exception as e:
            logger.error("task_failed", extra={
                "task_token": task_token[:10],
                "duration": time.time() - start_time,
                "error": str(e),
                "status": "failed"
            })
            raise
```

### Custom Dashboards
Create CloudWatch dashboards to monitor:
- Task completion rates
- Average processing time
- Error rates by error type
- Worker health and availability
- Activity task queue depth