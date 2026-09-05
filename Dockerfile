# syntax=docker/dockerfile:1

# ---- Build stage ----
FROM node:24-alpine AS build
RUN corepack enable pnpm && corepack prepare pnpm@11.20.0 --activate
WORKDIR /opt/strapi

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

COPY config/ ./config/
COPY src/ ./src/
COPY types/ ./types/
COPY database/ ./database/
COPY public/ ./public/
COPY favicon.png tsconfig.json ./

RUN pnpm build

# ---- Runtime stage ----
FROM node:24-alpine
RUN corepack enable pnpm && corepack prepare pnpm@11.20.0 --activate
ENV NODE_ENV=production
WORKDIR /opt/strapi

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile --prod

COPY --from=build /opt/strapi/dist ./dist
COPY --from=build /opt/strapi/config ./config
COPY --from=build /opt/strapi/src ./src
COPY --from=build /opt/strapi/database ./database
COPY --from=build /opt/strapi/public ./public
COPY --from=build /opt/strapi/favicon.png ./

RUN chown -R node:node /opt/strapi
USER node

EXPOSE 1337

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:1337/admin/ || exit 1

CMD ["pnpm", "run", "start"]
