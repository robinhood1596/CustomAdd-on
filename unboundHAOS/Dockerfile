# We still need BUILD_ARCH because it's available, even if we don't use it directly in the FROM line.
# It's good practice to keep it if you might need it for other architecture-specific logic later.
ARG BUILD_ARCH

# Use the 'latest' tag, which is multi-architecture friendly for klutchell/unbound
FROM klutchell/unbound:latest

# Copy the run.sh script into the container
COPY run.sh /usr/bin/run.sh

# Ensure the script is executable
RUN chmod a+x /usr/bin/run.sh

# Set the entrypoint to your run.sh script
CMD [ "/usr/bin/run.sh" ]
