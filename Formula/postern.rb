# Source-of-truth for the Postern Homebrew formula (copied to tobsai/homebrew-tap
# as Formula/postern.rb at release; see docs/release.md).
#
# The source repo (tobsai/postern) is PRIVATE, so we don't build from source in
# the formula. Instead we publish a prebuilt, self-contained CLI bundle (dist +
# the Python adapter assets + node_modules) as a PUBLIC release asset on the tap
# repo, and the formula just downloads + installs it. No token, no build toolchain.
# The bundle contains no secrets (the Desktop OAuth secret is read from env at
# runtime). Bump `url`/`sha256`/`version` per release.
class Postern < Formula
  desc "Register a machine-hosted Hermes agent with Postern (Google-account relay)"
  homepage "https://github.com/tobsai/postern"
  url "https://github.com/tobsai/homebrew-tap/releases/download/postern-0.1.2/postern-cli-0.1.2.tar.gz"
  sha256 "708b63f5245d5220eea8e449f0487dfe79886295bb0f9cd49f1ef140775217a4"
  version "0.1.2"
  license "MIT"

  depends_on "node"

  def install
    libexec.install Dir["*"]
    (bin/"postern").write <<~SH
      #!/bin/bash
      exec "#{Formula["node"].opt_bin}/node" "#{libexec}/dist/index.js" "$@"
    SH
  end

  def caveats
    <<~EOS
      Bind this machine's Hermes agent to your Postern account:
        POSTERN_GOOGLE_CLIENT_SECRET=<desktop-oauth-secret> postern register
      (defaults --cloud to https://postern-production.up.railway.app)
      Then restart Hermes to load the Postern platform. Manage with:
        postern status      # show the binding + adapter install
        postern logout      # remove the binding + adapter
    EOS
  end

  test do
    assert_match "0.1.2", shell_output("#{bin}/postern --version")
  end
end
