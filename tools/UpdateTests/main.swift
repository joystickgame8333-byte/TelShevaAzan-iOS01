import Foundation

func release(tag: String = "v0.7.2-b196", draft: Bool = false, prerelease: Bool = false,
             asset: String = "TelShevaAzan-unsigned.ipa", host: String = "github.com", size: Int = 100) throws -> AppRelease {
    let object: [String: Any] = [
        "id": 1, "tag_name": tag, "body": "test", "draft": draft, "prerelease": prerelease,
        "assets": [["name": asset, "state": "uploaded", "size": size,
                    "browser_download_url": "https://\(host)/joystickgame8333-byte/TelShevaAzan-iOS01/releases/download/\(tag)/\(asset)"]]
    ]
    return try JSONDecoder().decode(AppRelease.self, from: JSONSerialization.data(withJSONObject: object))
}

func expect(_ value: Bool, _ message: String) {
    if !value { fatalError(message) }
}

let next = try release()
expect(next.isNewer(than: "0.7.1", build: "195"), "New version must be offered")
expect(!next.isNewer(than: "0.7.2", build: "196"), "Installed release must not be offered")
expect(!next.isNewer(than: "0.8.0", build: "200"), "Do not offer a downgrade")
expect(next.isNewer(than: "0.7.2", build: "195"), "Same version with higher build is an update")
expect(try release(tag: "v0.7.10-b210").isNewer(than: "0.7.9", build: "209"), "Compare version components numerically")
expect(try release(draft: true).downloadURL == nil, "Drafts must not be offered")
expect(try release(prerelease: true).downloadURL == nil, "Prereleases must not be offered")
expect(try release(asset: "source.zip").downloadURL == nil, "Source archives are not an installable IPA")
expect(try release(size: 0).downloadURL == nil, "Empty files must not be offered")
expect(try release(host: "example.com").downloadURL == nil, "Only the configured repository download is trusted")
expect(try release(tag: "v0.7.2").downloadURL == nil, "Incomplete tags must not be offered")
expect(try release(tag: "v0.7.2-b0").downloadURL == nil, "Invalid build must not be offered")
let installComponents = URLComponents(url: next.installationURL!, resolvingAgainstBaseURL: false)!
expect(installComponents.scheme == "apple-magnifier" && installComponents.host == "install", "Use the documented TrollStore installation route")
expect(installComponents.queryItems?.first(where: { $0.name == "url" })?.value == next.downloadURL?.absoluteString, "Installer must receive the exact validated IPA URL")
expect(try release(draft: true).installationURL == nil, "Do not hand an unpublished IPA to the installer")
expect(try release(host: "example.com").installationURL == nil, "Reject untrusted installation links")
print("App update release tests passed (16 checks)")
