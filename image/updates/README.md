# Update and rollback scaffolding

This directory is for product update metadata and policies.

Target capabilities:

- signed update artifacts,
- channel-aware rollout metadata,
- boot-success marking,
- rollback eligibility,
- compatibility gates per board pack.

The current repository supports runtime/config migration, but not yet atomic image rollback.
This directory is where that platform layer should be introduced.
