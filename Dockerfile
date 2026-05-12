# HexStrike AI — Tool Execution Backend
FROM python:3.12-slim

WORKDIR /app

RUN groupadd -r hexstrike && useradd -r -g hexstrike hexstrike

RUN apt-get update && apt-get install -y \
    curl wget git nmap dnsutils whois unzip perl \
    && rm -rf /var/lib/apt/lists/*

# nikto — install from source (not in standard debian repos)
RUN git clone --depth 1 https://github.com/sullo/nikto.git /opt/nikto && \
    ln -s /opt/nikto/program/nikto.pl /usr/local/bin/nikto && \
    chmod +x /opt/nikto/program/nikto.pl

# wafw00f (Python)
RUN pip install --no-cache-dir wafw00f

# Go 1.22
RUN curl -sSL https://go.dev/dl/go1.22.3.linux-amd64.tar.gz | tar -C /usr/local -xz
ENV PATH=$PATH:/usr/local/go/bin:/usr/local/go-tools/bin
ENV GOPATH=/usr/local/go-tools

# Go-based recon tools
RUN go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null || true
RUN go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest 2>/dev/null || true
RUN go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest 2>/dev/null || true
RUN go install -v github.com/projectdiscovery/katana/cmd/katana@latest 2>/dev/null || true
RUN go install -v github.com/hakluke/hakrawler@latest 2>/dev/null || true
RUN go install -v github.com/lc/gau/v2/cmd/gau@latest 2>/dev/null || true
RUN go install -v github.com/OJ/gobuster/v3@latest 2>/dev/null || true
# amass — pre-built binary (go install is too slow to compile)
RUN curl -sL https://github.com/owasp-amass/amass/releases/download/v4.2.0/amass_Linux_amd64.zip \
    -o /tmp/amass.zip && unzip -q /tmp/amass.zip -d /tmp/amass && \
    mv /tmp/amass/amass_Linux_amd64/amass /usr/local/bin/ && \
    chmod +x /usr/local/bin/amass && rm -rf /tmp/amass /tmp/amass.zip 2>/dev/null || true

# Copy Go binaries to system PATH
RUN cp /root/go/bin/* /usr/local/bin/ 2>/dev/null || true

# feroxbuster binary
RUN curl -sL https://github.com/epi052/feroxbuster/releases/latest/download/x86-linux-feroxbuster.zip \
    -o /tmp/ferox.zip && unzip -q /tmp/ferox.zip -d /tmp && \
    mv /tmp/feroxbuster /usr/local/bin/ && chmod +x /usr/local/bin/feroxbuster && \
    rm /tmp/ferox.zip 2>/dev/null || true

# nuclei
RUN go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

# dalfox (XSS scanner)
RUN go install -v github.com/hahwul/dalfox/v2@latest

# sqlmap
RUN pip install --no-cache-dir sqlmap

# testssl.sh
RUN curl -sL https://github.com/drwetter/testssl.sh/archive/refs/heads/3.2.zip \
    -o /tmp/testssl.zip && unzip -q /tmp/testssl.zip -d /tmp && \
    mv /tmp/testssl.sh-3.2/testssl.sh /usr/local/bin/testssl.sh && \
    chmod +x /usr/local/bin/testssl.sh && rm -rf /tmp/testssl*

# wpscan
RUN apt-get update && apt-get install -y ruby ruby-dev libcurl4-openssl-dev libssl-dev && \
    gem install wpscan --no-document && \
    rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p /wordlists /output && \
    chown -R hexstrike:hexstrike /app /wordlists /output

EXPOSE 9000

USER hexstrike

CMD ["python", "hexstrike_server.py"]
