class Fort < Formula
  desc "Self-improving personal AI agent platform"
  homepage "https://github.com/tobsai/fort"
  url "https://github.com/tobsai/fort/archive/refs/tags/v0.2.3.tar.gz"
  sha256 "e6e21c0a5bd63d67903c1aeb2f4f3dd6c9fff80075d55650b4f91e4689e12f82"
  license "MIT"

  depends_on "node@20"

  def install
    # Install workspace dependencies. better-sqlite3 needs native compilation,
    # so we don't pass --ignore-scripts.
    system "npm", "install", "--no-audit", "--no-fund"

    # Build only what the CLI needs. The dashboard workspace is a Tauri app
    # that would pull in extra toolchains; users who want it run it from a
    # checkout.
    system "npm", "run", "build", "--workspace=@fort-ai/core"
    system "npm", "run", "build", "--workspace=@fort-ai/cli"

    # Stage runtime artifacts under libexec
    libexec.install "package.json"
    libexec.install "node_modules"
    (libexec/"packages/core").install "packages/core/dist", "packages/core/package.json"
    (libexec/"packages/cli").install  "packages/cli/dist",  "packages/cli/package.json"

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
