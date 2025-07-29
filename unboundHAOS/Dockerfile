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

# Set the entrypoint to be a simple shell, then execute your script with bashio
# This explicitly ensures the bashio environment is loaded for your script
ENTRYPOINT ["/usr/bin/with-contenv", "bashio", "/usr/bin/run.sh"]

# CMD is often used with ENTRYPOINT for default arguments, but here run.sh takes care of it
CMD []
