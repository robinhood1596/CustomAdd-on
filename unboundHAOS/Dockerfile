# Stage 1: Build Stage - Use a base image with a shell to prepare files
FROM alpine:latest AS build_stage

# Copy your run.sh script into the build stage
COPY run.sh /usr/bin/run.sh

# Ensure the script is executable in this stage
RUN chmod a+x /usr/bin/run.sh


# Stage 2: Final Image Stage - Use the minimalist klutchell/unbound image
ARG BUILD_ARCH
FROM klutchell/unbound:latest

# Copy the prepared (executable) run.sh from the build_stage
COPY --from=build_stage /usr/bin/run.sh /usr/bin/run.sh

# Set the entrypoint to your run.sh script
CMD [ "/usr/bin/run.sh" ]
