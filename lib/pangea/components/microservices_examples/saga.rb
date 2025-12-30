# frozen_string_literal: true

# Copyright 2025 The Pangea Authors. Licensed under Apache 2.0.

module Pangea
  module Components
    module MicroservicesExamples
      # Event-driven saga orchestration example
      module Saga
        def payment_saga_example
          event_driven_microservice(:payment_saga, {
            service_name: 'payment-processor',
            event_sources: [{ type: 'EventBridge', event_pattern: { source: ['checkout.service'], 'detail-type': ['CheckoutInitiated'] } }],
            command_handler: { runtime: 'python3.9', handler: 'saga.orchestrator.handler', timeout: 300, memory_size: 1024, layers: ['arn:aws:lambda:region:account:layer:payment-sdk:1'] },
            event_store: { table_name: 'payment-saga-events', stream_enabled: true,
                           global_secondary_indexes: [{ name: 'transaction-index', hash_key: 'transaction_id', range_key: 'timestamp', projection_type: 'ALL' }] },
            saga: { enabled: true, state_machine_ref: create_payment_state_machine, compensation_enabled: true, timeout_seconds: 600 },
            event_replay: { enabled: true, snapshot_enabled: true, snapshot_frequency: 50 }
          })
        end

        private

        def create_payment_state_machine
          aws_sfn_state_machine(:payment_saga_sm, {
            name: 'payment-processing-saga',
            definition: JSON.generate(payment_saga_definition)
          })
        end

        def payment_saga_definition
          {
            Comment: 'Payment processing saga with compensation',
            StartAt: 'ValidatePayment',
            States: {
              ValidatePayment: { Type: 'Task', Resource: '${ValidatePaymentLambda.Arn}', Next: 'ChargePayment', Catch: [{ ErrorEquals: ['ValidationError'], Next: 'PaymentFailed' }] },
              ChargePayment: { Type: 'Task', Resource: '${ChargePaymentLambda.Arn}', Next: 'UpdateInventory', Catch: [{ ErrorEquals: ['PaymentError'], Next: 'CompensatePayment' }] },
              UpdateInventory: { Type: 'Task', Resource: '${UpdateInventoryLambda.Arn}', Next: 'SendConfirmation', Catch: [{ ErrorEquals: ['InventoryError'], Next: 'CompensateInventory' }] },
              SendConfirmation: { Type: 'Task', Resource: '${SendConfirmationLambda.Arn}', End: true },
              CompensateInventory: { Type: 'Task', Resource: '${ReverseInventoryLambda.Arn}', Next: 'CompensatePayment' },
              CompensatePayment: { Type: 'Task', Resource: '${RefundPaymentLambda.Arn}', Next: 'PaymentFailed' },
              PaymentFailed: { Type: 'Fail', Error: 'PaymentProcessingFailed', Cause: 'Payment saga failed and was compensated' }
            }
          }
        end
      end
    end
  end
end
