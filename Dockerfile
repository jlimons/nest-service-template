ARG NODE_VERSION=16.17.0

###
# DEVELOPMENT IMAGE
#
# This image has no code baked in since the code will be mounted into it
# by docker-comopse.
###

# Locking to a specific version to avoid version compatibility issues
FROM node:${NODE_VERSION} as development

# set node user's UID
ARG NODE_UID=1000
RUN groupmod -g "${NODE_UID}" node && usermod -u "${NODE_UID}" -g "${NODE_UID}" node

# Set to a non-root built-in user `node`
USER node
ENV HOST=0.0.0.0 PORT=8080
EXPOSE ${PORT}

###
# BUILDER IMAGE
#
# This builds upon the development image, installs modules, and
# builds the code
###

FROM development as builder

# Create app directory (with user `node`)
RUN mkdir -p /home/node/app

WORKDIR /home/node/app

# Install app dependencies
COPY --chown=node package.json yarn.lock .npmrc ./

ARG GITHUB_NPM_TOKEN
RUN yarn install

# Bundle app source code
COPY --chown=node . .

# HACK ALERT
# Remove .npmrc after running yarn install so that the GITHUB_NPM_TOKEN env var
# doesn't need to be set in order to run (other) yarn commands in production.
RUN rm .npmrc

RUN yarn run build

CMD [ "node", "dist/main" ]