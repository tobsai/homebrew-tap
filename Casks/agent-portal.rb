cask "agent-portal" do
  version "1.0.2"
  sha256 "2acc00e68d5d2b7091bda27f315e330db258b24b63c23627ff84f2be900cef14"

  url "https://github.com/tobsai/agent-portal-desktop/releases/download/v#{version}/Lewis-#{version}.dmg"
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
