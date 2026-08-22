FROM n8nio/n8n:latest

# Keep the first staging image identical to the official n8n runtime.
# Current n8n v2 images intentionally omit OS package managers such as apk,
# so business-schema migrations are applied as a separate controlled step.
