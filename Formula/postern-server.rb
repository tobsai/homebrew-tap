# Source-of-truth for the Postern *server* Homebrew formula (copied to
# tobsai/homebrew-tap as Formula/postern-server.rb at release; see docs/release-server.md).
#
# This installs the self-hosted Postern relay (@postern/server) as a brew-services
# daemon. As with the `postern` CLI formula, the source repo (tobsai/postern) is
# PRIVATE, so we do NOT build from source: each release publishes a prebuilt,
# self-contained server bundle (dist + node_modules, incl. the resolved
# @postern/shared dist and the better-sqlite3 native addon) as a PUBLIC release
# asset on the tap repo, and the formula just downloads + installs it.
#
# Unlike the CLI bundle, the server bundle is ARCH-SPECIFIC (better-sqlite3 ships a
# compiled .node) and is pinned to node@22: the shipped prebuild targets the Node 22
# ABI, so it loads without a compile step. Publish one asset per arch and bump
# url/sha256/version per release.
class PosternServer < Formula
  desc "Self-hosted Postern relay server (Fastify) as a brew-services daemon"
  homepage "https://github.com/tobsai/postern"
  arch = Hardware::CPU.arm? ? "arm64" : "x64"
  url "https://github.com/tobsai/homebrew-tap/releases/download/postern-server-0.1.0/postern-server-0.1.0-darwin-#{arch}.tar.gz"
  version "0.1.0"
  sha256(Hardware::CPU.arm? ? "6e3adbbcfa771967c57f9f8e60119a6ebbef1e268bd5cdb3a8b74fb1c735ea48" : "c518a56466da176e61e15ed5e6b6ac48c2eb7cc257fd0033bf2314a82f7cb73d")
  license "MIT"

  depends_on :macos # darwin-only prebuilt addon; Linuxbrew out of scope
  depends_on "node@22"

  def install
    # dist/ + node_modules/ (incl. @postern/shared dist and better-sqlite3 .node)
    libexec.install Dir["*"]

    env_file = etc/"postern-server/postern.env"
    node = Formula["node@22"].opt_bin/"node"

    # Wrapper: source the operator's env file, then exec the pinned node on the server.
    # (A brew `service`/`bin` invocation can't itself "source" a file.)
    (libexec/"bin").mkpath
    (libexec/"bin/postern-server").write <<~SH
      #!/bin/bash
      set -a
      [ -f "#{env_file}" ] && . "#{env_file}"
      set +a
      exec "#{node}" "#{libexec}/dist/server.js" "$@"
    SH
    chmod 0755, libexec/"bin/postern-server"

    (bin/"postern-server").write <<~SH
      #!/bin/bash
      exec "#{opt_libexec}/bin/postern-server" "$@"
    SH

    # Template env file with self-host defaults (see packages/server/src/config.ts).
    env_template = <<~ENV
      # Postern server config (self-host defaults).
      # Edit, then: brew services restart postern-server
      PORT=4080
      POSTERN_DB=#{var}/postern-server/postern.db
      POSTERN_MEDIA_DIR=#{var}/postern-server/media

      # CHANGE THESE — long random strings (e.g. `openssl rand -hex 32`):
      POSTERN_JWT_SECRET=change-me-please
      POSTERN_AGENT_TOKEN_SECRET=change-me-please

      # Agent backend: `fake` (canned agent) or `hermes` (real Hermes + OpenClaw connectors).
      AGENT_BACKEND=fake
      HERMES_BASE_URL=http://localhost:8642/v1
      # HERMES_API_KEY=
      # OPENCLAW_BASE_URL=http://localhost:8643/v1
      # OPENCLAW_API_KEY=

      # Google Sign-In: comma-separated OAuth client IDs.
      GOOGLE_CLIENT_IDS=
    ENV

    (etc/"postern-server").mkpath
    # Always refresh the example so operators can diff against new defaults...
    (etc/"postern-server/postern.env.example").write env_template
    # ...but never clobber a live, edited config on upgrade.
    env_file.write env_template unless env_file.exist?
  end

  def post_install
    (var/"postern-server/media").mkpath
    (var/"log").mkpath
  end

  service do
    run [opt_libexec/"bin/postern-server"]
    keep_alive true
    working_dir var/"postern-server"
    log_path var/"log/postern-server.log"
    error_log_path var/"log/postern-server.log"
  end

  def caveats
    <<~EOS
      Config (edit, then restart the service):
        #{etc}/postern-server/postern.env
        # set POSTERN_JWT_SECRET + POSTERN_AGENT_TOKEN_SECRET to random strings
        # (openssl rand -hex 32), and GOOGLE_CLIENT_IDS to your OAuth client IDs.

      Start the relay daemon:
        brew services start postern-server
        curl http://localhost:4080/health     # -> {"ok":true}

      Data lives in #{var}/postern-server (DB + media);
      logs in #{var}/log/postern-server.log.

      Attach a LOCAL agent to this relay (all-in-one local stack):
        brew install tobsai/tap/postern
        POSTERN_GOOGLE_CLIENT_SECRET=<desktop-oauth-secret> \\
          postern register --cloud http://localhost:4080
        # then restart Hermes to load the Postern platform.
        # (Requires AGENT_BACKEND=hermes in postern.env to drive real runs.)
    EOS
  end

  test do
    assert_path_exists libexec/"dist/server.js"
    assert_path_exists etc/"postern-server/postern.env.example"

    port = free_port
    pid = spawn(
      { "POSTERN_DB" => ":memory:", "PORT" => port.to_s },
      Formula["node@22"].opt_bin/"node", libexec/"dist/server.js"
    )
    sleep 4
    assert_match "\"ok\":true", shell_output("curl -s http://localhost:#{port}/health")
  ensure
    Process.kill("TERM", pid) if pid
  end
end
