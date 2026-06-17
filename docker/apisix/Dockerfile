# APISIX Builder Dockerfile
# Builds APISIX + OpenResty from source
# Output stage has files under /output/

#======================================
# Stage 1: Build OpenResty and APISIX
#======================================
FROM debian:bookworm-slim AS builder

ARG APISIX_VERSION=3.16.0
ARG OPENRESTY_VERSION=1.29.2.5

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential autoconf automake libtool pkg-config \
    git curl wget ca-certificates \
    libpcre3-dev libpcre2-dev libssl-dev libyaml-dev \
    zlib1g-dev libreadline-dev luarocks lua5.1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Build OpenResty
RUN wget -q https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz \
    && tar -xzf openresty-${OPENRESTY_VERSION}.tar.gz \
    && cd openresty-${OPENRESTY_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty \
        --with-http_v2_module --with-http_ssl_module \
        --with-http_realip_module --with-http_stub_status_module \
        --with-http_gzip_static_module --with-pcre-jit \
        --with-stream --with-stream_ssl_module --with-stream_realip_module \
    && make -j$(nproc) && make install \
    && cd .. && rm -rf openresty-${OPENRESTY_VERSION}*

# Download APISIX source
RUN wget -q https://downloads.apache.org/apisix/${APISIX_VERSION}/apache-apisix-${APISIX_VERSION}-src.tgz \
    && mkdir -p apisix-source \
    && tar -xzf apache-apisix-${APISIX_VERSION}-src.tgz -C apisix-source --strip-components=1 \
    && rm -f apache-apisix-${APISIX_VERSION}-src.tgz

WORKDIR /build/apisix-source

# Install APISIX Lua dependencies
RUN luarocks install --only-deps apisix-*.rockspec --tree=/usr/local/apisix/deps
RUN luarocks install lua-resty-jit-uuid --tree=/usr/local/apisix/deps
RUN luarocks install lua-resty-openssl --tree=/usr/local/apisix/deps

# Copy APISIX source to /usr/local/apisix
RUN mkdir -p /usr/local/apisix && cp -r . /usr/local/apisix/

# Bundle portable shared libraries into openresty/lib for portability.
# Only bundle portable libs (pcre, ssl, crypto, yaml, zlib, luajit).
# Do NOT bundle system-critical libs (libc, libm, libdl, libcrypt, libpthread)
# as they must come from the host system to avoid GLIBC version mismatches.
RUN mkdir -p /usr/local/openresty/lib && \
    for lib in libpcre libssl libcrypto libyaml libz; do \
        find /usr/lib /lib -name "$lib.so*" -type f 2>/dev/null | head -5 | while read f; do \
            cp -aL "$f" /usr/local/openresty/lib/ 2>/dev/null || true; \
        done; \
    done; \
    # Also bundle luajit from openresty itself
    cp -aL /usr/local/openresty/luajit/lib/libluajit* /usr/local/openresty/lib/ 2>/dev/null || true; \
    # Create symlinks
    cd /usr/local/openresty/lib && \
    for f in *.so.*; do \
        base="${f%%.so*}.so"; \
        [ ! -f "$base" ] && ln -sf "$f" "$base" 2>/dev/null || true; \
    done; \
    echo "Bundled libs:" && ls -la /usr/local/openresty/lib/ | head -20

#======================================
# Stage 2: Package
#======================================
FROM debian:bookworm-slim AS package

ARG APISIX_VERSION=3.16.0
ARG OPENRESTY_VERSION=1.29.2.5

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates libpcre3 libssl3 zlib1g libyaml-0-2 \
    && rm -rf /var/lib/apt/lists/*

# Copy from builder
COPY --from=builder /usr/local/openresty /usr/local/openresty
COPY --from=builder /usr/local/apisix /usr/local/apisix

# Prepare output
RUN mkdir -p /output/apisix-${APISIX_VERSION}
RUN cp -a /usr/local/openresty /output/apisix-${APISIX_VERSION}/openresty
RUN cp -a /usr/local/apisix /output/apisix-${APISIX_VERSION}/apisix
RUN mkdir -p /output/apisix-${APISIX_VERSION}/bin
RUN ln -sf ../openresty/nginx/sbin/nginx /output/apisix-${APISIX_VERSION}/bin/openresty
RUN ln -sf ../openresty/bin/resty /output/apisix-${APISIX_VERSION}/bin/resty

# Create apisix wrapper
RUN printf '#!/bin/bash\nDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"\nPATH="$DIR/openresty/bin:$DIR/openresty/nginx/sbin:$PATH"\nLD_LIBRARY_PATH="$DIR/lib:${LD_LIBRARY_PATH:-}"\nLUA_PATH="$DIR/apisix/deps/share/lua/5.1/?.lua;$DIR/apisix/deps/share/lua/5.1/?/init.lua;$DIR/apisix/?.lua;$DIR/apisix/?/init.lua;"\nLUA_CPATH="$DIR/apisix/deps/lib/lua/5.1/?.so;"\nexport PATH LD_LIBRARY_PATH LUA_PATH LUA_CPATH\ncd "$DIR/apisix" && exec ./bin/apisix "$@"\n' > /output/apisix-${APISIX_VERSION}/bin/apisix

RUN printf '#!/bin/bash\nDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"\nexport PATH="$DIR/bin:$DIR/openresty/bin:$DIR/openresty/nginx/sbin:$PATH"\nexport LD_LIBRARY_PATH="$DIR/lib:${LD_LIBRARY_PATH:-}"\nexport LUA_PATH="$DIR/apisix/deps/share/lua/5.1/?.lua;$DIR/apisix/deps/share/lua/5.1/?/init.lua;$DIR/apisix/?.lua;$DIR/apisix/?/init.lua;"\nexport LUA_CPATH="$DIR/apisix/deps/lib/lua/5.1/?.so;"\necho "APISIX env ready"\n' > /output/apisix-${APISIX_VERSION}/set-env.sh

RUN chmod +x /output/apisix-${APISIX_VERSION}/bin/apisix /output/apisix-${APISIX_VERSION}/set-env.sh

# Copy runtime libs
RUN mkdir -p /output/apisix-${APISIX_VERSION}/lib && \
    cp -aL /lib/x86_64-linux-gnu/libpcre* /output/apisix-${APISIX_VERSION}/lib/ 2>/dev/null; \
    cp -aL /lib/x86_64-linux-gnu/libssl* /output/apisix-${APISIX_VERSION}/lib/ 2>/dev/null; \
    cp -aL /lib/x86_64-linux-gnu/libcrypto* /output/apisix-${APISIX_VERSION}/lib/ 2>/dev/null; \
    cp -aL /lib/x86_64-linux-gnu/libyaml* /output/apisix-${APISIX_VERSION}/lib/ 2>/dev/null; \
    cp -aL /lib/x86_64-linux-gnu/libz* /output/apisix-${APISIX_VERSION}/lib/ 2>/dev/null; true

RUN echo "APISIX ${APISIX_VERSION}" > /output/apisix-${APISIX_VERSION}/VERSION

# Verify output exists
RUN ls -la /output/apisix-${APISIX_VERSION}/ && ls -la /output/apisix-${APISIX_VERSION}/bin/

#======================================
# Stage 3: Runtime
#======================================
FROM debian:bookworm-slim AS runtime

ARG APISIX_VERSION=3.16.0
ARG OPENRESTY_VERSION=1.29.2.5

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates lua5.1 libpcre3 libssl3 zlib1g libyaml-0-2 \
    && rm -rf /var/lib/apt/lists/* \
    # Create lua symlink - bin/apisix uses #!/usr/bin/env lua shebang
    && ln -sf /usr/bin/lua5.1 /usr/bin/lua

# Copy OpenResty and APISIX from package stage
COPY --from=package /usr/local/openresty /usr/local/openresty
COPY --from=package /usr/local/apisix /usr/local/apisix

# Set up runtime environment
ENV APISIX_HOME="/usr/local/apisix" \
    PATH="/usr/local/openresty/bin:/usr/local/openresty/nginx/sbin:/usr/local/apisix/bin:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/openresty/lib:${LD_LIBRARY_PATH:-}" \
    LUA_PATH="/usr/local/apisix/deps/share/lua/5.1/?.lua;/usr/local/apisix/deps/share/lua/5.1/?/init.lua;/usr/local/apisix/?.lua;/usr/local/apisix/?/init.lua;" \
    LUA_CPATH="/usr/local/apisix/deps/lib/lua/5.1/?.so;"

# Create entrypoint script: starts APISIX then tails logs to keep container alive
RUN printf '%s\n' '#!/bin/bash' \
    'set -e' \
    '' \
    'cd "${APISIX_HOME}"' \
    '' \
    'echo "Starting APISIX..."' \
    'if ! /usr/local/apisix/bin/apisix start 2>&1; then' \
    '  echo "[FAIL] APISIX CLI failed. Last 30 lines of error.log:"' \
    '  tail -30 /usr/local/apisix/logs/error.log 2>/dev/null || true' \
    '  exit 1' \
    'fi' \
    '' \
    '# Wait for Admin API to become available' \
    'for i in $(seq 15); do' \
    '  if curl -sf http://127.0.0.1:9090/v1/health >/dev/null 2>&1; then' \
    '    echo "[OK] APISIX ready (Admin API responded)"' \
    '    break' \
    '  fi' \
    '  sleep 2' \
    'done' \
    '' \
    '# Final check - if not ready, dump logs and exit' \
    'if ! curl -sf http://127.0.0.1:9090/v1/health >/dev/null 2>&1; then' \
    '  echo "[FAIL] APISIX Admin API not responding after 30s"' \
    '  echo "=== nginx pid ==="' \
    '  cat /usr/local/apisix/logs/nginx.pid 2>/dev/null || echo "(no pid file)"' \
    '  echo "=== error.log (last 50) ==="' \
    '  tail -50 /usr/local/apisix/logs/error.log 2>/dev/null || echo "(no error.log)"' \
    '  echo "=== config.yaml ==="' \
    '  cat /usr/local/apisix/conf/config.yaml 2>/dev/null || echo "(no config)"' \
    '  exit 1' \
    'fi' \
    '' \
    'echo "Tailing logs..."' \
    'exec tail -f /usr/local/apisix/logs/error.log' \
    > /usr/local/bin/start-apisix.sh \
    && chmod +x /usr/local/bin/start-apisix.sh

WORKDIR /usr/local/apisix

EXPOSE 9080 9443 9090

STOPSIGNAL SIGQUIT

CMD ["/usr/local/bin/start-apisix.sh"]
