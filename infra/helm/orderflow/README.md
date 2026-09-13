# OrderFlow Helm chart

Local labs may use tags. Any cloud lab must set global.requireDigest=true and
provide both API and worker sha256 digests. The chart uses non-root containers,
a read-only root filesystem, explicit resources, liveness/readiness probes,
deny-by-default Kubernetes RBAC, optional existing Secret references, a
namespace-scoped API NetworkPolicy, disruption budgets, and optional API HPA.

The NetworkPolicy requires a network-policy-capable CNI. Workload AWS access
must be supplied by a reviewed workload identity annotation; never place AWS
keys in values files or Kubernetes Secret manifests.
