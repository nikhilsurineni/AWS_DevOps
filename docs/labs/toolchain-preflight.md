# Toolchain Preflight

- Observed: 13 September 2026
- Scope: read-only inventory of Ubuntu WSL 2
- Installation changes: none

## Confirmed

| Tool | Observed version | State |
| --- | --- | --- |
| Ubuntu WSL | WSL 2, running | Ready |
| Git | 2.53.0 | Ready |
| Python | 3.14.4 | Ready; project CI will also define its supported Python versions |
| AWS CLI | 2.31.35 | Ready; personal login is not yet configured |
| Docker | 29.7.2 client and engine | Ready |
| Terraform | 1.16.1 | Ready; 1.16.2 update is available but not required for the first lab |

## Needs installation or correction

| Tool | Observed state | Planned action |
| --- | --- | --- |
| Node.js | Linux executable missing | Install an LTS release inside WSL; do not rely on the Windows-mounted npm shim |
| `kubectl` | Missing | Install before the local Kubernetes phase |
| `eksctl` | Missing | Install immediately before the EKS lab and pin the version |
| Helm | Missing | Install before Helm packaging begins |
| GitHub CLI | Missing | Install before command-line repository and pull-request exercises |

## Boundary notes

- This inventory does not authenticate AWS and proves no AWS account identity.
- No corporate AWS credentials will be copied into WSL.
- Installations will be performed only from official distribution or vendor sources with TLS and version verification.
