# Google Sheets Review Workbook

Google Sheets is the phone-friendly approval and operations surface. PostgreSQL remains the authoritative record. Sheet edits never trigger an external action until n8n validates the row, records an approval decision, and passes all safety checks.

## Workbook Tabs

### 1. Product Intake

`candidate_id`, `supplier`, `supplier_product_id`, `supplier_url`, `supplier_sku`, `product_title`, `warehouse`, `product_cost`, `shipping_cost`, `processing_days`, `delivery_days`, `inventory_status`, `submitted_by`, `intake_status`, `validation_errors`, `created_at`, `updated_at`

### 2. Research Scores

`candidate_id`, `demand_score`, `margin_score`, `shipping_score`, `supplier_score`, `return_risk_score`, `regulatory_risk_score`, `ip_risk_score`, `overall_score`, `recommendation`, `evidence_links`, `review_status`, `reviewer`, `reviewed_at`

### 3. Pricing Review

`candidate_id`, `variant_sku`, `supplier_cost`, `supplier_shipping`, `duties_allowance`, `fee_allowance`, `refund_reserve`, `ad_allowance`, `landed_cost`, `proposed_price`, `gross_margin_pct`, `contribution_profit`, `price_status`, `reviewer`, `reviewed_at`

### 4. Content Review

`candidate_id`, `content_draft_id`, `title`, `description_html`, `benefits`, `specifications`, `tags`, `seo_title`, `seo_description`, `alt_text`, `source_facts`, `risk_flags`, `content_status`, `reviewer`, `reviewed_at`

### 5. Publish Queue

`candidate_id`, `shopify_product_id`, `handle`, `variant_count`, `mapping_complete`, `pricing_approved`, `content_approved`, `sample_status`, `publish_status`, `reviewer`, `reviewed_at`, `published_at`

### 6. Supplier Mapping

`shopify_product_id`, `shopify_variant_id`, `shopify_sku`, `supplier`, `supplier_product_id`, `supplier_variant_id`, `supplier_sku`, `mapping_status`, `verified_by`, `verified_at`, `validation_error`

### 7. Order Exceptions

`order_id`, `shopify_order_name`, `exception_type`, `severity`, `summary`, `recommended_action`, `approval_required`, `decision`, `decided_by`, `decided_at`, `status`

### 8. Support Review

`ticket_id`, `order_id`, `intent`, `risk_level`, `customer_summary`, `draft_reply`, `proposed_action`, `send_status`, `action_status`, `reviewer`, `reviewed_at`

### 9. Campaign Review

`campaign_id`, `channel`, `campaign_type`, `audience`, `subject_or_hook`, `content`, `offer`, `budget_limit`, `campaign_status`, `reviewer`, `reviewed_at`

### 10. Daily Metrics

`metric_date`, `gross_sales`, `net_sales`, `orders`, `average_order_value`, `refunds`, `chargebacks`, `landed_cost`, `gross_profit_estimate`, `contribution_profit_estimate`, `fulfillment_rate`, `delayed_orders`, `support_tickets`, `data_as_of`

### 11. Workflow Errors

`correlation_id`, `workflow_key`, `execution_id`, `error_class`, `error_summary`, `retryable`, `attempt`, `status`, `first_seen_at`, `last_seen_at`, `resolved_at`

### 12. Configuration

`key`, `value`, `value_type`, `environment`, `editable`, `description`, `updated_by`, `updated_at`

## Controlled Values

- Approvals: `PENDING`, `APPROVED`, `REJECTED`, `EXPIRED`, `CANCELLED`
- Candidate: `DISCOVERED`, `REVIEW`, `SAMPLE_REQUIRED`, `APPROVED`, `REJECTED`, `PAUSED`, `RETIRED`
- Mapping: `UNMAPPED`, `PARTIAL`, `VALID`, `INVALID`, `PAUSED`
- Publish: `BLOCKED`, `READY`, `APPROVED`, `PUBLISHED`, `PAUSED`, `RETIRED`

## Protection Rules

- Protect identifier, calculated, timestamp, and audit columns.
- Allow users to edit only review decisions, comments, and explicitly editable configuration values.
- Use dropdown validation for all status fields.
- Never store API keys, access tokens, passwords, customer addresses, or complete customer messages in Sheets.
