cask "agent-portal" do
  version "1.0.1"
  sha256 "cfe07a63afbaad7464ccd88f9f1467a31c7d06d6d45ea378284e049a2ba1c918"

  url "https://github.com/tobsai/agent-portal-desktop/releases/download/v#{version}/Lewis-1.0.0.dmg"
  name "Agent Portal"
  desc "Agent Portal — Desktop Chat for macOS"
  homepage "https://talos.mtree.io"

  depends_on macos: ">= :ventura"
  depends_on arch: :arm64

  app "Lewis.app"

  zap trash: [
    "~/Library/Application Support/Lewis",
    "~/Library/Preferences/com.electron.lewis-desktop.plist",
    "~/Library/Caches/Lewis",
  ]
end
