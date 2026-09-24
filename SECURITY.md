# Security policy

## Supported versions

Security fixes target the latest release in the **0.3.x** series (currently
0.3.1). Please update to the latest patch release before reporting an issue.
Older versions are not supported; `main` is development code, not a release.

## Report a vulnerability privately

Email **oss-security@brue.nu**, the project's dedicated security contact mailbox,
with the subject **cc-picker security report**. Do not report an unpatched
vulnerability first in a public issue, pull request or discussion.

Include the affected version, Linux distribution and Bash version, the impact,
and minimal reproduction steps using disposable folders and fake credentials.
Do not send real passwords, tokens, private keys, personal project contents or
unredacted logs. If sensitive evidence is needed, first ask how to share it
securely.

The maintainer will assess the report privately and coordinate a fix and public
disclosure with the reporter. This is a volunteer project; there is no guaranteed
response time. If you have not heard back after seven days, please follow up by
email rather than publishing the vulnerability.

## Scope

Reports about command injection, unsafe path handling, configuration parsing,
installation, updates and the project's website or workflows are welcome.
cc-picker launches your existing Claude Code installation; vulnerabilities in
Claude Code itself should be reported to its vendor.

The installed cc-picker launcher does not manage API keys, providers or models
and has no telemetry. The project website separately offers consent-based,
self-hosted Matomo analytics. See the
[privacy notice](https://cc-picker.brue.nu/privacy.html) for details and withdrawal.
