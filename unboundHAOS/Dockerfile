ARG BUILD_ARCH

FROM klutchell/unbound:latest

# Set the default shell for subsequent RUN commands
# This is crucial for Alpine-based images where /bin/sh might not be present or linked as expected.
SHELL ["/bin/bash", "-c"]

# Copy the run.sh script into the container
COPY run.sh /usr/bin/run.sh

# Ensure the script is executable
RUN chmod a+x /usr/bin/run.sh

# Set the entrypoint to your run.sh script
CMD [ "/usr/bin/run.sh" ]
