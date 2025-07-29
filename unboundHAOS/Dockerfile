ARG BUILD_FROM
FROM ${BUILD_FROM}

# Copy the run.sh script into the container
COPY run.sh /usr/bin/run.sh

# Ensure the script is executable
RUN chmod a+x /usr/bin/run.sh

# Set the entrypoint to your run.sh script
CMD [ "/usr/bin/run.sh" ]
