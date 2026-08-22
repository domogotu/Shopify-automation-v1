# Dynamic Memory Categories

## Purpose

The memory hub organizes information into a governed, expandable category tree. Categories are navigation and retrieval scopes; they do not replace source evidence, memory kinds, freshness, permissions, or store isolation.

Example hierarchy:

```text
Finance
  Markets
    Equities
    Foreign Exchange
  Business Finance
    Cash Flow
    Taxes
Business
  Reeds Solutions LLC
  Shopify Store
    Products
    Suppliers
    Orders
Federal Contracting
  Opportunities
  Proposals
  Awards
```

One memory item can belong to several categories, but it has one primary category. Cross-category assignment prevents duplication when information belongs in both Finance and Shopify, for example.

## Classification flow

1. Sanitize and validate the incoming information.
2. Identify its store, source, authority, sensitivity, memory kind, and freshness.
3. Compare it with active category names, descriptions, aliases, and examples.
4. Assign a primary category and optional secondary categories with confidence and reasons.
5. If no category fits, place it in `Uncategorized Review` and evaluate a new-category proposal.
6. Search for duplicate or near-duplicate categories before proposing one.
7. Create only low-risk child categories automatically when policy thresholds are met.
8. Require human review for roots, merges, splits, deletion, sensitive categories, permissions, or retention changes.
9. Record every assignment and taxonomy change in the audit trail.

## Improvement loop

The weekly Memory Librarian review detects:

- repeated uncategorized subjects;
- duplicate or synonymous categories;
- categories with too many unrelated items;
- empty, orphaned, or unused categories;
- items frequently retrieved together;
- user corrections to classification;
- categories whose names no longer match their contents.

It may propose creating, renaming, moving, merging, splitting, or archiving categories. Verified memory is never silently rewritten. Reclassification creates an auditable assignment change, and category restructuring preserves the underlying memory and sources.

## Retrieval behavior

When a user asks within a category, retrieval searches the selected category, its approved descendants, relevant cross-category links, and permitted memories only. Results are ranked by authority, freshness, category relevance, semantic similarity, and confidence.

The user can also ask:

- "Show what you know under Finance."
- "Create a category for commercial real estate."
- "Move this information to Reeds Solutions."
- "Why was this stored under Marketing?"
- "Show uncategorized information."
- "Merge these two categories."

Structural or sensitive changes follow the approval policy.
