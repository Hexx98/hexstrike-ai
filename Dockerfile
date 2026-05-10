# HexStrike AI — Tool Execution Backend
# Source: Hexx98/hexstrike-ai (git submodule)

FROM python:3.12-slim

WORKDIR /app

RUN groupadd -r hexstrike && useradd -r -g hexstrike hexstrike

# System tools
RUN apt-get update && apt-get install -y \
    curl wget git nmap dnsutils whois nikto \
    ruby ruby-dev build-essential libssl-dev libxml2 libxml2-dev libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

# wafw00f (Python)
RUN pip install --no-cache-dir wafw00f

# WPScan (Ruby)
RUN gem install wpscan --no-document 2>/dev/null || true

# Go tools — download pre-built binaries
ENV GOPATH=/usr/local/go
RUN curl -sSL https://go.dev/dl/go1.22.3.linux-amd64.tar.gz | tar -C /usr/local -xz
ENV PATH=$PATH:/usr/local/go/bin

RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null || true
RUN go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest 2>/dev/null || true
RUN go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest 2>/dev/null || true
RUN go install -v github.com/projectdiscovery/katana/cmd/katana@latest 2>/dev/null || true
RUN go install -v github.com/hakluke/hakrawler@latest 2>/dev/null || true
RUN go install -v github.com/lc/gau/v2/cmd/gau@latest 2>/dev/null || true
RUN go install -v github.com/OJ/gobuster/v3@latest 2>/dev/null || true
RUN go install -v github.com/OWASP/Amass/v4/...@latest 2>/dev/null || true

# Copy Go binaries to PATH
RUN cp /root/go/bin/* /usr/local/bin/ 2>/dev/null || true

# feroxbuster (Rust binary)
RUN curl -sL https://github.com/epi052/feroxbuster/releases/latest/download/x86-linux-feroxbuster.zip \
    -o /tmp/ferox.zip && cd /tmp && unzip -q ferox.zip && \
    mv feroxbuster /usr/local/bin/ && chmod +x /usr/local/bin/feroxbuster && \
    rm /tmp/ferox.zip 2>/dev/null || true

# Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p /wordlists /output && \
    chown -R hexstrike:hexstrike /app /wordlists /output

EXPOSE 9000

USER hexstrike

CMD ["python", "hexstrike_server.py"]
