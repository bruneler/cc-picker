# Public release audit — 2026-09-24

Baseline: `abb0dff2904ff3c3971027cb2535faf3b55128f9` (`main`, version 0.3.0).
The repository was private during this review. This review does not change its
visibility or merge changes into production.

## Coverage and method

- Enumerated all GitHub-exposed branch, tag and pull-request refs and traversed
  their complete parent graph: 25 commits, 18 distinct trees, 102 unique blobs,
  45 historical file paths. This includes earlier and deleted/replaced content,
  not only the current working tree. Trees were not truncated; retrieved blob
  bytes were checked against their Git object hashes.
- Scanned historical content for private keys, common token formats, credential
  assignments and URLs, high-entropy strings, IPs/internal hostnames, personal
  local paths and email addresses. Reviewed the resulting candidates, commit
  messages/identities, workflows, deployment code and website network/storage use.
- Inspected the six PNG assets and their metadata, SVG sources and the metadata
  of the twelve bundled fonts. No project screenshots containing personal data
  or personal build paths were found. Font attribution/licensing is intentional.

This is a review of reachable repository history exposed by GitHub, not a
forensic guarantee about unreachable server objects, external clones, Actions
secret values, old log/artifact contents or the live server filesystem.

## Findings and disposition

No committed credentials, private keys, real test credentials, personal home
paths or internal hostnames were identified. Token/entropy candidates were
variable references or badge URLs, not secrets. Test identities are examples;
commit email identities are GitHub noreply addresses.

The deployment script contains a public server endpoint and a restricted deploy
account name. These are connection metadata, not credentials; the SSH key is
provided through Actions secrets and the host key is pinned. The website's
controller name and contact address are intentional public privacy information.
Neither finding calls for credential rotation or a history rewrite. No history
was rewritten. If a credential is found later, revoke/rotate it first and assess
history, refs, caches and copies; deleting it only from `main` is insufficient.

The missing security reporting policy is addressed by `SECURITY.md`, using the
existing contact mailbox rather than inventing an unconfigured security address.
The overly broad dependency claim is corrected in English and German on the
website and in both READMEs. The application remains unchanged.

Regression coverage exercises shell metacharacters through creation, recent
state, all six terminal launch adapters, executable paths (including controls),
clone option separation, known configuration values, rename, archive and restore.
Control characters in project names are rejected/skipped. Tests use isolated
homes, fake Claude/dialog/terminal/Git programs and a disposable execution marker.

The website source has no analytics, remote fonts or tracking cookies; its two
localStorage preferences match the privacy notice. The baseline main CI and
website deployment succeeded. Direct live HTTPS comparison was unavailable from
the audit environment, so live content/certificate state is not independently
certified here. The PR does not deploy; main CI deploys after merge.

## Release assessment and deferred work

No concrete security/privacy blocker was found in the reviewed history and
source. Merge the focused preparation PR after its existing CI passes. Repository
visibility remains a separate maintainer decision.

Deferred: `--doctor`, adding existing directories, a maintainable translation
architecture before French/Spanish, versioned/checksummed (optionally signed)
release updates, and Arch plus Debian/Ubuntu CI coverage. No telemetry, key,
provider or model management is introduced.
