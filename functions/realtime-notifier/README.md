# Real-time notifier

The Lambda accepts the OrderFlow v1 envelope directly or in EventBridge
`detail`, validates it, allowlists browser fields, and performs a bounded scan
of the DynamoDB connection registry. Gone WebSocket connections are deleted;
other delivery failures raise so EventBridge can retry. Clients must deduplicate
by `event_id`.

Package only `handler.py`; boto3 is supplied by the Lambda Python runtime.
The Terraform notifier switch remains disabled until the package, exact
management endpoint, and exact execute-api ARN are provided.
