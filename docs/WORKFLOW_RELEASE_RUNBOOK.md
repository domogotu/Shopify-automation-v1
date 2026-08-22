# Controlled workflow release runbook

Repository workflow files and n8n database workflows are separate copies. A GitHub deployment does not automatically update workflows already stored in n8n while `BOOTSTRAP_WORKFLOWS=false`.

## Safety rule

This process prepares and verifies a release. It does not activate workflows and it does not automatically import them.

## 1. Confirm source safety

Run:

```sh
./scripts/validate-foundation.sh
```

The result must pass. Warnings about missing n8n credentials are expected until credential setup is complete.

## 2. Back up the current n8n workflows

Use n8n's supported CLI from the running service environment:

```sh
mkdir -p /tmp/n8n-workflow-backup
n8n export:workflow --backup --output=/tmp/n8n-workflow-backup
```

Copy the backup to durable, access-controlled storage before changing the n8n database. Do not commit the backup if it contains credential references or private workflow data.

## 3. Compare n8n with GitHub

Run:

```sh
node scripts/prepare-workflow-release.mjs --current=/tmp/n8n-workflow-backup
```

The report separates:

- unchanged workflows;
- structurally changed workflows;
- workflows missing from n8n;
- extra n8n workflows not managed by this repository.

Credential assignments, activation state, timestamps, tags, and n8n version metadata are excluded from the structural hash. This prevents environment-specific credential bindings from being mistaken for source changes.

## 4. Review the proposed release

For each changed workflow:

1. Confirm the source workflow has the intended stable ID and name.
2. Confirm `active` is not `true`.
3. Confirm credential bindings will not be erased.
4. Confirm webhook paths are unchanged or intentionally versioned.
5. Confirm sub-workflow references still resolve.
6. Confirm the rollback backup is accessible.

Do not use a bulk import merely because the comparison found changes. n8n documents that workflows with matching IDs can be overwritten.

## 5. Apply through a controlled maintenance window

Apply only after approval. Keep the global kill switch enabled and every commerce action flag false. Update one workflow at a time, starting with non-triggered validation workflows.

After each update:

1. Confirm it remains inactive.
2. Reassign required n8n credentials if needed.
3. Run a mock-only test.
4. Verify the output content, not only the green execution status.
5. Record the result and any skipped issue.

## 6. Roll back

If structure, credential bindings, webhook behavior, or tests are wrong:

1. Stop the release.
2. Keep the affected workflow inactive.
3. Restore the previous workflow from the backup.
4. Re-run the comparison and mock test.
5. Record the failure, evidence, and corrective action.

## Current expected release scope

The GitHub source currently contains changes to:

- the realtime Claude gateway environment contract;
- four PostgreSQL workflows scoped to `automation_os`.

These changes are not considered live until the n8n database copies are updated and verified.
