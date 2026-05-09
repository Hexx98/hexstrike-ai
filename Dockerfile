# HexStrike AI — Tool Execution Backend
# Source: Hexx98/hexstrike-ai (git submodule)
#
# Initialize submodule before building:
#   git submodule add https://github.com/Hexx98/hexstrike-ai hexstrike
#   git submodule update --init --recursive

FROM python:3.12-slim

WORKDIR /app

# Non-root user — HexStrike must never run as root (STRIDE E2 mitigation)
RUN groupadd -r hexstrike && useradd -r -g hexstrike hexstrike

# System deps required by HexStrike tool integrations
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    nmap \
    dnsutils \
    whois \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Wordlist and output directories
RUN mkdir -p /wordlists /output && \
    chown -R hexstrike:hexstrike /app /wordlists /output

EXPOSE 9000

USER hexstrike

# HEXSTRIKE_HOST must be 0.0.0.0 in container (set via docker-compose env)
CMD ["python", "hexstrike_server.py"]
