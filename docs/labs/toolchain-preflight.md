# Toolchain Preflight

- Observed: 13 September 2026
- Scope: Ubuntu WSL 2 inventory and user-local tool installation
- Installation changes: checksum-verified binaries under the WSL user's `.local` directories; no `sudo`

## Confirmed

| Tool | Observed version | State |
| --- | --- | --- |
| Ubuntu WSL | WSL 2, running | Ready |
| Git | 2.53.0 | Ready |
| Python | 3.14.4 | Ready; project CI will also define its supported Python versions |
| AWS CLI | 2.31.35 | Ready; personal login is not yet configured |
| Docker | 29.7.2 client and engine | Ready |
| Terraform | 1.16.1 | Ready; 1.16.2 update is available but not required for the first lab |

## Completed WSL additions

| Tool | Observed version | State |
| --- | --- | --- |
| Node.js | 24.21.0 LTS | Ready; user-local, checksum verified |
| npm | 11.19.0 | Ready; delivered with the Linux Node.js installation |
| `kubectl` | 1.37.0 | Ready; user-local, checksum verified |
| `eksctl` | 0.230.0 | Ready; user-local, checksum verified |
| Helm | 4.3.0 | Ready; user-local, checksum verified |
| GitHub CLI | 2.100.0 | Ready; user-local, checksum verified; authentication still pending |

The repeatable installer is `scripts/install-wsl-tools.sh`. It uses official release endpoints, verifies every downloaded binary against its published SHA-256 value, writes only beneath the WSL user's `.local` directories, and requires no `sudo`.

## Boundary notes

- This inventory does not authenticate AWS and proves no AWS account identity.
- No corporate AWS credentials will be copied into WSL.
- Installations used official distribution or vendor sources with TLS and SHA-256 verification.
