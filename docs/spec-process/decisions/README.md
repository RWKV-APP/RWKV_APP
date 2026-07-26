# Specification Decisions

Store explicit human product or process rulings as strict `DEC-*` records using `docs/spec-process/templates.md`. A record may be `approved`, `superseded`, or `rejected`, and always names the human decision authority in `approved_by`, the governed stable assertions, and affected surfaces.

Only an approved decision can resolve a conflict or observation. A decision that resolves a conflict, rejects an input, changes process rules, or participates in acceptance must use exact bidirectional references.
