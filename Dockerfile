FROM python:3.12-slim-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    gpg \
    gnupg2 \
    sudo \
    libsecret-tools \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install UV
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    cp /root/.local/bin/uv /usr/local/bin/ && \
    cp /root/.local/bin/uvx /usr/local/bin/

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
ARG USERNAME=warp
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Create directories for user configuration
RUN mkdir -p /home/$USERNAME/.gnupg /home/$USERNAME/.config /home/$USERNAME/.local/share/keyrings && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.gnupg /home/$USERNAME/.config /home/$USERNAME/.local && \
    chmod 700 /home/$USERNAME/.gnupg

USER $USERNAME
WORKDIR /home/$USERNAME

# Copy entrypoint script
COPY --chown=$USERNAME:$USERNAME entrypoint.sh /home/$USERNAME/entrypoint.sh
RUN chmod +x /home/$USERNAME/entrypoint.sh

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_HOME=/home/$USERNAME/.uv \
    PATH=/home/$USERNAME/.uv/bin:/home/$USERNAME/.local/bin:$PATH \
    GPG_TTY=/dev/pts/0

ENTRYPOINT ["/home/warp/entrypoint.sh"]
