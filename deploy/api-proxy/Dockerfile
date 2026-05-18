FROM node:20-alpine
WORKDIR /app
RUN npm install -g wrangler
COPY worker.js wrangler.toml ./
EXPOSE 8787
CMD ["wrangler", "dev", "--port", "8787", "--ip", "0.0.0.0"]
