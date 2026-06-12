FROM node:22-alpine
WORKDIR /app

# Nur Manifeste kopieren, damit der npm-Layer gecacht wird
COPY package.json package-lock.json* ./
RUN npm install --omit=dev --no-audit --no-fund

COPY server.js ./
COPY public/ ./public/

EXPOSE 3000
CMD ["node", "server.js"]
