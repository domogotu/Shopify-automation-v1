FROM n8nio/n8n:latest

USER root
RUN apk add --no-cache postgresql-client

COPY database/migrations /opt/shopify-automation/migrations
COPY database/seeds /opt/shopify-automation/seeds
COPY workflows /opt/shopify-automation/workflows
COPY config /opt/shopify-automation/config
COPY scripts/apply-migrations.sh /opt/shopify-automation/scripts/apply-migrations.sh
COPY scripts/render-start.sh /opt/shopify-automation/scripts/render-start.sh

RUN chmod 0555 /opt/shopify-automation/scripts/apply-migrations.sh \
    /opt/shopify-automation/scripts/render-start.sh

USER node
ENTRYPOINT ["/opt/shopify-automation/scripts/render-start.sh"]
