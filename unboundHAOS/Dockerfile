# Use the BUILD_ARCH argument provided by Home Assistant Supervisor
ARG BUILD_ARCH

# Base image for Unbound from klutchell, using the architecture
FROM klutchell/unbound:${BUILD_ARCH}

# Copy the run.sh script into the container
COPY run.sh /usr/bin/run.sh

# Ensure the script is executable
RUN chmod a+x /usr/bin/run.sh

# Set the entrypoint to your run.sh script
CMD [ "/usr/bin/run.sh" ]
