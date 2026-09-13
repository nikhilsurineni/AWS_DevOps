# Security Policy

OrderFlow processes synthetic learning data only. Do not submit credentials, tokens, account identifiers, internal URLs, enterprise screenshots, personal data, payment data, or private infrastructure metadata in issues, logs, examples, or pull requests.

## Reporting

Do not open a public issue for a suspected credential exposure or exploitable vulnerability. Use GitHub's private vulnerability reporting feature after it is enabled for the repository.

## Supported versions

Only the latest release on main is supported during the learning project.

## Response

If secret material is exposed:

1. revoke or rotate it at the authoritative provider;
2. stop affected workloads;
3. preserve a sanitized incident timeline;
4. remove the material from the current tree and repository history as needed;
5. rerun the secret scan before resuming deployment.
