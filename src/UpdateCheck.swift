import Foundation

/// Offer shown when GitHub latest release is newer than the running app.
struct AppUpdateOffer: Identifiable, Sendable {
  var id: String { remoteTag }
  let remoteVersion: String
  let remoteTag: String
  let releasePageURL: URL
  let dmgDownloadURL: URL?
  let localVersion: String
}

/// Result of an explicit “Check for updates” from Settings.
enum ManualUpdateCheckOutcome: Sendable {
  /// Latest GitHub release is not newer than this build.
  case upToDate(latestVersion: String)
  /// A newer release exists (`respectSkipPreference` ignored for this path).
  case updateAvailable(AppUpdateOffer)
  /// Network error or unexpected API response.
  case failed
}

/// Silent check against `GET /repos/.../releases/latest` (no Sparkle).
enum UpdateCheck {
  private static let githubLatestAPI = URL(
    string: "https://api.github.com/repos/PattanasakGit/Paenia/releases/latest"
  )!
  private static let skippedTagKey = "PaeniaUpdateSkippedReleaseTag"

  static func skippedReleaseTag() -> String? {
    UserDefaults.standard.string(forKey: skippedTagKey)
  }

  static func skipReleaseTag(_ tag: String) {
    UserDefaults.standard.set(tag, forKey: skippedTagKey)
  }

  /// `remote` / `local` may include a leading `v` or pre-release suffix; numeric semver prefix is compared.
  static func versionIsNewer(remote: String, thanLocal local: String) -> Bool {
    let rParts = numericVersionParts(normalizeVersion(remote))
    let lParts = numericVersionParts(normalizeVersion(local))
    let n = max(rParts.count, lParts.count)
    for i in 0..<n {
      let a = i < rParts.count ? rParts[i] : 0
      let b = i < lParts.count ? lParts[i] : 0
      if a != b { return a > b }
    }
    return false
  }

  private static func normalizeVersion(_ s: String) -> String {
    var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
    if t.hasPrefix("v") || t.hasPrefix("V") { t.removeFirst() }
    if let dash = t.firstIndex(of: "-") {
      t = String(t[..<dash])
    }
    if let plus = t.firstIndex(of: "+") {
      t = String(t[..<plus])
    }
    return t
  }

  private static func numericVersionParts(_ s: String) -> [Int] {
    s.split(separator: ".").map { Int($0) ?? 0 }
  }

  private static func makeRequest() -> URLRequest {
    let local = AppInfo.version
    var request = URLRequest(url: githubLatestAPI)
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("Paenia/\(local) (macOS)", forHTTPHeaderField: "User-Agent")
    request.timeoutInterval = 22
    return request
  }

  /// Parsed `releases/latest` payload.
  private static func parseReleaseJSON(_ data: Data) -> (tagName: String, remoteVersion: String, pageURL: URL, dmgURL: URL?)? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let tagName = json["tag_name"] as? String,
          let htmlUrlString = json["html_url"] as? String,
          let pageURL = URL(string: htmlUrlString) else {
      return nil
    }
    let remoteVersion = normalizeVersion(tagName)
    var dmgURL: URL?
    if let assets = json["assets"] as? [[String: Any]] {
      for a in assets {
        guard let name = a["name"] as? String, name.hasSuffix(".dmg"),
              let urlStr = a["browser_download_url"] as? String,
              let u = URL(string: urlStr) else { continue }
        dmgURL = u
        break
      }
    }
    return (tagName, remoteVersion, pageURL, dmgURL)
  }

  private static func fetchLatestRelease() async -> (tagName: String, remoteVersion: String, pageURL: URL, dmgURL: URL?)? {
    let request = makeRequest()
    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await URLSession.shared.data(for: request)
    } catch {
      return nil
    }
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
      return nil
    }
    return parseReleaseJSON(data)
  }

  private static func offer(from parsed: (tagName: String, remoteVersion: String, pageURL: URL, dmgURL: URL?)) -> AppUpdateOffer {
    AppUpdateOffer(
      remoteVersion: parsed.remoteVersion,
      remoteTag: parsed.tagName,
      releasePageURL: parsed.pageURL,
      dmgDownloadURL: parsed.dmgURL,
      localVersion: AppInfo.version
    )
  }

  /// Fetches latest release; returns an offer only when remote is newer than `AppInfo.version` and the user
  /// has not chosen “don’t remind” for that release tag.
  static func fetchUpdateOfferIfNeeded() async -> AppUpdateOffer? {
    let local = AppInfo.version
    guard let parsed = await fetchLatestRelease() else { return nil }
    if !versionIsNewer(remote: parsed.remoteVersion, thanLocal: local) {
      return nil
    }
    if let skipped = skippedReleaseTag(), skipped == parsed.tagName {
      return nil
    }
    return offer(from: parsed)
  }

  /// Explicit check from Settings: always hits the network; ignores “don’t remind” so the user can see the offer again.
  static func manualCheck() async -> ManualUpdateCheckOutcome {
    let local = AppInfo.version
    guard let parsed = await fetchLatestRelease() else {
      return .failed
    }
    if versionIsNewer(remote: parsed.remoteVersion, thanLocal: local) {
      return .updateAvailable(offer(from: parsed))
    }
    return .upToDate(latestVersion: parsed.remoteVersion)
  }
}
