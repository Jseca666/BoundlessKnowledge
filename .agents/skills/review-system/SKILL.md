---
name: review-system
description: Use the knowledge-base review module for proactive system review, external knowledge review, visual review, release-readiness review, and review-to-diagnostics handoff.
---

# Review System

This is a thin skill entrypoint. It only routes into the review module.

Read order:

- `system/route-registry.json` route `review-system`
- `system/reviews/review-system.json`
- `system/reviews/review-queue.json`
- `system/reviews/review-docs-map.json`
- `schemas/review-record.schema.json`
- `system/information-map.json`

Use this skill when the user asks for review, audit, inspection, quality review, external knowledge review, source review, visual review, or release-readiness review.

Boundary:

- Machine truth, review classes, criteria, workflow and durable record fields live in the routed JSON/schema files.
- This entry may state general review principles only: name scope before judging, read authoritative surfaces, separate observations from defects, and hand systemic defects to diagnostics.
- Do not add local module methods, output templates or special-case rules here.
