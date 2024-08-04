ARG NODE_VERSION=20.11.0

################################################################################
# Use node image for base image for all stages.
FROM node:${NODE_VERSION}-alpine AS base

# Set working directory for all build stages.
WORKDIR /usr/src/app

RUN apk --no-cache add ca-certificates wget
RUN wget https://raw.githubusercontent.com/athalonis/docker-alpine-rpi-glibc-builder/master/glibc-2.26-r1.apk
RUN apk add --allow-untrusted --force-overwrite glibc-2.26-r1.apk
RUN rm glibc-2.26-r1.apk

RUN npm install -g bun

################################################################################
# Create a stage for installing production dependencies.
FROM base AS deps

# Copy Bun installation from base stage to deps stage
ENV PATH="$(npm bin -g):${PATH}"

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.bun to speed up subsequent builds.
# Leverage bind mounts to package.json and bun.lockb to avoid having to copy them
# into this layer.
COPY package.json bun.lockb /usr/src/app/
RUN bun install

################################################################################
# Create a stage for building the application.
FROM deps AS build

# Copy the rest of the source files into the image.
COPY . .

# Run the build script.
RUN bun run build

################################################################################
# Create a new stage to run the application with minimal runtime dependencies
# where the necessary files are copied from the build stage.
FROM base AS final

# Copy Bun installation from base stage to final stage
ENV PATH="$(npm bin -g):${PATH}"

# Use production node environment by default.
ENV NODE_ENV="production"
ENV ORIGIN="https://qwik.gambala.pro"

# Run the application as a non-root user.
USER node

# Copy package.json so that package manager commands can be used.
COPY package.json .

# Copy the production dependencies from the deps stage and also
# the built application from the build stage into the image.
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/server ./server

# Expose the port that the application listens on.
EXPOSE 3000

# Run the application.
CMD ["bun", "run", "serve"]
