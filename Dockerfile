# Simple Docker Test Project
FROM alpine:latest

# Install basic tools
RUN apk add --no-cache \
    curl \
    wget \
    git \
    bash

# Create a simple test script
RUN echo '#!/bin/bash' > /test.sh && \
    echo 'echo "Docker container is working!"' >> /test.sh && \
    echo 'echo "Current date: $(date)"' >> /test.sh && \
    echo 'echo "Available commands: curl, wget, git"' >> /test.sh && \
    chmod +x /test.sh

# Set working directory
WORKDIR /app

# Copy test files
COPY . .

# Default command
CMD ["/test.sh"]
