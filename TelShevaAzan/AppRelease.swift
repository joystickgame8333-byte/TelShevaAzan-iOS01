import Foundation

struct AppRelease: Decodable, Identifiable {
    struct Asset: Decodable {
        let name: String
        let state: String
        let size: Int
        let browser_download_url: URL
    }

    let id: Int
    let tag_name: String
    let body: String?
    let draft: Bool
    let prerelease: Bool
    let assets: [Asset]

    // Release tags carry both numbers: v0.7.2-b196.
    var version: String? {
        let parts = tag_name.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2, parts[0].hasPrefix("v"),
              parts[1].hasPrefix("b"), build != nil else { return nil }
        let value = String(parts[0].dropFirst())
        let numbers = value.split(separator: ".", omittingEmptySubsequences: false)
        guard numbers.count == 3, numbers.allSatisfy({ Int($0).map { $0 >= 0 } == true }) else { return nil }
        return value
    }

    var build: Int? {
        let parts = tag_name.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2, parts[1].hasPrefix("b"),
              let number = Int(parts[1].dropFirst()), number > 0 else { return nil }
        return number
    }

    var downloadURL: URL? {
        guard !draft, !prerelease, version != nil else { return nil }
        return assets.first { asset in
            let url = asset.browser_download_url
            return asset.name == "TelShevaAzan-unsigned.ipa" && asset.state == "uploaded"
                && asset.size > 0 && url.scheme == "https" && url.host == "github.com"
                && url.path.hasPrefix("/joystickgame8333-byte/TelShevaAzan-iOS01/releases/download/\(tag_name)/")
                && url.lastPathComponent == asset.name
        }?.browser_download_url
    }

    func isNewer(than installedVersion: String, build installedBuild: String) -> Bool {
        guard let version, let build, let currentBuild = Int(installedBuild), downloadURL != nil else { return false }
        let comparison = version.compare(installedVersion, options: .numeric)
        return comparison == .orderedDescending || (comparison == .orderedSame && build > currentBuild)
    }

    var installationURL: URL? {
        guard let downloadURL else { return nil }
        var components = URLComponents()
        components.scheme = "apple-magnifier"
        components.host = "install"
        components.queryItems = [URLQueryItem(name: "url", value: downloadURL.absoluteString)]
        return components.url
    }
}
