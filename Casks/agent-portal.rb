cask "agent-portal" do
  version "1.0.0"
  sha256 "5ead7b3a6ddb71389b7703cc02f169996d918cc7e65ec0ee6f6d0223b2c7a685"

  url "https://github.com/tobsai/agent-portal-desktop/releases/download/v#{version}/Lewis-#{version}.dmg"
  name "Lewis"
  desc "Lewis Agent Portal — Desktop Chat for macOS"
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
