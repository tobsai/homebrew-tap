class Fort < Formula
  desc "Self-improving personal AI agent platform"
  homepage "https://github.com/tobsai/fort"
  url "https://github.com/tobsai/fort/archive/refs/tags/v0.3.3.tar.gz"
  sha256 "2c2f7c250f9ca7a87ee844353052d09987c5d94760a39836e3f165a36577d896"
  license "MIT"

  depends_on "node@20"

  def install
    # Install workspace dependencies. better-sqlite3 needs native compilation,
    # so we don't pass --ignore-scripts.
    system "npm", "install", "--no-audit", "--no-fund"

    # Build core (LLM client + services), CLI, and the dashboard SPA.
    # The dashboard's Tauri pieces are optional deps and don't pull in the
    # Rust toolchain.
    system "npm", "run", "build", "--workspace=@fort-ai/core"
    system "npm", "run", "build", "--workspace=@fort-ai/cli"
    system "npm", "run", "build", "--workspace=@fort/dashboard"

    # Stage runtime artifacts under libexec
    libexec.install "package.json"
    libexec.install "node_modules"
    (libexec/"packages/core").install      "packages/core/dist",      "packages/core/package.json"
    (libexec/"packages/cli").install       "packages/cli/dist",       "packages/cli/package.json"
    (libexec/"packages/cli").install       "packages/cli/assets"
    (libexec/"packages/dashboard").install "packages/dashboard/dist", "packages/dashboard/package.json"

    # Wrapper pinning the formula's node@20
    (bin/"fort").write <<~SH
      #!/bin/bash
      exec "#{Formula["node@20"].opt_bin}/node" "#{libexec}/packages/cli/dist/index.js" "$@"
    SH
  end

  def caveats
    <<~EOS
      To authenticate Fort with Claude (Pro/Team/Max subscription):
        fort llm setup

      Or with OpenAI (ChatGPT Plus/Pro/Team via Codex CLI):
        fort llm setup --openai

      First-run setup: fort init
    EOS
  end

  test do
    assert_match "fort", shell_output("#{bin}/fort --help 2>&1")
  end
end
