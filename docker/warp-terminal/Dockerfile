FROM debian:bullseye-slim

# Install essential packages and security updates
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd with checksum verification
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.3/ttyd.x86_64 -o /usr/local/bin/ttyd && \
    echo "b557d32bd5a67adcf2020825f3b0203499de1b2358d21ed6ed168e589efbdbf5  /usr/local/bin/ttyd" | sha256sum -c - && \
    chmod +x /usr/local/bin/ttyd

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd -g ${USER_GID} warpuser && \
    useradd -u ${USER_UID} -g ${USER_GID} -m -s /bin/bash warpuser

# Set up GPG directory
RUN mkdir -p /home/warpuser/.gnupg && \
    chown -R warpuser:warpuser /home/warpuser/.gnupg && \
    chmod 700 /home/warpuser/.gnupg

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

USER warpuser
WORKDIR /home/warpuser

# Expose ttyd port
EXPOSE 7681

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
