# Week 3: Git and GitHub

Status: **Partial** on 13 September 2026. Public publication and CI are confirmed;
branch protection and the practice pull-request exercise remain pending.

## Learning outcomes

- Explain commits, branches, remotes, pull requests, tags, and releases.
- Use Conventional Commit subjects and Semantic Versioning.
- Keep credentials, cloud identifiers, private URLs, and unsanitized evidence out of Git.
- Require automated checks before merging changes to the protected default branch.

## Confirmed local evidence

- Git repository exists on branch `main` with focused commits.
- Public remote targets `nikhilsurineni/AWS_DevOps`.
- `.gitignore` excludes credentials, local configuration, Terraform state, build output,
  runtime evidence, and dependency directories.
- `.gitattributes` normalizes platform-sensitive line endings.
- Pull-request and structured issue templates capture acceptance and rollback evidence.
- Dependabot configuration covers Python, npm, GitHub Actions, and Terraform dependencies.
- CI definitions cover backend, frontend, containers, Terraform, CloudFormation, and Helm.
- Contribution and security policies define synthetic-data and disclosure boundaries.

## Confirmed remote evidence

- The public `nikhilsurineni/AWS_DevOps` repository renders the OrderFlow source and documentation.
- Remote `main` matched local commit `ead2170` after the CI repair.
- GitHub Actions CI run 6 completed successfully for backend, frontend, and infrastructure jobs.
- The first CI run correctly exposed two lint failures; the focused repair passed the same hosted gate.
- Dependabot parsed the configuration and opened four dependency-update pull requests.

## Remote checkpoints

Complete these only after the initial public push succeeds:

1. Enable private vulnerability reporting and secret scanning where the repository plan supports them.
2. Protect `main`: require a pull request and the applicable CI status checks before merge.
3. Create a practice branch, open an issue-linked pull request, observe CI, and merge it.
4. Create the first annotated Semantic Versioning tag only after the milestone is accepted.

## Negative tests

- A deliberately failing test must fail CI and prevent merge.
- An invalid Terraform file must fail formatting or validation.
- A sample secret-shaped value must be tested only in an untracked disposable file and must
  never be committed or uploaded.

## Cleanup and rollback

- Remove unneeded practice branches after merge.
- Revert the focused governance commit if repository templates interfere with the intended workflow.
- Do not delete remote history or tags as a routine rollback.
