# TAM MCP Server Dockerfile
# Multi-stage build for optimized production image

# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including dev for TypeScript build)
RUN npm ci --ignore-scripts

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Production
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only (ignore prepare script which tries to build)
RUN npm ci --only=production --ignore-scripts

# Copy built files from builder stage
COPY --from=builder /app/dist ./dist

# Create logs directory
RUN mkdir -p logs

# Expose port
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
ENV LOG_LEVEL=info
ENV HOST=0.0.0.0
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the server (HTTP is now the default)
CMD ["node", "dist/index.js"]
