FROM n8nio/n8n:latest

COPY workflows /opt/shopify-automation/workflows
COPY scripts/bootstrap-n8n.sh /opt/shopify-automation/bootstrap-n8n.sh

# Current n8n v2 images intentionally omit OS package managers. The bootstrap
# uses only n8n's supported CLI and the shell already included in the image.
ENTRYPOINT ["/bin/sh", "/opt/shopify-automation/bootstrap-n8n.sh"]
