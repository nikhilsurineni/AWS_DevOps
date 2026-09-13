# Week 01 — Account and Cost Safety

- Date started: 13 September 2026
- Environment: personal-learning
- Region: `us-east-1`
- Objective: establish identity, plan, budget, and cost evidence before provisioning.
- Expected resources: no application resources.
- Teardown deadline: not applicable.

## Confirmed

- The AWS Console is signed in and the selected Region is US East (N. Virginia).
- The Console identifies the account as a credit-backed Free Plan.
- The console reports that the Free Plan expires on 18 December 2026. The project still targets an earlier personal-account exit so cleanup is not left until expiry.
- AWS Budgets is accessible.
- The monthly learning budget is USD 10 with actual-cost email alerts at 25%, 50%, 80%, and 100%.
- The saved budget and all four thresholds were re-opened and verified after the update; all thresholds were unbreached at that checkpoint.
- No automatic budget actions are attached.
- The IAM security dashboard confirms that the root user has MFA.
- The authenticated console session is a non-root IAM user.

## Partial

- The active IAM user does not have MFA. Enrollment was intentionally deferred at the learner's request on 13 September 2026.
- IAM reports access keys unused for more than one year. Their owner and dependencies must be verified before any deactivation or deletion.
- The non-root temporary-authentication path has not yet been independently verified.

## Unavailable

- Current-month and forecast detail widgets on Console Home were access-denied for the active identity.
- No claim is made that current cost is zero.

## Next checkpoint

1. Inventory the stale access keys without exposing their values, verify ownership and dependencies, then make a separate removal decision.
2. Configure an AWS CLI `aws login` temporary session for the personal account.
3. Recheck the budget after the next AWS lab and record only sanitized evidence.
