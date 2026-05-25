class Postern < Formula
  desc "Register a machine-hosted Hermes agent with Postern (Google-account relay)"
  homepage "https://github.com/tobsai/postern"
  url "https://github.com/tobsai/homebrew-tap/releases/download/postern-0.1.0/postern-cli-0.1.0.tar.gz"
  sha256 "e9ba378b4f79bfe47b4f7eff3488a81d5d34156b6589a796425480c87c97afd4"
  version "0.1.0"
  license "MIT"

  # Prebuilt, self-contained CLI bundle (dist + the Python adapter assets +
  # node_modules). The source repo (tobsai/postern) is private; this artifact is
  # the public install path, so no build-from-source / token is needed.
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
    assert_match "0.1.0", shell_output("#{bin}/postern --version")
  end
end
