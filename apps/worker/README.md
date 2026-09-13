# OrderFlow Worker

The standalone SQS process is introduced in Week 11. The current local MVP performs the same validated, idempotent transition inside the API process and labels emitted transition events with the `order-worker` source.

The later worker will consume the versioned event contract, apply bounded retries, persist state transitions, and route exhausted messages to a dead-letter queue. Keeping this boundary explicit prevents the local MVP from pretending that AWS event delivery has already been implemented.
