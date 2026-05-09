import SwiftUI
import AppKit

let appSupportRoot = FileManager.default.homeDirectoryForCurrentUser
  .appendingPathComponent("Library/Application Support")
/// Legacy support directory from before the rebrand. Migrated to `studioDir`
/// on first launch (see `migrateLegacyStudioDirIfNeeded()`).
private let legacyStudioDir = appSupportRoot.appendingPathComponent("Workbench Theme Studio")
let studioDir = appSupportRoot.appendingPathComponent("Paenia")
let themeURL = studioDir.appendingPathComponent("theme.json")
let backupsRoot = studioDir.appendingPathComponent("Backups")

/// Protected "factory" snapshot — settings.json captured the FIRST time the
/// app sees a target's file. Lets the user always roll back to a pristine
/// pre-app state regardless of how many times they've Applied themes.
/// Files here are intentionally not exposed to the regular Backup Management
/// delete UI; users must remove them manually if they truly want to.
let originalBackupsRoot = studioDir.appendingPathComponent("OriginalBackups")

/// Path where the original snapshot for a given source settings.json lives.
/// Mirrors the regular `backupsDirectory(for:)` encoding for parity.
func originalBackupURL(for sourceURL: URL) -> URL {
  originalBackupsRoot
    .appendingPathComponent(backupFolderName(for: sourceURL))
    .appendingPathComponent(sourceURL.lastPathComponent)
}

/// Static, read-once metadata about the current app bundle. Used by the
/// About pane in Preferences and any place we want to surface version /
/// system info to the user. All values come from the bundle's Info.plist
/// so they stay in sync with the build automatically.
enum AppInfo {
  static let name: String = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
    ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
    ?? "Paenia"

  static let version: String = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
    ?? "1.0.0"

  static let build: String = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
    ?? "1"

  static let bundleID: String = Bundle.main.bundleIdentifier ?? "app.paenia"

  static let copyright: String = (Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String)
    ?? "© Paenia"

  static let systemVersion: String = {
    let v = ProcessInfo.processInfo.operatingSystemVersion
    return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
  }()

  /// Short MIT license snippet shown in About → License so the user can
  /// see the redistribution terms without leaving the app.
  static let licenseSnippet: String = """
  Permission is hereby granted, free of charge, to any person obtaining a copy of this \
  software and associated documentation files (the "Software"), to deal in the Software \
  without restriction, including without limitation the rights to use, copy, modify, \
  merge, publish, distribute, sublicense, and/or sell copies of the Software.
  """
}

/// Stable, filesystem-safe folder name keyed by absolute source path.
/// Backups for `<X>/settings.json` go under `Backups/<encoded-path>/` so we
/// never clutter the editor's own User folder.
func backupFolderName(for sourceURL: URL) -> String {
  let path = sourceURL.standardizedFileURL.path
  let b64 = Data(path.utf8).base64EncodedString()
    .replacingOccurrences(of: "+", with: "-")
    .replacingOccurrences(of: "/", with: "_")
    .replacingOccurrences(of: "=", with: "")
  return b64
}

func backupsDirectory(for sourceURL: URL) -> URL {
  backupsRoot.appendingPathComponent(backupFolderName(for: sourceURL))
}

enum DetectionStatus: String {
  case ready = "พร้อม"
  case willCreate = "พร้อมสร้าง"
  case installedOnly = "ติดตั้งแล้ว"
  case notFound = "ไม่พร้อม"

  var icon: String {
    switch self {
    case .ready: return "checkmark.seal.fill"
    case .willCreate: return "plus.circle.fill"
    case .installedOnly: return "circle.dotted"
    case .notFound: return "xmark.circle"
    }
  }
}

struct EditorTarget: Identifiable, Hashable {
  let id: String
  var name: String
  let appSupportName: String
  let bundleID: String?
  let supportLevel: String
  var pathOverride: String? = nil
  var isCustom: Bool = false

  var defaultSettingsPath: String {
    appSupportRoot
      .appendingPathComponent(appSupportName)
      .appendingPathComponent("User")
      .appendingPathComponent("settings.json")
      .path
  }

  var settingsURL: URL {
    URL(fileURLWithPath: pathOverride ?? defaultSettingsPath)
  }

  var userDir: URL {
    settingsURL.deletingLastPathComponent()
  }

  var detectionStatus: DetectionStatus {
    let fm = FileManager.default
    if fm.fileExists(atPath: settingsURL.path) {
      return .ready
    }
    if fm.fileExists(atPath: userDir.path) {
      return .willCreate
    }
    if let id = bundleID,
       NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) != nil {
      return .installedOnly
    }
    return .notFound
  }

  var isDetected: Bool {
    let status = detectionStatus
    return status == .ready || status == .willCreate || status == .installedOnly
  }
}

let builtInTargets: [EditorTarget] = [
  EditorTarget(id: "cursor", name: "Cursor", appSupportName: "Cursor", bundleID: "com.todesktop.230313mzl4w4u92", supportLevel: "Detected"),
  EditorTarget(id: "vscode", name: "Visual Studio Code", appSupportName: "Code", bundleID: "com.microsoft.VSCode", supportLevel: "Official"),
  EditorTarget(id: "antigravity", name: "Antigravity", appSupportName: "Antigravity", bundleID: "com.google.antigravity", supportLevel: "VS Code-family"),
  EditorTarget(id: "trae", name: "Trae", appSupportName: "Trae", bundleID: "com.trae.app", supportLevel: "VS Code-family"),
  EditorTarget(id: "windsurf", name: "Windsurf", appSupportName: "Windsurf", bundleID: nil, supportLevel: "VS Code-family"),
  EditorTarget(id: "vscodium", name: "VSCodium", appSupportName: "VSCodium", bundleID: "com.vscodium", supportLevel: "VS Code-family"),
  EditorTarget(id: "kiro", name: "Kiro", appSupportName: "Kiro", bundleID: nil, supportLevel: "VS Code-family"),
  EditorTarget(id: "positron", name: "Positron", appSupportName: "Positron", bundleID: nil, supportLevel: "VS Code-family"),
  EditorTarget(id: "code-oss", name: "Code - OSS", appSupportName: "Code - OSS", bundleID: nil, supportLevel: "VS Code-family")
]

// MARK: - Path Validator

enum PathValidation {
  case ok
  case warning(String)
  case blocked(String)
}

enum PathValidator {
  static let dangerousRoots = ["/System/", "/usr/", "/private/var/", "/Library/", "/bin/", "/sbin/"]

  static func validate(_ path: String) -> PathValidation {
    let normalized = (path as NSString).standardizingPath

    // Hard blocks
    for root in dangerousRoots where normalized.hasPrefix(root) {
      return .blocked("Path อยู่ใน system area (\(root)) — ไม่อนุญาตเพื่อความปลอดภัย")
    }
    if normalized.contains(".app/") || normalized.contains(".bundle/") || normalized.contains(".framework/") {
      return .blocked("ห้ามเขียนใน app bundle / framework")
    }

    let url = URL(fileURLWithPath: normalized)
    let lowercased = normalized.lowercased()

    // Soft warnings
    if !lowercased.hasSuffix(".json") && !lowercased.hasSuffix(".jsonc") {
      return .warning("Path ไม่ได้ลงท้ายด้วย .json หรือ .jsonc — แน่ใจไหม?")
    }

    let fm = FileManager.default
    if fm.fileExists(atPath: normalized) {
      guard let data = try? Data(contentsOf: url) else {
        return .warning("เปิดไฟล์ไม่ได้ อาจไม่มีสิทธิ์อ่าน")
      }
      if data.count > 1_000_000 {
        return .warning("ไฟล์ใหญ่ผิดปกติ (>1MB) — ใช่ settings.json จริงไหม?")
      }
      if let raw = String(data: data, encoding: .utf8), !raw.contains("workbench") && !raw.isEmpty {
        return .warning("ไฟล์ไม่มี \"workbench.*\" — ไม่เหมือน settings.json ของ VS Code-family")
      }
    } else {
      return .warning("ไฟล์ยังไม่มี — Apply จะสร้างใหม่")
    }

    if !normalized.hasSuffix("User/settings.json") {
      return .warning("Path ไม่ตรงรูปแบบ \".../User/settings.json\" — ตั้งใจหรือเปล่า?")
    }

    return .ok
  }
}

struct ThemePreset: Identifiable, Hashable {
  let id: String
  let colors: [String: String]

  /// True when bg0 luminance is high enough to be a light theme.
  /// Result is cached per-id at module load (see `darkPresetIDs` / `lightPresetIDs`)
  /// so the hot path on every render is a Set lookup, not a hex-parse + math.
  var isLight: Bool {
    if let cached = lightPresetIDs[id] { return cached }
    return computeIsLight()
  }

  fileprivate func computeIsLight() -> Bool {
    let raw = (colors["bg0"] ?? "#000000")
    let nsc = nsColor(from: raw)
    let r = Double(nsc.redComponent)
    let g = Double(nsc.greenComponent)
    let b = Double(nsc.blueComponent)
    let luminance = 0.299 * r + 0.587 * g + 0.114 * b
    return luminance > 0.5
  }
}

struct ColorMeta {
  let title: String
  let subtitle: String
}

struct ColorCategory: Identifiable, Hashable {
  let id: String
  let title: String
  let subtitle: String
  let symbol: String
  let keys: [String]
}

enum EditorMode: String, CaseIterable, Identifiable {
  case base = "Base Palette"
  case detailed = "Detailed Colors"

  var id: String { rawValue }

  var icon: String {
    switch self {
    case .base: return "paintpalette.fill"
    case .detailed: return "slider.horizontal.3"
    }
  }

  var shortLabel: String {
    switch self {
    case .base: return "Palette"
    case .detailed: return "Detailed"
    }
  }
}

let colorMeta: [String: ColorMeta] = [
  "bg0": ColorMeta(title: "Editor Background", subtitle: "พื้นหลังหลักของ editor และพื้นที่เขียนโค้ด"),
  "bg1": ColorMeta(title: "Sidebar & Panels", subtitle: "พื้นหลัง sidebar, terminal panel และ secondary panel"),
  "bg2": ColorMeta(title: "Inputs & Popups", subtitle: "ช่องกรอก, dropdown, quick input และ widget"),
  "bg3": ColorMeta(title: "Inactive Selection", subtitle: "พื้นหลัง selection ที่ไม่ active และ tab รอง"),
  "bg4": ColorMeta(title: "Active Selection", subtitle: "selection ที่ active, hover และ focused row"),
  "fg0": ColorMeta(title: "Primary Text", subtitle: "ตัวอักษรหลักที่ต้องอ่านชัดที่สุด"),
  "fg1": ColorMeta(title: "Secondary Text", subtitle: "ตัวอักษรรอง เช่น terminal และ property"),
  "fg2": ColorMeta(title: "Muted Headings", subtitle: "หัวข้อ section, hints และ punctuation"),
  "muted": ColorMeta(title: "Comments", subtitle: "สี comment ใน editor"),
  "muted2": ColorMeta(title: "Disabled / Ignored", subtitle: "สีสถานะจาง เช่น ignored files และ line number"),
  "border": ColorMeta(title: "Main Border", subtitle: "เส้นแบ่ง panel, sidebar, title bar และ input border"),
  "accent": ColorMeta(title: "Primary Accent", subtitle: "สีหลักของ activity indicator, focus และ cursor"),
  "accentSoft": ColorMeta(title: "Hover Accent", subtitle: "สี accent แบบนุ่มสำหรับ hover และ active foreground"),
  "blue": ColorMeta(title: "Links & Functions", subtitle: "link, function name และ HTML tag"),
  "green": ColorMeta(title: "Strings / Added", subtitle: "string ใน code และไฟล์ที่เพิ่มใหม่"),
  "red": ColorMeta(title: "Errors / Deleted", subtitle: "error, deleted files และ keyword สำคัญ"),
  "purple": ColorMeta(title: "Types / Numbers", subtitle: "type, class, number และ conflict status"),
  "transparent": ColorMeta(title: "Transparent Border", subtitle: "ค่า alpha สำหรับ border ที่ต้องซ่อน"),
  "overlayLow": ColorMeta(title: "Line Highlight", subtitle: "overlay จางสำหรับบรรทัดที่ active"),
  "overlayMid": ColorMeta(title: "Scrollbar Base", subtitle: "สี scrollbar ตอนปกติ"),
  "overlayHigh": ColorMeta(title: "Scrollbar Hover", subtitle: "สี scrollbar ตอน hover"),
  "overlayActive": ColorMeta(title: "Scrollbar Active", subtitle: "สี scrollbar ตอนลากหรือ active")
]

let baseCategories: [ColorCategory] = [
  ColorCategory(id: "surfaces", title: "Surfaces", subtitle: "พื้นหลังและพื้นที่หลัก", symbol: "rectangle.3.group", keys: ["bg0", "bg1", "bg2", "bg3", "bg4"]),
  ColorCategory(id: "text", title: "Text", subtitle: "ตัวอักษรและความอ่านง่าย", symbol: "textformat.size", keys: ["fg0", "fg1", "fg2", "muted", "muted2"]),
  ColorCategory(id: "accent", title: "Accent & Interaction", subtitle: "focus, hover, link และ border", symbol: "cursorarrow.click.2", keys: ["accent", "accentSoft", "border", "blue"]),
  ColorCategory(id: "syntax", title: "Syntax Colors", subtitle: "สี token ใน editor", symbol: "curlybraces", keys: ["green", "red", "purple", "blue", "accent", "fg1"]),
  ColorCategory(id: "git", title: "Git & State", subtitle: "modified, added, deleted และ conflict", symbol: "point.3.connected.trianglepath.dotted", keys: ["green", "red", "purple", "accent", "muted2"]),
  ColorCategory(id: "overlays", title: "Transparency", subtitle: "overlay และ alpha states", symbol: "square.stack.3d.up", keys: ["transparent", "overlayLow", "overlayMid", "overlayHigh", "overlayActive"])
]

let presets: [ThemePreset] = [
  // ── Minimal Showcase · Earth Tone ────────────────────────────
  // Curated palettes built around earth-tone surfaces (umber, sienna,
  // ochre, sage, clay, parchment). Each preset is hand-tuned across all
  // 5 surface levels + foreground ramp + accents so contrast feels even
  // and syntax colors melt into the surface instead of fighting it.
  //
  // Design guardrails for every Minimal preset:
  //   • bg0 → bg4 ramp uses a single warm hue family, no cool gray jumps
  //   • fg0 ≠ pure white / pure black — soft to reduce eye strain
  //   • accent saturated only just enough to read at body-text size
  //   • syntax (blue/green/red/purple) shifted to muted earth siblings

  // ── Earth · Dark ────
  ThemePreset(id: "Sumi Ink", colors: [
    "bg0": "#13110F", "bg1": "#0E0C0B", "bg2": "#1B1815", "bg3": "#26221E", "bg4": "#332E27",
    "fg0": "#ECE3D2", "fg1": "#B5A993", "fg2": "#8C8273", "muted": "#6A6256", "muted2": "#463F36",
    "border": "#2A2520", "accent": "#C9A76E", "accentSoft": "#DEC498", "blue": "#7390A8",
    "green": "#8AA677", "red": "#BB6F62", "purple": "#9C7C9B"
  ]),
  ThemePreset(id: "Terracotta", colors: [
    "bg0": "#1A1311", "bg1": "#150F0D", "bg2": "#221915", "bg3": "#2E231D", "bg4": "#3D2F26",
    "fg0": "#F0E2D2", "fg1": "#BFAA94", "fg2": "#968372", "muted": "#6F5F52", "muted2": "#4A3F35",
    "border": "#2C2018", "accent": "#C26B4A", "accentSoft": "#DA9272", "blue": "#6F8AA0",
    "green": "#8FA67A", "red": "#C26B4A", "purple": "#9F778F"
  ]),
  ThemePreset(id: "Moss Stone", colors: [
    "bg0": "#141815", "bg1": "#0F1310", "bg2": "#1C211D", "bg3": "#272E27", "bg4": "#353D34",
    "fg0": "#E2E7DD", "fg1": "#B0B6AA", "fg2": "#868D7F", "muted": "#61685B", "muted2": "#404640",
    "border": "#232924", "accent": "#8FAA80", "accentSoft": "#B5C9A8", "blue": "#7993A5",
    "green": "#8FAA80", "red": "#BD7B72", "purple": "#9989A7"
  ]),
  ThemePreset(id: "Cedar", colors: [
    "bg0": "#1A1612", "bg1": "#14110E", "bg2": "#221C16", "bg3": "#2E261E", "bg4": "#3D3327",
    "fg0": "#EDE0CE", "fg1": "#B9A78D", "fg2": "#8E7E68", "muted": "#685A48", "muted2": "#443A2D",
    "border": "#2A2218", "accent": "#B07952", "accentSoft": "#CB9A77", "blue": "#6F8AA0",
    "green": "#8B9F76", "red": "#B26F58", "purple": "#94768F"
  ]),
  ThemePreset(id: "Dune", colors: [
    "bg0": "#1B1813", "bg1": "#15130F", "bg2": "#221F18", "bg3": "#2E2A21", "bg4": "#3D372B",
    "fg0": "#EFE5D0", "fg1": "#BCAE91", "fg2": "#908370", "muted": "#6A5F50", "muted2": "#463E33",
    "border": "#2B251C", "accent": "#C8A368", "accentSoft": "#DBC18C", "blue": "#738BA0",
    "green": "#8DA478", "red": "#BB7259", "purple": "#97798E"
  ]),
  ThemePreset(id: "Espresso", colors: [
    "bg0": "#16100B", "bg1": "#110C08", "bg2": "#1F1610", "bg3": "#2A1E16", "bg4": "#38291D",
    "fg0": "#EBDEC8", "fg1": "#B9A689", "fg2": "#8E7E66", "muted": "#695A47", "muted2": "#443A2C",
    "border": "#28201A", "accent": "#D9BB91", "accentSoft": "#E7D2AE", "blue": "#6E879D",
    "green": "#8C9F76", "red": "#B07058", "purple": "#93768D"
  ]),
  ThemePreset(id: "Rust Iron", colors: [
    "bg0": "#15110D", "bg1": "#110D0A", "bg2": "#1F1814", "bg3": "#2A2018", "bg4": "#382B1F",
    "fg0": "#ECDFCA", "fg1": "#B9A88B", "fg2": "#8E7F69", "muted": "#685B49", "muted2": "#443A2D",
    "border": "#281F18", "accent": "#B65A2C", "accentSoft": "#D38157", "blue": "#6F889E",
    "green": "#8B9F76", "red": "#B65A2C", "purple": "#94768F"
  ]),
  ThemePreset(id: "Olive Grove", colors: [
    "bg0": "#16170F", "bg1": "#11120B", "bg2": "#1F2118", "bg3": "#2A2D21", "bg4": "#383C2C",
    "fg0": "#ECE7CD", "fg1": "#B9B391", "fg2": "#8E8A6B", "muted": "#67654E", "muted2": "#454432",
    "border": "#28291D", "accent": "#A0A05A", "accentSoft": "#C4C383", "blue": "#788C9D",
    "green": "#A0A05A", "red": "#B36F4E", "purple": "#95778A"
  ]),

  // ── Earth · Light ────
  ThemePreset(id: "Linen", colors: [
    "bg0": "#F2EBE0", "bg1": "#F8F2E7", "bg2": "#EAE2D3", "bg3": "#DCD2BE", "bg4": "#C4B89E",
    "fg0": "#2A2218", "fg1": "#574B3A", "fg2": "#847762", "muted": "#ABA08A", "muted2": "#C8BFA9",
    "border": "#DAD1BD", "accent": "#8B7355", "accentSoft": "#B0987C", "blue": "#5E7A93",
    "green": "#6F8B5D", "red": "#A1554B", "purple": "#826F89"
  ]),
  ThemePreset(id: "Parchment", colors: [
    "bg0": "#F5EDD8", "bg1": "#FAF4E2", "bg2": "#ECE3CB", "bg3": "#DED3B7", "bg4": "#C8BC9C",
    "fg0": "#2D2415", "fg1": "#5A4D33", "fg2": "#87775B", "muted": "#A89A7E", "muted2": "#C8BCA1",
    "border": "#DCD0B5", "accent": "#6B4F2C", "accentSoft": "#957654", "blue": "#5E748A",
    "green": "#6E8757", "red": "#9B5141", "purple": "#815F7A"
  ]),
  ThemePreset(id: "Sage Garden", colors: [
    "bg0": "#ECF1E8", "bg1": "#F4F8F0", "bg2": "#E3EADD", "bg3": "#D2DBCA", "bg4": "#B6C4AB",
    "fg0": "#1F2A1B", "fg1": "#4A5942", "fg2": "#768470", "muted": "#9CAA94", "muted2": "#BFC9B8",
    "border": "#D1DACA", "accent": "#5B7B5A", "accentSoft": "#82A381", "blue": "#5E7A93",
    "green": "#5B7B5A", "red": "#9F574A", "purple": "#7B6E8A"
  ]),
  ThemePreset(id: "Adobe", colors: [
    "bg0": "#F5E8DC", "bg1": "#FAEFE2", "bg2": "#EDDFCF", "bg3": "#DECDB8", "bg4": "#C4B193",
    "fg0": "#2D1F12", "fg1": "#5A452F", "fg2": "#87694B", "muted": "#A8896B", "muted2": "#C7AC8E",
    "border": "#DDC9AF", "accent": "#B45838", "accentSoft": "#D38461", "blue": "#5E7A93",
    "green": "#6E8757", "red": "#B45838", "purple": "#845F7A"
  ]),
  ThemePreset(id: "Stone", colors: [
    "bg0": "#EFE9E0", "bg1": "#F5EFE6", "bg2": "#E5DED2", "bg3": "#D3CCBE", "bg4": "#B9B19F",
    "fg0": "#2A241C", "fg1": "#564E40", "fg2": "#837866", "muted": "#A6997F", "muted2": "#C4B89C",
    "border": "#D6CDBC", "accent": "#5A4938", "accentSoft": "#836C53", "blue": "#5E748A",
    "green": "#6E8757", "red": "#9F5141", "purple": "#7B5F6E"
  ]),
  ThemePreset(id: "Wheat", colors: [
    "bg0": "#F4ECD8", "bg1": "#FAF3E1", "bg2": "#EAE0C7", "bg3": "#DACFB1", "bg4": "#BFB28C",
    "fg0": "#2C2415", "fg1": "#574A2E", "fg2": "#847555", "muted": "#A89776", "muted2": "#C5B697",
    "border": "#D9CDAD", "accent": "#9C6E32", "accentSoft": "#C29355", "blue": "#5E748A",
    "green": "#7A8949", "red": "#9C5238", "purple": "#7E5E73"
  ]),

  // ── Signature ────────────────────────────────────────────────
  ThemePreset(id: "Cyber Violet", colors: [
    "bg0": "#08060F", "bg1": "#100B1F", "bg2": "#17102A", "bg3": "#241642", "bg4": "#34205F",
    "fg0": "#FFF7FF", "fg1": "#E9D7FF", "fg2": "#B79CFF", "muted": "#7C6A99", "muted2": "#534566",
    "border": "#9D4EDD", "accent": "#FF4FD8", "accentSoft": "#FF9BE8", "blue": "#00D4FF",
    "green": "#5CFF95", "red": "#FF3864", "purple": "#C77DFF"
  ]),
  ThemePreset(id: "Neon Dark", colors: [
    "bg0": "#05070A", "bg1": "#071018", "bg2": "#0A1620", "bg3": "#102536", "bg4": "#14354A",
    "fg0": "#F4FBFF", "fg1": "#C7E9FF", "fg2": "#7CCBFF", "muted": "#5D7A8C", "muted2": "#385363",
    "border": "#1F6FEB", "accent": "#00E5FF", "accentSoft": "#7DF9FF", "blue": "#4D7CFF",
    "green": "#64FF4A", "red": "#FF3B81", "purple": "#D946EF"
  ]),
  ThemePreset(id: "Minimal Warm", colors: [
    "bg0": "#0B0D0E", "bg1": "#0D1012", "bg2": "#111417", "bg3": "#171B1F", "bg4": "#20262B",
    "fg0": "#E6E1D9", "fg1": "#B8B2A8", "fg2": "#8D9399", "muted": "#6F767D", "muted2": "#4D555D",
    "border": "#273038", "accent": "#D9A86C", "accentSoft": "#F0C98B", "blue": "#7AA2F7",
    "green": "#9ECE6A", "red": "#F7768E", "purple": "#C099FF"
  ]),

  // ── Popular dark themes (inspired-by) ───────────────────────
  ThemePreset(id: "Dracula", colors: [
    "bg0": "#282A36", "bg1": "#21222C", "bg2": "#343746", "bg3": "#44475A", "bg4": "#6272A4",
    "fg0": "#F8F8F2", "fg1": "#E0E0DC", "fg2": "#C7C7C2", "muted": "#6272A4", "muted2": "#44475A",
    "border": "#BD93F9", "accent": "#FF79C6", "accentSoft": "#FFB8E5", "blue": "#8BE9FD",
    "green": "#50FA7B", "red": "#FF5555", "purple": "#BD93F9"
  ]),
  ThemePreset(id: "Tokyo Night", colors: [
    "bg0": "#1A1B26", "bg1": "#16161E", "bg2": "#1F2335", "bg3": "#292E42", "bg4": "#3B4261",
    "fg0": "#C0CAF5", "fg1": "#A9B1D6", "fg2": "#7AA2F7", "muted": "#565F89", "muted2": "#3B4261",
    "border": "#7AA2F7", "accent": "#7AA2F7", "accentSoft": "#9ECCFF", "blue": "#7DCFFF",
    "green": "#9ECE6A", "red": "#F7768E", "purple": "#BB9AF7"
  ]),
  ThemePreset(id: "Tokyo Storm", colors: [
    "bg0": "#24283B", "bg1": "#1F2335", "bg2": "#2A2F42", "bg3": "#343A52", "bg4": "#414868",
    "fg0": "#C0CAF5", "fg1": "#A9B1D6", "fg2": "#9AA5CE", "muted": "#565F89", "muted2": "#414868",
    "border": "#7AA2F7", "accent": "#BB9AF7", "accentSoft": "#C7B7FA", "blue": "#7DCFFF",
    "green": "#9ECE6A", "red": "#F7768E", "purple": "#BB9AF7"
  ]),
  ThemePreset(id: "One Dark", colors: [
    "bg0": "#282C34", "bg1": "#21252B", "bg2": "#2C313A", "bg3": "#3A3F4B", "bg4": "#4D5566",
    "fg0": "#ABB2BF", "fg1": "#9DA5B4", "fg2": "#828997", "muted": "#5C6370", "muted2": "#4B5263",
    "border": "#528BFF", "accent": "#61AFEF", "accentSoft": "#88C0FF", "blue": "#61AFEF",
    "green": "#98C379", "red": "#E06C75", "purple": "#C678DD"
  ]),
  ThemePreset(id: "Monokai", colors: [
    "bg0": "#272822", "bg1": "#1E1F1C", "bg2": "#2D2E27", "bg3": "#3E3D32", "bg4": "#49483E",
    "fg0": "#F8F8F2", "fg1": "#CFCFC2", "fg2": "#75715E", "muted": "#75715E", "muted2": "#49483E",
    "border": "#75715E", "accent": "#F92672", "accentSoft": "#FF6B9F", "blue": "#66D9EF",
    "green": "#A6E22E", "red": "#F92672", "purple": "#AE81FF"
  ]),
  ThemePreset(id: "Solarized Dark", colors: [
    "bg0": "#002B36", "bg1": "#073642", "bg2": "#0E4854", "bg3": "#1A5563", "bg4": "#2A6772",
    "fg0": "#FDF6E3", "fg1": "#EEE8D5", "fg2": "#93A1A1", "muted": "#586E75", "muted2": "#475C63",
    "border": "#268BD2", "accent": "#268BD2", "accentSoft": "#5DAEEC", "blue": "#268BD2",
    "green": "#859900", "red": "#DC322F", "purple": "#6C71C4"
  ]),
  ThemePreset(id: "Nord", colors: [
    "bg0": "#2E3440", "bg1": "#272B36", "bg2": "#3B4252", "bg3": "#434C5E", "bg4": "#4C566A",
    "fg0": "#ECEFF4", "fg1": "#E5E9F0", "fg2": "#D8DEE9", "muted": "#7B88A1", "muted2": "#5E6779",
    "border": "#88C0D0", "accent": "#88C0D0", "accentSoft": "#A3D2DE", "blue": "#81A1C1",
    "green": "#A3BE8C", "red": "#BF616A", "purple": "#B48EAD"
  ]),
  ThemePreset(id: "Gruvbox Dark", colors: [
    "bg0": "#282828", "bg1": "#1D2021", "bg2": "#32302F", "bg3": "#3C3836", "bg4": "#504945",
    "fg0": "#FBF1C7", "fg1": "#EBDBB2", "fg2": "#D5C4A1", "muted": "#928374", "muted2": "#665C54",
    "border": "#FE8019", "accent": "#FABD2F", "accentSoft": "#FFD777", "blue": "#83A598",
    "green": "#B8BB26", "red": "#FB4934", "purple": "#D3869B"
  ]),
  ThemePreset(id: "Catppuccin Mocha", colors: [
    "bg0": "#1E1E2E", "bg1": "#181825", "bg2": "#313244", "bg3": "#45475A", "bg4": "#585B70",
    "fg0": "#CDD6F4", "fg1": "#BAC2DE", "fg2": "#A6ADC8", "muted": "#7F849C", "muted2": "#6C7086",
    "border": "#CBA6F7", "accent": "#F5C2E7", "accentSoft": "#F5D6E9", "blue": "#89B4FA",
    "green": "#A6E3A1", "red": "#F38BA8", "purple": "#CBA6F7"
  ]),
  ThemePreset(id: "Catppuccin Macchiato", colors: [
    "bg0": "#24273A", "bg1": "#1E2030", "bg2": "#363A4F", "bg3": "#494D64", "bg4": "#5B6078",
    "fg0": "#CAD3F5", "fg1": "#B8C0E0", "fg2": "#A5ADCB", "muted": "#8087A2", "muted2": "#6E738D",
    "border": "#C6A0F6", "accent": "#F5BDE6", "accentSoft": "#F4D5EE", "blue": "#8AADF4",
    "green": "#A6DA95", "red": "#ED8796", "purple": "#C6A0F6"
  ]),
  ThemePreset(id: "Rose Pine", colors: [
    "bg0": "#191724", "bg1": "#1F1D2E", "bg2": "#26233A", "bg3": "#2A273F", "bg4": "#403D52",
    "fg0": "#E0DEF4", "fg1": "#CECACD", "fg2": "#908CAA", "muted": "#6E6A86", "muted2": "#524F67",
    "border": "#C4A7E7", "accent": "#EBBCBA", "accentSoft": "#F2D5C9", "blue": "#9CCFD8",
    "green": "#3E8FB0", "red": "#EB6F92", "purple": "#C4A7E7"
  ]),
  ThemePreset(id: "Rose Pine Moon", colors: [
    "bg0": "#232136", "bg1": "#2A273F", "bg2": "#393552", "bg3": "#3E3A56", "bg4": "#56526E",
    "fg0": "#E0DEF4", "fg1": "#D4CDD4", "fg2": "#908CAA", "muted": "#6E6A86", "muted2": "#56526E",
    "border": "#C4A7E7", "accent": "#EA9A97", "accentSoft": "#F2C2C0", "blue": "#9CCFD8",
    "green": "#3E8FB0", "red": "#EB6F92", "purple": "#C4A7E7"
  ]),
  ThemePreset(id: "Night Owl", colors: [
    "bg0": "#011627", "bg1": "#01111D", "bg2": "#0B2942", "bg3": "#1D3B53", "bg4": "#2C5180",
    "fg0": "#D6DEEB", "fg1": "#C5CFD9", "fg2": "#7FDBCA", "muted": "#637777", "muted2": "#4B6479",
    "border": "#82AAFF", "accent": "#7FDBCA", "accentSoft": "#A6F0E2", "blue": "#82AAFF",
    "green": "#22DA6E", "red": "#EF5350", "purple": "#C792EA"
  ]),
  ThemePreset(id: "Palenight", colors: [
    "bg0": "#292D3E", "bg1": "#222533", "bg2": "#34384B", "bg3": "#3F4458", "bg4": "#4F5374",
    "fg0": "#EEFFFF", "fg1": "#BFC7D5", "fg2": "#A6ACCD", "muted": "#676E95", "muted2": "#4F5374",
    "border": "#82AAFF", "accent": "#FFCB6B", "accentSoft": "#FFE2A8", "blue": "#82AAFF",
    "green": "#C3E88D", "red": "#F07178", "purple": "#C792EA"
  ]),
  ThemePreset(id: "GitHub Dark", colors: [
    "bg0": "#0D1117", "bg1": "#010409", "bg2": "#161B22", "bg3": "#21262D", "bg4": "#30363D",
    "fg0": "#E6EDF3", "fg1": "#C9D1D9", "fg2": "#8B949E", "muted": "#6E7681", "muted2": "#484F58",
    "border": "#58A6FF", "accent": "#58A6FF", "accentSoft": "#79C0FF", "blue": "#79C0FF",
    "green": "#7EE787", "red": "#FF7B72", "purple": "#D2A8FF"
  ]),
  ThemePreset(id: "Synthwave 84", colors: [
    "bg0": "#241B30", "bg1": "#1A1325", "bg2": "#2D2440", "bg3": "#3B2D55", "bg4": "#4F3A75",
    "fg0": "#FFFFFF", "fg1": "#F4F4FE", "fg2": "#B893CE", "muted": "#7C5295", "muted2": "#5A3B73",
    "border": "#F92AAD", "accent": "#FF7EDB", "accentSoft": "#FFB1ED", "blue": "#03EDF9",
    "green": "#72F1B8", "red": "#FE4450", "purple": "#B893CE"
  ]),
  ThemePreset(id: "Cobalt 2", colors: [
    "bg0": "#193549", "bg1": "#122738", "bg2": "#1F4662", "bg3": "#234E70", "bg4": "#0D3A58",
    "fg0": "#FFFFFF", "fg1": "#E1EFFF", "fg2": "#B0C2D6", "muted": "#5C7E99", "muted2": "#3F5871",
    "border": "#FFC600", "accent": "#FFC600", "accentSoft": "#FFE066", "blue": "#9EFFFF",
    "green": "#A8FF60", "red": "#FF628C", "purple": "#FF9D00"
  ]),
  ThemePreset(id: "Material Ocean", colors: [
    "bg0": "#0F111A", "bg1": "#090B10", "bg2": "#1A1C25", "bg3": "#252836", "bg4": "#3A3E4C",
    "fg0": "#EEFFFF", "fg1": "#B4BAC7", "fg2": "#8F93A2", "muted": "#717CB4", "muted2": "#464B5D",
    "border": "#82AAFF", "accent": "#80CBC4", "accentSoft": "#A7E0DA", "blue": "#82AAFF",
    "green": "#C3E88D", "red": "#F07178", "purple": "#C792EA"
  ]),
  ThemePreset(id: "Ayu Dark", colors: [
    "bg0": "#0F1419", "bg1": "#0B0E14", "bg2": "#191F26", "bg3": "#253340", "bg4": "#3E4B59",
    "fg0": "#E6E1CF", "fg1": "#BFBDB6", "fg2": "#959BA4", "muted": "#5C6773", "muted2": "#3E4B59",
    "border": "#FFB454", "accent": "#FFB454", "accentSoft": "#FFD08F", "blue": "#39BAE6",
    "green": "#AAD94C", "red": "#F26D78", "purple": "#D2A6FF"
  ]),
  ThemePreset(id: "Ayu Mirage", colors: [
    "bg0": "#1F2430", "bg1": "#171B24", "bg2": "#272D38", "bg3": "#34323E", "bg4": "#4F5663",
    "fg0": "#CBCCC6", "fg1": "#B0B3BA", "fg2": "#8A9199", "muted": "#5C6773", "muted2": "#444B58",
    "border": "#FFCC66", "accent": "#FFCC66", "accentSoft": "#FFDC92", "blue": "#5CCFE6",
    "green": "#BAE67E", "red": "#F28779", "purple": "#D4BFFF"
  ]),
  ThemePreset(id: "Kanagawa", colors: [
    "bg0": "#1F1F28", "bg1": "#16161D", "bg2": "#2A2A37", "bg3": "#363646", "bg4": "#54546D",
    "fg0": "#DCD7BA", "fg1": "#C8C093", "fg2": "#9CABCA", "muted": "#727169", "muted2": "#54546D",
    "border": "#7E9CD8", "accent": "#FFA066", "accentSoft": "#FFC59D", "blue": "#7E9CD8",
    "green": "#98BB6C", "red": "#E46876", "purple": "#957FB8"
  ]),
  ThemePreset(id: "Everforest Dark", colors: [
    "bg0": "#2D353B", "bg1": "#272E33", "bg2": "#374145", "bg3": "#414B50", "bg4": "#4F585E",
    "fg0": "#D3C6AA", "fg1": "#BCAB94", "fg2": "#9DA9A0", "muted": "#7A8478", "muted2": "#5C6A72",
    "border": "#A7C080", "accent": "#A7C080", "accentSoft": "#C7E0A0", "blue": "#7FBBB3",
    "green": "#A7C080", "red": "#E67E80", "purple": "#D699B6"
  ]),
  ThemePreset(id: "Oxocarbon", colors: [
    "bg0": "#161616", "bg1": "#0F0F0F", "bg2": "#262626", "bg3": "#393939", "bg4": "#525252",
    "fg0": "#F2F4F8", "fg1": "#DDE1E6", "fg2": "#878D96", "muted": "#525252", "muted2": "#393939",
    "border": "#BE95FF", "accent": "#BE95FF", "accentSoft": "#D4B6FF", "blue": "#33B1FF",
    "green": "#42BE65", "red": "#EE5396", "purple": "#BE95FF"
  ]),
  ThemePreset(id: "High Contrast Dark", colors: [
    "bg0": "#000000", "bg1": "#0A0A0A", "bg2": "#161616", "bg3": "#222222", "bg4": "#333333",
    "fg0": "#FFFFFF", "fg1": "#E8E8E8", "fg2": "#B8B8B8", "muted": "#888888", "muted2": "#555555",
    "border": "#FFFFFF", "accent": "#FFFF00", "accentSoft": "#FFFF66", "blue": "#00FFFF",
    "green": "#00FF00", "red": "#FF0000", "purple": "#FF00FF"
  ]),

  // ── Cute / playful ──────────────────────────────────────────
  ThemePreset(id: "Pastel Dream", colors: [
    "bg0": "#1F1B2E", "bg1": "#251F3D", "bg2": "#2D2647", "bg3": "#3A3158", "bg4": "#4A4070",
    "fg0": "#FFF1F8", "fg1": "#F8DCEE", "fg2": "#D4B5E8", "muted": "#9888B5", "muted2": "#6B5F8A",
    "border": "#E4B7FF", "accent": "#FFB7E0", "accentSoft": "#FFD6EC", "blue": "#A4DAFF",
    "green": "#B8FFD8", "red": "#FF9DB5", "purple": "#D6B4FF"
  ]),
  ThemePreset(id: "Sakura Night", colors: [
    "bg0": "#1A1320", "bg1": "#231929", "bg2": "#2E1F38", "bg3": "#3D2A4B", "bg4": "#553B69",
    "fg0": "#FFF0F4", "fg1": "#F0CADD", "fg2": "#D196B5", "muted": "#A06B8B", "muted2": "#704660",
    "border": "#FFB3D1", "accent": "#FF8FB6", "accentSoft": "#FFB8D0", "blue": "#9EC7FF",
    "green": "#B3F0C5", "red": "#FF7088", "purple": "#D49DFF"
  ]),
  ThemePreset(id: "Mint Dream", colors: [
    "bg0": "#0E1A18", "bg1": "#0A1413", "bg2": "#152624", "bg3": "#1F3631", "bg4": "#2C4F47",
    "fg0": "#E8FFF6", "fg1": "#C5F0E1", "fg2": "#8DCAB4", "muted": "#608A7C", "muted2": "#3F5E54",
    "border": "#7FFFD4", "accent": "#3DDCAB", "accentSoft": "#7CECC8", "blue": "#5BC8FF",
    "green": "#90F5A1", "red": "#FF8E80", "purple": "#B894FF"
  ]),
  ThemePreset(id: "Sunset Glow", colors: [
    "bg0": "#1F1014", "bg1": "#180A0E", "bg2": "#2B161B", "bg3": "#3D1F26", "bg4": "#582935",
    "fg0": "#FFE9D6", "fg1": "#FFCCAA", "fg2": "#E89A82", "muted": "#A06B5C", "muted2": "#6E483F",
    "border": "#FFA585", "accent": "#FF7847", "accentSoft": "#FFA178", "blue": "#FFC36B",
    "green": "#FFD56B", "red": "#FF5577", "purple": "#FF9DCC"
  ]),
  ThemePreset(id: "Ocean Breeze", colors: [
    "bg0": "#0A1E2A", "bg1": "#06151F", "bg2": "#102A3A", "bg3": "#1A3A4D", "bg4": "#27516A",
    "fg0": "#E8F8FF", "fg1": "#B7DDF0", "fg2": "#7EB6D1", "muted": "#5A8AA3", "muted2": "#3D6075",
    "border": "#5AC8FA", "accent": "#26C5DC", "accentSoft": "#6FE0F0", "blue": "#5DAEFC",
    "green": "#7FE0B6", "red": "#FF7080", "purple": "#B89FFF"
  ]),
  ThemePreset(id: "Forest Witch", colors: [
    "bg0": "#0E1812", "bg1": "#08120D", "bg2": "#16241B", "bg3": "#1F3527", "bg4": "#2E4D38",
    "fg0": "#E8F5E0", "fg1": "#C8DEB8", "fg2": "#8FAB7E", "muted": "#5E7A55", "muted2": "#3E5238",
    "border": "#9CCB7E", "accent": "#88D86C", "accentSoft": "#B0E89A", "blue": "#86C5C5",
    "green": "#A8E490", "red": "#E47E76", "purple": "#C49AD9"
  ]),
  ThemePreset(id: "Bubblegum", colors: [
    "bg0": "#1E1521", "bg1": "#180F1B", "bg2": "#2A1E2E", "bg3": "#3A2A40", "bg4": "#5A4264",
    "fg0": "#FFEDFA", "fg1": "#F8C7E8", "fg2": "#D69BC4", "muted": "#9D7398", "muted2": "#6E4F6B",
    "border": "#FF80D5", "accent": "#FF5EC4", "accentSoft": "#FF95D8", "blue": "#7FD6FF",
    "green": "#9CFFB5", "red": "#FF6B82", "purple": "#D87DFF"
  ]),
  ThemePreset(id: "Coffee Dark", colors: [
    "bg0": "#1A1410", "bg1": "#140F0C", "bg2": "#241C16", "bg3": "#322620", "bg4": "#473530",
    "fg0": "#F5E8D6", "fg1": "#D9C4A6", "fg2": "#A89274", "muted": "#7A6648", "muted2": "#564434",
    "border": "#C8985C", "accent": "#D4A06A", "accentSoft": "#E5BD8A", "blue": "#9CC2D5",
    "green": "#B8D08C", "red": "#D87870", "purple": "#C098D4"
  ]),

  // ── Light themes ────────────────────────────────────────────
  ThemePreset(id: "Solarized Light", colors: [
    "bg0": "#FDF6E3", "bg1": "#EEE8D5", "bg2": "#E4DDC9", "bg3": "#D6CFB7", "bg4": "#C3BC9F",
    "fg0": "#002B36", "fg1": "#073642", "fg2": "#586E75", "muted": "#93A1A1", "muted2": "#B6B0A0",
    "border": "#268BD2", "accent": "#268BD2", "accentSoft": "#5DAEEC", "blue": "#268BD2",
    "green": "#859900", "red": "#DC322F", "purple": "#6C71C4"
  ]),
  ThemePreset(id: "GitHub Light", colors: [
    "bg0": "#FFFFFF", "bg1": "#F6F8FA", "bg2": "#EAEEF2", "bg3": "#D0D7DE", "bg4": "#AFB8C1",
    "fg0": "#1F2328", "fg1": "#424A53", "fg2": "#656D76", "muted": "#8C959F", "muted2": "#AFB8C1",
    "border": "#0969DA", "accent": "#0969DA", "accentSoft": "#54AEFF", "blue": "#218BFF",
    "green": "#1A7F37", "red": "#CF222E", "purple": "#8250DF"
  ]),
  ThemePreset(id: "Catppuccin Latte", colors: [
    "bg0": "#EFF1F5", "bg1": "#E6E9EF", "bg2": "#DCE0E8", "bg3": "#CCD0DA", "bg4": "#BCC0CC",
    "fg0": "#4C4F69", "fg1": "#5C5F77", "fg2": "#6C6F85", "muted": "#9CA0B0", "muted2": "#BCC0CC",
    "border": "#8839EF", "accent": "#EA76CB", "accentSoft": "#E5A1D5", "blue": "#1E66F5",
    "green": "#40A02B", "red": "#D20F39", "purple": "#8839EF"
  ]),
  // ── Curated Light themes ─────────────────────────────────────
  ThemePreset(id: "Paper", colors: [
    "bg0": "#F7F2E8", "bg1": "#FFFAEF", "bg2": "#EFEADC", "bg3": "#E6E0CF", "bg4": "#D6CFBC",
    "fg0": "#2C2A24", "fg1": "#5A574E", "fg2": "#847F73", "muted": "#ABA597", "muted2": "#C9C4B5",
    "border": "#DBD5C5", "accent": "#A8541F", "accentSoft": "#D49264", "blue": "#3D6FA8",
    "green": "#4F9656", "red": "#B23942", "purple": "#8E58A0"
  ]),
  ThemePreset(id: "Mist", colors: [
    "bg0": "#F4F8FB", "bg1": "#FFFFFF", "bg2": "#EDF2F7", "bg3": "#E2E9F0", "bg4": "#CFDBE7",
    "fg0": "#1A2230", "fg1": "#4A5568", "fg2": "#718096", "muted": "#A0AEC0", "muted2": "#CBD5E0",
    "border": "#E2E9F0", "accent": "#4F86C6", "accentSoft": "#82AFD8", "blue": "#4F86C6",
    "green": "#58A65A", "red": "#E55353", "purple": "#8B6FB2"
  ]),
  ThemePreset(id: "Sakura Light", colors: [
    "bg0": "#FFF7F8", "bg1": "#FFFFFF", "bg2": "#FFEAEF", "bg3": "#FFD9E2", "bg4": "#F5B8CA",
    "fg0": "#4A2935", "fg1": "#6F4452", "fg2": "#936374", "muted": "#B68B9A", "muted2": "#D4B3BE",
    "border": "#F2D6DD", "accent": "#D6336C", "accentSoft": "#F58FA8", "blue": "#6385C4",
    "green": "#5D9B5D", "red": "#C92A4A", "purple": "#A2569E"
  ]),
  ThemePreset(id: "Mint Cloud", colors: [
    "bg0": "#F4FBF6", "bg1": "#FFFFFF", "bg2": "#E9F5ED", "bg3": "#DBEDDF", "bg4": "#C0DDC8",
    "fg0": "#1F3329", "fg1": "#4A5F50", "fg2": "#768B7B", "muted": "#A2B5A6", "muted2": "#C9D4CB",
    "border": "#E0EBE2", "accent": "#2F855A", "accentSoft": "#6EAA89", "blue": "#4287B0",
    "green": "#339966", "red": "#C04A52", "purple": "#8C5CB4"
  ]),
  ThemePreset(id: "Lavender Light", colors: [
    "bg0": "#FAF7FF", "bg1": "#FFFFFF", "bg2": "#F1ECFB", "bg3": "#E5DCF5", "bg4": "#D2C3EC",
    "fg0": "#2C2640", "fg1": "#54486B", "fg2": "#7E7196", "muted": "#A99CC0", "muted2": "#CABFE0",
    "border": "#E8DFF5", "accent": "#7C3AED", "accentSoft": "#A78BFA", "blue": "#5B7AD9",
    "green": "#5BA86C", "red": "#D14552", "purple": "#7C3AED"
  ]),
  ThemePreset(id: "Peach Cream", colors: [
    "bg0": "#FFF6EE", "bg1": "#FFFAF3", "bg2": "#FFE9D5", "bg3": "#FBDBBC", "bg4": "#F2C19A",
    "fg0": "#3A2516", "fg1": "#614433", "fg2": "#896651", "muted": "#B08A72", "muted2": "#CFAE94",
    "border": "#F5DEC4", "accent": "#D9633F", "accentSoft": "#F39575", "blue": "#5786B4",
    "green": "#629851", "red": "#C04338", "purple": "#9F5C9C"
  ]),
  ThemePreset(id: "Pearl", colors: [
    "bg0": "#FCFBF9", "bg1": "#FFFFFF", "bg2": "#F4F1ED", "bg3": "#E9E5DE", "bg4": "#D4CFC4",
    "fg0": "#1F1E1A", "fg1": "#4A4945", "fg2": "#7A7872", "muted": "#A6A49C", "muted2": "#C6C2B8",
    "border": "#E5E0D6", "accent": "#3F3F46", "accentSoft": "#71717A", "blue": "#2563EB",
    "green": "#16A34A", "red": "#DC2626", "purple": "#9333EA"
  ]),
  ThemePreset(id: "Rose Quartz", colors: [
    "bg0": "#FBF5F4", "bg1": "#FFFFFF", "bg2": "#F4EAE8", "bg3": "#EBDAD5", "bg4": "#D9BBB3",
    "fg0": "#3A2326", "fg1": "#604448", "fg2": "#876870", "muted": "#B08F95", "muted2": "#CCB1B5",
    "border": "#EFDDD9", "accent": "#B5475A", "accentSoft": "#D67D8C", "blue": "#5783B0",
    "green": "#658D55", "red": "#A93C45", "purple": "#8E5790"
  ]),
  ThemePreset(id: "Sky Light", colors: [
    "bg0": "#F0F9FF", "bg1": "#FFFFFF", "bg2": "#E0F2FE", "bg3": "#BAE6FD", "bg4": "#7DD3FC",
    "fg0": "#0C2E48", "fg1": "#1E4A6E", "fg2": "#3D6896", "muted": "#7390B5", "muted2": "#A6BCD4",
    "border": "#CFE7F7", "accent": "#0284C7", "accentSoft": "#38BDF8", "blue": "#0284C7",
    "green": "#16A34A", "red": "#DC2626", "purple": "#7C3AED"
  ]),

  ThemePreset(id: "Ayu Light", colors: [
    "bg0": "#FAFAFA", "bg1": "#F0F0F0", "bg2": "#E8E8E8", "bg3": "#D9D7CE", "bg4": "#BFBDB6",
    "fg0": "#5C6166", "fg1": "#787B80", "fg2": "#959DA6", "muted": "#ABB0B6", "muted2": "#C5C6C5",
    "border": "#FA8D3E", "accent": "#FA8D3E", "accentSoft": "#FFB376", "blue": "#399EE6",
    "green": "#86B300", "red": "#F07171", "purple": "#A37ACC"
  ]),

  // ── 🌀 Weird & wild ────────────────────────────────────────
  ThemePreset(id: "Vaporwave", colors: [
    "bg0": "#1B0B3A", "bg1": "#140628", "bg2": "#28104D", "bg3": "#3A1A6B", "bg4": "#552B95",
    "fg0": "#FFE6F7", "fg1": "#FFB8E5", "fg2": "#C795D9", "muted": "#8166A8", "muted2": "#5A4878",
    "border": "#FF71CE", "accent": "#FF71CE", "accentSoft": "#FFA8DD", "blue": "#01CDFE",
    "green": "#05FFA1", "red": "#FF61C7", "purple": "#B967FF"
  ]),
  ThemePreset(id: "Hacker Matrix", colors: [
    "bg0": "#000000", "bg1": "#020A02", "bg2": "#031603", "bg3": "#062306", "bg4": "#0A3A0A",
    "fg0": "#00FF41", "fg1": "#00DD33", "fg2": "#00B82A", "muted": "#085C12", "muted2": "#063D0E",
    "border": "#00FF41", "accent": "#00FF41", "accentSoft": "#74FF8E", "blue": "#00FFCC",
    "green": "#00FF41", "red": "#FF1F1F", "purple": "#7CFFB4"
  ]),
  ThemePreset(id: "Cyberpunk 2077", colors: [
    "bg0": "#0A0E14", "bg1": "#050811", "bg2": "#10161E", "bg3": "#1A2530", "bg4": "#293949",
    "fg0": "#F2FF00", "fg1": "#E1ECC9", "fg2": "#8DB6BC", "muted": "#557A7E", "muted2": "#3D5557",
    "border": "#00FFD1", "accent": "#FCEE0A", "accentSoft": "#FFF668", "blue": "#00F0FF",
    "green": "#39FFAD", "red": "#FF003C", "purple": "#FF00A8"
  ]),
  ThemePreset(id: "Amber CRT", colors: [
    "bg0": "#1A0E00", "bg1": "#120A00", "bg2": "#251600", "bg3": "#3D2300", "bg4": "#5A3500",
    "fg0": "#FFB000", "fg1": "#E89800", "fg2": "#B57600", "muted": "#7E5300", "muted2": "#553700",
    "border": "#FFB000", "accent": "#FFB000", "accentSoft": "#FFC94D", "blue": "#FF8000",
    "green": "#FFD700", "red": "#FF4500", "purple": "#FF6B00"
  ]),
  ThemePreset(id: "MS-DOS", colors: [
    "bg0": "#000080", "bg1": "#000060", "bg2": "#0000A0", "bg3": "#0000C0", "bg4": "#0000E0",
    "fg0": "#FFFFFF", "fg1": "#E0E0FF", "fg2": "#B0B0FF", "muted": "#7070C0", "muted2": "#5050A0",
    "border": "#FFFF00", "accent": "#FFFF00", "accentSoft": "#FFFF80", "blue": "#00FFFF",
    "green": "#00FF00", "red": "#FF8080", "purple": "#FF80FF"
  ]),
  ThemePreset(id: "Galaxy Far Away", colors: [
    "bg0": "#03030F", "bg1": "#02020A", "bg2": "#0A0A20", "bg3": "#161640", "bg4": "#272760",
    "fg0": "#F0F8FF", "fg1": "#B8C8E8", "fg2": "#7B91C2", "muted": "#4A5680", "muted2": "#303A55",
    "border": "#8AB4FF", "accent": "#A78BFA", "accentSoft": "#C3B0FB", "blue": "#5BBCFF",
    "green": "#7DF8C2", "red": "#FF6B9F", "purple": "#C77DFF"
  ]),
  ThemePreset(id: "Aurora Borealis", colors: [
    "bg0": "#001020", "bg1": "#000A18", "bg2": "#001A30", "bg3": "#002848", "bg4": "#013D6A",
    "fg0": "#E8FFFB", "fg1": "#A8E8E0", "fg2": "#6EBFB6", "muted": "#3F8480", "muted2": "#28575C",
    "border": "#00E8B8", "accent": "#7FFFD4", "accentSoft": "#A8FFE0", "blue": "#42E2F4",
    "green": "#00FFAA", "red": "#FF6188", "purple": "#AA77FF"
  ]),
  ThemePreset(id: "Volcanic Lava", colors: [
    "bg0": "#1A0000", "bg1": "#0E0000", "bg2": "#280505", "bg3": "#400808", "bg4": "#5C0F0F",
    "fg0": "#FFE6CC", "fg1": "#FFB380", "fg2": "#E07A3D", "muted": "#A0451B", "muted2": "#6B2E13",
    "border": "#FF4500", "accent": "#FF4500", "accentSoft": "#FF7037", "blue": "#FF8C00",
    "green": "#FFD700", "red": "#DC143C", "purple": "#FF1493"
  ]),
  ThemePreset(id: "Arctic Glacier", colors: [
    "bg0": "#0E1A22", "bg1": "#091218", "bg2": "#152631", "bg3": "#1F3645", "bg4": "#2D4A5C",
    "fg0": "#E8F8FF", "fg1": "#B5DDF0", "fg2": "#7FB6CE", "muted": "#4F7E96", "muted2": "#345768",
    "border": "#A6E3FF", "accent": "#7FDFFF", "accentSoft": "#A8EBFF", "blue": "#5DC4F2",
    "green": "#88E5C0", "red": "#FF7E8A", "purple": "#A0B6FF"
  ]),
  ThemePreset(id: "Cotton Candy", colors: [
    "bg0": "#2A1830", "bg1": "#1F1124", "bg2": "#3A2240", "bg3": "#4D2E55", "bg4": "#683E72",
    "fg0": "#FFF5FB", "fg1": "#F0CCE6", "fg2": "#D599C7", "muted": "#9C6D92", "muted2": "#6E4D67",
    "border": "#FFC0E8", "accent": "#FF85C8", "accentSoft": "#FFB1D7", "blue": "#85D0FF",
    "green": "#A8FFCC", "red": "#FF7588", "purple": "#D085FF"
  ]),
  ThemePreset(id: "Watermelon", colors: [
    "bg0": "#1A2818", "bg1": "#101D0F", "bg2": "#243A22", "bg3": "#345732", "bg4": "#4D7848",
    "fg0": "#FFE6EE", "fg1": "#FFB8CC", "fg2": "#E68DA5", "muted": "#9C5E72", "muted2": "#6B4051",
    "border": "#FF4F7B", "accent": "#FF4F7B", "accentSoft": "#FF85A6", "blue": "#7FE5C5",
    "green": "#7FE57F", "red": "#FF3060", "purple": "#FF85A6"
  ]),
  ThemePreset(id: "Avocado Toast", colors: [
    "bg0": "#1F2A14", "bg1": "#15200D", "bg2": "#2A3920", "bg3": "#3D5030", "bg4": "#566B45",
    "fg0": "#F8F1D8", "fg1": "#DBC9A5", "fg2": "#A89E7A", "muted": "#7A724F", "muted2": "#544E37",
    "border": "#A8D86C", "accent": "#A8D86C", "accentSoft": "#C5E89B", "blue": "#9CCFD8",
    "green": "#88C040", "red": "#D87055", "purple": "#C89DC8"
  ]),
  ThemePreset(id: "Goth Bunny", colors: [
    "bg0": "#000000", "bg1": "#080008", "bg2": "#150010", "bg3": "#22001A", "bg4": "#380028",
    "fg0": "#FFEEFF", "fg1": "#E0B8D8", "fg2": "#9C7898", "muted": "#5C3D58", "muted2": "#3D2638",
    "border": "#FF1493", "accent": "#FF1493", "accentSoft": "#FF66B5", "blue": "#9F00FF",
    "green": "#5BFF8A", "red": "#FF1B5C", "purple": "#C800FF"
  ]),
  ThemePreset(id: "Y2K Chrome", colors: [
    "bg0": "#0F1428", "bg1": "#0A0E1F", "bg2": "#1A2040", "bg3": "#252D55", "bg4": "#3A436F",
    "fg0": "#E0EBFF", "fg1": "#A8B8E0", "fg2": "#7588B5", "muted": "#52638F", "muted2": "#384566",
    "border": "#C0C0C0", "accent": "#FF00CC", "accentSoft": "#FF66DC", "blue": "#00CCFF",
    "green": "#7FFF00", "red": "#FF3030", "purple": "#9966FF"
  ]),
  ThemePreset(id: "Halloween", colors: [
    "bg0": "#0A0510", "bg1": "#05020A", "bg2": "#15091F", "bg3": "#22102E", "bg4": "#351947",
    "fg0": "#FFE0B8", "fg1": "#E8B97D", "fg2": "#C49460", "muted": "#7E5E3D", "muted2": "#553F28",
    "border": "#FF6B00", "accent": "#FF6B00", "accentSoft": "#FF9847", "blue": "#7CC4FF",
    "green": "#5BC85B", "red": "#E62E2E", "purple": "#9B30FF"
  ]),
  ThemePreset(id: "Vampire", colors: [
    "bg0": "#0F0608", "bg1": "#080304", "bg2": "#1C0810", "bg3": "#2D0E18", "bg4": "#451522",
    "fg0": "#FFE8E8", "fg1": "#E0B8B8", "fg2": "#B08585", "muted": "#785757", "muted2": "#503838",
    "border": "#8B0000", "accent": "#DC143C", "accentSoft": "#F04060", "blue": "#A06080",
    "green": "#88B848", "red": "#DC143C", "purple": "#5D2B5D"
  ]),
  ThemePreset(id: "Witch's Brew", colors: [
    "bg0": "#0A0F0A", "bg1": "#050805", "bg2": "#101810", "bg3": "#1C2818", "bg4": "#2D3F26",
    "fg0": "#E8FFD8", "fg1": "#B8E095", "fg2": "#88B068", "muted": "#587838", "muted2": "#3A5024",
    "border": "#7CFF50", "accent": "#7CFF50", "accentSoft": "#A8FF88", "blue": "#48A0E0",
    "green": "#5BFF1F", "red": "#FF3030", "purple": "#9B30FF"
  ]),
  ThemePreset(id: "Mermaid Lagoon", colors: [
    "bg0": "#001A24", "bg1": "#001218", "bg2": "#002A38", "bg3": "#0A3F50", "bg4": "#15596E",
    "fg0": "#E8FFF8", "fg1": "#A8E8DC", "fg2": "#6FBFB0", "muted": "#3F8478", "muted2": "#28574F",
    "border": "#FF7F88", "accent": "#FF7F88", "accentSoft": "#FFB0B6", "blue": "#48E0DC",
    "green": "#5BFFD0", "red": "#FF5078", "purple": "#9B85FF"
  ]),
  ThemePreset(id: "Unicorn Rainbow", colors: [
    "bg0": "#1F0F2E", "bg1": "#150822", "bg2": "#2C1745", "bg3": "#3F2363", "bg4": "#553387",
    "fg0": "#FFF0FF", "fg1": "#F0C8FF", "fg2": "#C795E8", "muted": "#8E6BAB", "muted2": "#634B7E",
    "border": "#FF80F0", "accent": "#FF80F0", "accentSoft": "#FFB0F8", "blue": "#80E0FF",
    "green": "#80FFB0", "red": "#FF7090", "purple": "#C080FF"
  ]),
  ThemePreset(id: "Phoenix Fire", colors: [
    "bg0": "#1A0900", "bg1": "#0E0500", "bg2": "#2D1100", "bg3": "#481B00", "bg4": "#702A00",
    "fg0": "#FFE8C0", "fg1": "#FFC080", "fg2": "#E89045", "muted": "#A85F1F", "muted2": "#6E3D10",
    "border": "#FF6600", "accent": "#FF8C00", "accentSoft": "#FFB050", "blue": "#FFD700",
    "green": "#FFCC00", "red": "#FF3300", "purple": "#FF1493"
  ]),
  ThemePreset(id: "Dragon Scale", colors: [
    "bg0": "#0A1A0E", "bg1": "#051208", "bg2": "#15281C", "bg3": "#203D2A", "bg4": "#2F583E",
    "fg0": "#F5E8C8", "fg1": "#D4C088", "fg2": "#A89557", "muted": "#7A6A38", "muted2": "#544823",
    "border": "#FFD700", "accent": "#FFD700", "accentSoft": "#FFE057", "blue": "#48C5C5",
    "green": "#3FAA62", "red": "#D43838", "purple": "#A84FCD"
  ]),
  ThemePreset(id: "Boba Milk Tea", colors: [
    "bg0": "#1F1611", "bg1": "#150F0B", "bg2": "#2A1E16", "bg3": "#3D2C20", "bg4": "#5A4030",
    "fg0": "#FFF1E0", "fg1": "#E8C9A5", "fg2": "#B89A78", "muted": "#856E50", "muted2": "#5A4A35",
    "border": "#D4A576", "accent": "#E8B888", "accentSoft": "#F5D2A8", "blue": "#9CC0D0",
    "green": "#A8C088", "red": "#D87060", "purple": "#B898C8"
  ]),
  ThemePreset(id: "Matcha Latte", colors: [
    "bg0": "#F5F0E0", "bg1": "#E8E0CC", "bg2": "#DDD2B5", "bg3": "#C9BC95", "bg4": "#A89E78",
    "fg0": "#1F2A14", "fg1": "#3D5025", "fg2": "#5C7038", "muted": "#7E8C58", "muted2": "#9CA878",
    "border": "#5A8838", "accent": "#5A8838", "accentSoft": "#8AB562", "blue": "#3D7099",
    "green": "#5A8838", "red": "#B5414A", "purple": "#8C5BA0"
  ]),
  ThemePreset(id: "Sushi Bar", colors: [
    "bg0": "#0F0F12", "bg1": "#080809", "bg2": "#1A1A1F", "bg3": "#28282F", "bg4": "#3D3D45",
    "fg0": "#FFFCF5", "fg1": "#E8DFC8", "fg2": "#B5A988", "muted": "#7A7058", "muted2": "#544A35",
    "border": "#FF6B70", "accent": "#FF6B70", "accentSoft": "#FF9398", "blue": "#5DAEAC",
    "green": "#A8C870", "red": "#FF4858", "purple": "#A878B5"
  ]),
  ThemePreset(id: "Pad Thai", colors: [
    "bg0": "#1A0F08", "bg1": "#100806", "bg2": "#2A1B0E", "bg3": "#402815", "bg4": "#5C3A1F",
    "fg0": "#FFEED8", "fg1": "#F0CC95", "fg2": "#C49860", "muted": "#876738", "muted2": "#5A4521",
    "border": "#E89035", "accent": "#FF9B3D", "accentSoft": "#FFC07A", "blue": "#88C9E5",
    "green": "#A8E055", "red": "#E84F3A", "purple": "#D49A55"
  ]),
  ThemePreset(id: "Tropical Beach", colors: [
    "bg0": "#003348", "bg1": "#002535", "bg2": "#004460", "bg3": "#005978", "bg4": "#007299",
    "fg0": "#FFF8E0", "fg1": "#FFD9A0", "fg2": "#E89F5C", "muted": "#A87042", "muted2": "#6E4A2C",
    "border": "#FFD700", "accent": "#FF8845", "accentSoft": "#FFAB78", "blue": "#5BC8E5",
    "green": "#7FFFC0", "red": "#FF5566", "purple": "#FF8FB5"
  ]),
  ThemePreset(id: "Deep Sea", colors: [
    "bg0": "#000814", "bg1": "#00050E", "bg2": "#001628", "bg3": "#002340", "bg4": "#01355B",
    "fg0": "#E0F4FF", "fg1": "#90BFE0", "fg2": "#5589B5", "muted": "#2E5878", "muted2": "#1A3A52",
    "border": "#48BFE3", "accent": "#48BFE3", "accentSoft": "#80D5EF", "blue": "#5390D9",
    "green": "#56CFE1", "red": "#F72585", "purple": "#7400B8"
  ]),
  ThemePreset(id: "Coral Reef", colors: [
    "bg0": "#001F2D", "bg1": "#001520", "bg2": "#003045", "bg3": "#004763", "bg4": "#006085",
    "fg0": "#FFF0E8", "fg1": "#FFC9B0", "fg2": "#E89878", "muted": "#A86F50", "muted2": "#6E482F",
    "border": "#FF7F50", "accent": "#FF6B6B", "accentSoft": "#FF9B9B", "blue": "#4ECDC4",
    "green": "#95E1D3", "red": "#F38181", "purple": "#FCBAD3"
  ]),
  ThemePreset(id: "Honeycomb", colors: [
    "bg0": "#1A1300", "bg1": "#100B00", "bg2": "#2A1F00", "bg3": "#403100", "bg4": "#5C4700",
    "fg0": "#FFF5C8", "fg1": "#E8C966", "fg2": "#B59838", "muted": "#856B1A", "muted2": "#594810",
    "border": "#FFB300", "accent": "#FFC107", "accentSoft": "#FFD352", "blue": "#FF9800",
    "green": "#FFEB3B", "red": "#FF5722", "purple": "#FF6F00"
  ]),
  ThemePreset(id: "Blueprint", colors: [
    "bg0": "#0A2F4A", "bg1": "#06223A", "bg2": "#103E5E", "bg3": "#1B5078", "bg4": "#286490",
    "fg0": "#E0F0FF", "fg1": "#B8DCFF", "fg2": "#88B8E5", "muted": "#5588B5", "muted2": "#3A6080",
    "border": "#FFFFFF", "accent": "#FFFFFF", "accentSoft": "#E0F0FF", "blue": "#7FCEFF",
    "green": "#7FFFB0", "red": "#FF8A95", "purple": "#A0AFFF"
  ]),
  ThemePreset(id: "Outrun Sunset", colors: [
    "bg0": "#1B0035", "bg1": "#100020", "bg2": "#28004D", "bg3": "#3D006B", "bg4": "#560096",
    "fg0": "#FFF1FF", "fg1": "#FFC0F0", "fg2": "#E085C5", "muted": "#9555A8", "muted2": "#6B3A78",
    "border": "#FF1F8A", "accent": "#FF6FFF", "accentSoft": "#FF9FFF", "blue": "#00F0FF",
    "green": "#39FF14", "red": "#FF003C", "purple": "#FF1F8A"
  ]),
  ThemePreset(id: "Miami Vice", colors: [
    "bg0": "#1B0E2E", "bg1": "#0F081E", "bg2": "#2A1745", "bg3": "#3D2363", "bg4": "#553387",
    "fg0": "#FFE0F8", "fg1": "#F5A8DC", "fg2": "#C77FB5", "muted": "#8E5588", "muted2": "#633B5C",
    "border": "#00E5E5", "accent": "#FF6EC7", "accentSoft": "#FFB0E0", "blue": "#00E5E5",
    "green": "#7FFF8C", "red": "#FF4060", "purple": "#B967FF"
  ]),
  ThemePreset(id: "Pikachu Yellow", colors: [
    "bg0": "#1F1700", "bg1": "#150F00", "bg2": "#2D2300", "bg3": "#453700", "bg4": "#634F00",
    "fg0": "#FFEE00", "fg1": "#FFD700", "fg2": "#E5BE00", "muted": "#A88A00", "muted2": "#705C00",
    "border": "#000000", "accent": "#FFCB05", "accentSoft": "#FFE057", "blue": "#3B4CCA",
    "green": "#7FCC00", "red": "#FF1F1F", "purple": "#9B30FF"
  ]),
  ThemePreset(id: "Mario World", colors: [
    "bg0": "#1A1F4D", "bg1": "#101535", "bg2": "#252D6B", "bg3": "#363F8C", "bg4": "#4D58B0",
    "fg0": "#FFFFFF", "fg1": "#FFE0B0", "fg2": "#E89F5C", "muted": "#A87042", "muted2": "#6E4A2C",
    "border": "#E52521", "accent": "#E52521", "accentSoft": "#FF5550", "blue": "#0099E5",
    "green": "#43B047", "red": "#E52521", "purple": "#FFB341"
  ]),
  ThemePreset(id: "Pirate's Rum", colors: [
    "bg0": "#1A0F08", "bg1": "#100806", "bg2": "#2A1B0E", "bg3": "#402815", "bg4": "#5C3A1F",
    "fg0": "#FFE6BD", "fg1": "#E0B580", "fg2": "#B58A50", "muted": "#7A5E33", "muted2": "#523F1F",
    "border": "#FFD700", "accent": "#FFD700", "accentSoft": "#FFE057", "blue": "#88C9E5",
    "green": "#A8C078", "red": "#B81F1F", "purple": "#9B6B45"
  ]),
  ThemePreset(id: "Lavender Fields", colors: [
    "bg0": "#1F1A2E", "bg1": "#15111F", "bg2": "#2C2542", "bg3": "#3F3358", "bg4": "#564878",
    "fg0": "#F5F0FF", "fg1": "#D4C4F0", "fg2": "#A892D4", "muted": "#7868A8", "muted2": "#544978",
    "border": "#B197FC", "accent": "#B197FC", "accentSoft": "#D0BFFF", "blue": "#7FAFE5",
    "green": "#A0E5BF", "red": "#FF8FA3", "purple": "#C77DFF"
  ]),
  ThemePreset(id: "Bubble Pop", colors: [
    "bg0": "#0E1428", "bg1": "#080B1B", "bg2": "#1A2240", "bg3": "#2A345A", "bg4": "#3F4A78",
    "fg0": "#FFF8FB", "fg1": "#F5C9DD", "fg2": "#D195B0", "muted": "#8E6585", "muted2": "#634A5E",
    "border": "#FF61A6", "accent": "#FF61A6", "accentSoft": "#FF95C5", "blue": "#61DAFB",
    "green": "#7FFFB0", "red": "#FF6B6B", "purple": "#A78BFA"
  ]),
  ThemePreset(id: "Newspaper", colors: [
    "bg0": "#FBF8F0", "bg1": "#F0EAD8", "bg2": "#E4DDC9", "bg3": "#D2CAB0", "bg4": "#B5AB8C",
    "fg0": "#1A1715", "fg1": "#3D3835", "fg2": "#5C5651", "muted": "#7E7872", "muted2": "#A0998F",
    "border": "#1A1715", "accent": "#3D3835", "accentSoft": "#5C5651", "blue": "#2D5078",
    "green": "#5C7438", "red": "#9C2D2D", "purple": "#5C3870"
  ]),
  ThemePreset(id: "Edo Sumi", colors: [
    "bg0": "#0F0E0C", "bg1": "#0A0908", "bg2": "#1C1A18", "bg3": "#2C2926", "bg4": "#3E3A36",
    "fg0": "#F5F0E0", "fg1": "#D4CDB8", "fg2": "#A89E80", "muted": "#7A715A", "muted2": "#544D3D",
    "border": "#A52A2A", "accent": "#C8474D", "accentSoft": "#E58085", "blue": "#588C8E",
    "green": "#7C9E5F", "red": "#A52A2A", "purple": "#7E5680"
  ])
]

// Precompute light/dark classification once at module load — the popover renders
// hundreds of swatches and asking each preset to recompute its `isLight` on every
// body pass triggered measurable jank. Lookup is now O(1) by id.
let lightPresetIDs: [String: Bool] = Dictionary(
  uniqueKeysWithValues: presets.map { ($0.id, $0.computeIsLight()) }
)

/// Curated Minimal category — the showcase. Themes here are hand-tuned
/// earth-tone palettes (umber, sienna, ochre, sage, clay, parchment) with
/// restrained syntax colors. They're surfaced in their own filter and
/// removed from the generic Dark / Light buckets so the Minimal list
/// stays focused.
let minimalPresetIDs: Set<String> = [
  // Dark earth tones
  "Sumi Ink",
  "Terracotta",
  "Moss Stone",
  "Cedar",
  "Dune",
  "Espresso",
  "Rust Iron",
  "Olive Grove",
  // Light earth tones
  "Linen",
  "Parchment",
  "Sage Garden",
  "Adobe",
  "Stone",
  "Wheat"
]

let minimalPresetsList: [ThemePreset] = presets.filter { minimalPresetIDs.contains($0.id) }
let darkPresetsList: [ThemePreset] = presets.filter {
  lightPresetIDs[$0.id] == false && !minimalPresetIDs.contains($0.id)
}
let lightPresetsList: [ThemePreset] = presets.filter {
  lightPresetIDs[$0.id] == true && !minimalPresetIDs.contains($0.id)
}

// Thread-safe memoization cache for hex→NSColor parsing. Hex strings repeat
// constantly across previews, swatches, presets, etc., so caching turns the
// hot path into a single dictionary lookup.
private let nsColorCacheLock = NSLock()
nonisolated(unsafe) private var nsColorCache: [String: NSColor] = [:]

func nsColor(from hex: String) -> NSColor {
  nsColorCacheLock.lock()
  if let cached = nsColorCache[hex] {
    nsColorCacheLock.unlock()
    return cached
  }
  nsColorCacheLock.unlock()

  var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
  if raw.hasPrefix("#") { raw.removeFirst() }
  if raw.count < 6 {
    let fallback = NSColor.black
    nsColorCacheLock.lock(); nsColorCache[hex] = fallback; nsColorCacheLock.unlock()
    return fallback
  }
  let rgb = String(raw.prefix(6))
  let scanner = Scanner(string: rgb)
  var value: UInt64 = 0
  scanner.scanHexInt64(&value)
  let r = CGFloat((value & 0xFF0000) >> 16) / 255
  let g = CGFloat((value & 0x00FF00) >> 8) / 255
  let b = CGFloat(value & 0x0000FF) / 255
  let result = NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
  nsColorCacheLock.lock()
  // Cap cache size to keep memory bounded.
  if nsColorCache.count > 4096 { nsColorCache.removeAll(keepingCapacity: true) }
  nsColorCache[hex] = result
  nsColorCacheLock.unlock()
  return result
}

func hex(from color: NSColor, alphaSuffix: String = "") -> String {
  let converted = color.usingColorSpace(.sRGB) ?? color
  let r = Int(round(converted.redComponent * 255))
  let g = Int(round(converted.greenComponent * 255))
  let b = Int(round(converted.blueComponent * 255))
  return String(format: "#%02X%02X%02X%@", r, g, b, alphaSuffix)
}

func alphaSuffix(_ hex: String) -> String {
  let raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
  return raw.count == 9 ? String(raw.suffix(2)).uppercased() : ""
}

func uniqueBackupURL(for url: URL, stamp: String) -> URL {
  let directory = backupsDirectory(for: url)
  try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  let baseName = "\(url.lastPathComponent).backup-\(stamp)"
  var candidate = directory.appendingPathComponent(baseName)
  var index = 2
  while FileManager.default.fileExists(atPath: candidate.path) {
    candidate = directory.appendingPathComponent("\(baseName)-\(index)")
    index += 1
  }
  return candidate
}

func settingTitle(_ key: String) -> String {
  let spaced = key
    .replacingOccurrences(of: ".", with: " ")
    .replacingOccurrences(of: #"([a-z])([A-Z])"#, with: "$1 $2", options: .regularExpression)
  return spaced.split(separator: " ").map { word in
    let text = String(word)
    return text.prefix(1).uppercased() + text.dropFirst()
  }.joined(separator: " ")
}

func settingSubtitle(_ key: String) -> String {
  if key.hasPrefix("editor.") { return "พื้นที่ editor, cursor, line highlight, gutter และ guides" }
  if key.hasPrefix("sideBar") || key.hasPrefix("activityBar") { return "sidebar, activity bar, section header และ explorer" }
  if key.hasPrefix("tab.") || key.hasPrefix("titleBar") || key.hasPrefix("editorGroup") { return "tabs, title bar และ editor group header" }
  if key.hasPrefix("list.") || key.hasPrefix("menu.") || key.hasPrefix("menubar.") || key.hasPrefix("breadcrumb") { return "list row, hover, selection, menu และ breadcrumb" }
  if key.hasPrefix("input") || key.hasPrefix("dropdown") || key.hasPrefix("quickInput") || key.hasPrefix("widget") || key.hasPrefix("editorWidget") { return "input, dropdown, command palette และ floating widget" }
  if key.hasPrefix("button") || key.hasPrefix("extensionButton") || key.hasPrefix("toolbar") { return "button, extension button และ toolbar state" }
  if key.hasPrefix("gitDecoration") { return "สีสถานะไฟล์ใน explorer และ source control" }
  if key.hasPrefix("scrollbar") { return "สี scrollbar ปกติ hover และ active" }
  if key.hasPrefix("terminal") { return "terminal background, text และ cursor" }
  if key.hasPrefix("statusBar") { return "status bar และ remote indicator" }
  if key.hasPrefix("chat") || key.hasPrefix("notification") { return "chat, notification และ link ใน panel" }
  return "Workbench color key จาก settings.json"
}

func groupID(for key: String) -> String {
  if key.hasPrefix("editor.background") || key.hasPrefix("sideBar.background") || key.hasPrefix("activityBar.background") || key.hasPrefix("panel.background") || key.hasPrefix("terminal.background") || key.hasPrefix("minimap.background") || key.hasPrefix("statusBar.background") || key.hasPrefix("secondarySideBar.background") { return "surfaces" }
  if key.contains("border") || key == "contrastBorder" || key.hasPrefix("focusBorder") || key.hasPrefix("sash.") { return "borders" }
  if key.hasPrefix("tab.") || key.hasPrefix("titleBar") || key.hasPrefix("editorGroup") { return "tabs" }
  if key.hasPrefix("sideBar") || key.hasPrefix("activityBar") { return "sidebar" }
  if key.hasPrefix("list.") || key.hasPrefix("menu.") || key.hasPrefix("menubar.") || key.hasPrefix("breadcrumb") || key.hasPrefix("pickerGroup") { return "lists" }
  if key.hasPrefix("input") || key.hasPrefix("dropdown") || key.hasPrefix("quickInput") || key.hasPrefix("widget") || key.hasPrefix("editorWidget") || key.hasPrefix("commandCenter") { return "inputs" }
  if key.hasPrefix("editor.") { return "editor" }
  if key.hasPrefix("button") || key.hasPrefix("extensionButton") || key.hasPrefix("toolbar") { return "buttons" }
  if key.hasPrefix("gitDecoration") { return "git" }
  if key.hasPrefix("scrollbar") { return "scrollbar" }
  if key.hasPrefix("terminal") { return "terminal" }
  if key.hasPrefix("statusBar") { return "status" }
  if key.hasPrefix("chat") || key.hasPrefix("notification") || key.hasPrefix("textLink") { return "communication" }
  return "other"
}

let detailGroupInfo: [String: (String, String, String)] = [
  "surfaces": ("Surfaces", "พื้นหลังหลักทุกพื้นที่", "rectangle.3.group"),
  "sidebar": ("Sidebar & Activity", "แถบซ้าย/ขวา, explorer และ badge", "sidebar.left"),
  "tabs": ("Tabs & Title Bar", "tab, title bar และ editor groups", "macwindow"),
  "borders": ("Borders & Focus", "เส้นขอบ, focus ring และ sash", "square.dashed"),
  "lists": ("Lists, Menus & Selection", "selection, hover, menu และ breadcrumb", "list.bullet.rectangle"),
  "inputs": ("Inputs & Widgets", "input, dropdown, command palette และ widgets", "rectangle.and.pencil.and.ellipsis"),
  "editor": ("Editor Details", "line highlight, gutter, guide และ find match", "text.alignleft"),
  "buttons": ("Buttons & Toolbar", "button, extension button และ toolbar", "button.programmable"),
  "git": ("Git Decorations", "modified, added, deleted, ignored และ conflict", "point.3.connected.trianglepath.dotted"),
  "scrollbar": ("Scrollbar", "slider ปกติ hover และ active", "scroll"),
  "terminal": ("Terminal", "terminal foreground, background และ cursor", "terminal"),
  "status": ("Status Bar", "status bar และ remote states", "rectangle.bottomthird.inset.filled"),
  "communication": ("Links, Chat & Notices", "link, chat และ notification", "message.badge"),
  "other": ("Other Workbench Colors", "setting ที่เหลือจาก workbench.colorCustomizations", "slider.horizontal.3")
]

func buildDetailCategories(order: [String]) -> [ColorCategory] {
  let grouped = Dictionary(grouping: order, by: groupID(for:))
  let ids = ["surfaces", "sidebar", "tabs", "borders", "lists", "inputs", "editor", "buttons", "git", "scrollbar", "terminal", "status", "communication", "other"]
  return ids.compactMap { id in
    guard let keys = grouped[id], !keys.isEmpty else { return nil }
    let info = detailGroupInfo[id] ?? (id, "", "circle")
    return ColorCategory(id: id, title: info.0, subtitle: info.1, symbol: info.2, keys: keys)
  }
}

@MainActor
final class ThemeModel: ObservableObject {
  @Published var mode: EditorMode = .base
  @Published var colors: [String: String] = [:]
  @Published var order: [String] = []
  @Published var detailColors: [String: String] = [:]
  @Published var detailOrder: [String] = []
  @Published var detailOverrides: [String: String] = [:]
  @Published var detailCategories: [ColorCategory] = []
  @Published var selectedPreset = presets[0]
  @Published var selectedBaseCategory = baseCategories[0]
  @Published var selectedDetailCategoryID = "surfaces"
  @Published var activeTargetID: String = builtInTargets.first(where: { $0.id == "cursor" })?.id ?? builtInTargets[0].id
  @Published var targetApplyStates: [String: Bool] = Dictionary(uniqueKeysWithValues: builtInTargets.map { ($0.id, $0.id == "cursor") })
  @Published var customTargets: [EditorTarget] = []
  @Published var pathOverrides: [String: String] = [:]

  /// Built-in targets (with user path overrides applied) + user-added custom targets.
  var allTargets: [EditorTarget] {
    var result: [EditorTarget] = builtInTargets.map { base in
      var t = base
      if let override = pathOverrides[base.id] {
        t.pathOverride = override
      }
      return t
    }
    result.append(contentsOf: customTargets)
    return result
  }
  @Published var status = "Ready"
  @Published var filterText: String = ""
  @Published var selectedKey: String? = nil
  @Published var showPreferences: Bool = false
  @Published var showInspector: Bool = true

  @Published var document = ThemeDocument()
  @Published var targetWorkbenchColors: [String: String] = [:]
  @Published var userPresets: [UserPresetSpec] = []

  // Apply flow state
  @Published var pendingApplyConfirmation: Bool = false
  @Published var isApplying: Bool = false
  @Published var applyResult: ApplyOutcome? = nil

  // Confirmation modals for non-Apply toolbar actions.
  @Published var pendingBackupConfirmation: Bool = false
  @Published var pendingReloadConfirmation: Bool = false
  @Published var pendingResetGroupConfirmation: Bool = false
  @Published var pendingResetAllConfirmation: Bool = false
  @Published var pendingOriginalRestore: OriginalBackupInfo? = nil

  // Result modals so the user always gets explicit success/fail feedback,
  // not just a status-bar update.
  @Published var backupResult: BackupOutcome? = nil
  @Published var reloadResult: ReloadOutcome? = nil
  @Published var resetResult: ResetOutcome? = nil
  @Published var originalRestoreResult: OriginalRestoreOutcome? = nil

  enum OriginalRestoreOutcome: Identifiable {
    case success(target: String, date: String)
    case failure(target: String, message: String)
    var id: String {
      switch self {
      case .success(let t, _): return "ok-orig-\(t)"
      case .failure(let t, let m): return "fail-orig-\(t)-\(m)"
      }
    }
  }

  enum ResetOutcome: Identifiable {
    case success(cleared: Int, scope: String)
    var id: String {
      switch self { case .success(let c, let s): return "ok-\(c)-\(s)" }
    }
  }

  enum BackupOutcome: Identifiable {
    case success(files: [URL])
    case failure(message: String)
    var id: String {
      switch self {
      case .success(let f): return "ok-\(f.count)-\(f.first?.lastPathComponent ?? "")"
      case .failure(let m): return "fail-\(m)"
      }
    }
  }

  enum ReloadOutcome: Identifiable {
    case success(paletteCount: Int, keyCount: Int, liveCount: Int, targetName: String)
    case failure(message: String)
    var id: String {
      switch self {
      case .success(let p, let k, let l, let t): return "ok-\(p)-\(k)-\(l)-\(t)"
      case .failure(let m): return "fail-\(m)"
      }
    }
  }

  /// Per-target detail surfaced when Apply detected the source settings.json was
  /// already structurally broken before we touched it. Lets the failure modal offer
  /// a one-click "restore latest valid backup" recovery action per target.
  struct CorruptedTargetInfo: Identifiable, Hashable {
    let id: String          // == target.id
    let targetName: String
    let settingsPath: String
    let latestValidBackup: BackupFile?
  }

  enum ApplyOutcome: Identifiable {
    case success(targets: [String])
    case failure(message: String, partial: [String], corrupted: [CorruptedTargetInfo])
    var id: String {
      switch self {
      case .success(let t): return "ok-\(t.joined())"
      case .failure(let m, _, _): return "fail-\(m)"
      }
    }
  }

  var filteredBaseKeys: [String] {
    let all = selectedBaseCategory.keys.filter { colors[$0] != nil }
    guard !filterText.isEmpty else { return all }
    let q = filterText.lowercased()
    return all.filter { key in
      let title = colorMeta[key]?.title.lowercased() ?? ""
      let sub = colorMeta[key]?.subtitle.lowercased() ?? ""
      return key.lowercased().contains(q) || title.contains(q) || sub.contains(q)
    }
  }

  var filteredDetailKeys: [String] {
    let all = selectedDetailCategory.keys
    guard !filterText.isEmpty else { return all }
    let q = filterText.lowercased()
    return all.filter { key in
      let title = settingTitle(key).lowercased()
      return key.lowercased().contains(q) || title.contains(q)
    }
  }

  func resolvedHex(for key: String) -> String {
    detailOverrides[key] ?? detailColors[key] ?? "#000000"
  }

  /// Returns the most "live" hex for a workbench key for preview purposes.
  /// Priority:
  ///   1. detailOverrides (in-memory edit not yet applied)
  ///   2. theme.json's resolved ui value (detailColors)
  ///   3. target settings.json on disk (targetWorkbenchColors)
  ///   4. palette[paletteFallback]
  ///   5. literalFallback
  func previewHex(_ key: String, palette paletteFallback: String? = nil, literal: String = "#000000") -> String {
    if let v = detailOverrides[key] { return v }
    if let v = detailColors[key] { return v }
    if let v = targetWorkbenchColors[key] { return v }
    if let p = paletteFallback, let v = colors[p] { return v }
    return literal
  }

  /// Read the target's actual settings.json and pull workbench.colorCustomizations.
  func loadTargetWorkbenchColors() {
    let url = activeTarget.settingsURL
    guard let text = try? String(contentsOf: url, encoding: .utf8) else {
      targetWorkbenchColors = [:]
      return
    }
    let blockPattern = #""workbench\.colorCustomizations"\s*:\s*\{([\s\S]*?)\n\s*\}"#
    guard let blockRegex = try? NSRegularExpression(pattern: blockPattern) else {
      targetWorkbenchColors = [:]
      return
    }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = blockRegex.firstMatch(in: text, range: range), match.numberOfRanges > 1,
          let bodyRange = Range(match.range(at: 1), in: text) else {
      targetWorkbenchColors = [:]
      return
    }
    let body = String(text[bodyRange])
    var result: [String: String] = [:]
    let pairRegex = try! NSRegularExpression(pattern: #""([^"]+)":\s*"(#[0-9A-Fa-f]{6,8})""#)
    let bodyRangeNS = NSRange(body.startIndex..<body.endIndex, in: body)
    for match in pairRegex.matches(in: body, range: bodyRangeNS) {
      if let kr = Range(match.range(at: 1), in: body),
         let vr = Range(match.range(at: 2), in: body) {
        result[String(body[kr])] = String(body[vr]).uppercased()
      }
    }
    targetWorkbenchColors = result
  }

  init() {
    Self.migrateLegacyStudioDirIfNeeded()
    ensureThemeFile()
    reload()
    captureOriginalsIfNeeded()
  }

  /// One-time migration: if the legacy "Workbench Theme Studio" support
  /// folder exists from before the rebrand and a Paenia folder hasn't been
  /// created yet, move it over wholesale. Preserves theme.json, regular
  /// Backups, OriginalBackups, and any custom presets the user saved.
  /// Idempotent and silent — safe to call on every launch.
  private static func migrateLegacyStudioDirIfNeeded() {
    let fm = FileManager.default
    guard fm.fileExists(atPath: legacyStudioDir.path) else { return }
    if fm.fileExists(atPath: studioDir.path) { return }
    do {
      try fm.moveItem(at: legacyStudioDir, to: studioDir)
    } catch {
      // Best-effort copy fallback if move fails (e.g. cross-volume edge case)
      try? fm.copyItem(at: legacyStudioDir, to: studioDir)
    }
  }

  private func ensureThemeFile() {
    let fm = FileManager.default
    if fm.fileExists(atPath: themeURL.path) { return }
    try? fm.createDirectory(at: studioDir, withIntermediateDirectories: true)
    if let bundleURL = Bundle.main.url(forResource: "theme", withExtension: "json"),
       let data = try? Data(contentsOf: bundleURL) {
      try? data.write(to: themeURL, options: .atomic)
    }
  }

  var selectedDetailCategory: ColorCategory {
    detailCategories.first { $0.id == selectedDetailCategoryID } ?? detailCategories.first ?? ColorCategory(id: "empty", title: "Detailed Colors", subtitle: "ยังไม่พบสีจาก settings.json", symbol: "slider.horizontal.3", keys: [])
  }

  var activeTarget: EditorTarget {
    allTargets.first { $0.id == activeTargetID } ?? allTargets[0]
  }

  /// Only targets that are detected on this machine are eligible for Apply.
  /// Filtering here means a previously-selected target that the user later
  /// uninstalled won't sneak into a write attempt.
  var applyTargets: [EditorTarget] {
    let selected = allTargets.filter {
      $0.isDetected && targetApplyStates[$0.id] == true
    }
    if !selected.isEmpty { return selected }
    return activeTarget.isDetected ? [activeTarget] : []
  }

  func setActiveTarget(_ target: EditorTarget) {
    activeTargetID = target.id
    targetApplyStates[target.id] = true
    reload()
    // After reload, `detailColors` holds palette-derived values from theme.json.
    // Overlay the new target's actual on-disk workbench colors on top so the
    // LIVE PREVIEW reflects what THAT editor currently looks like — not the
    // last theme we wrote. Subsequent palette edits will overwrite these via
    // `rebuildDetailColorsFromPalette`, so live editing still works.
    syncDetailColorsFromActiveTargetDisk()
  }

  /// Read the active target's settings.json and overlay its workbench colors
  /// onto `detailColors`. Used after switching IDE so the preview tracks the
  /// IDE's actual current theme instead of theme.json's last-applied state.
  func syncDetailColorsFromActiveTargetDisk() {
    loadTargetWorkbenchColors()
    var merged = detailColors
    for (key, value) in targetWorkbenchColors {
      merged[key] = value.uppercased()
    }
    detailColors = merged
  }

  // MARK: - Custom Target Management

  /// Save current customization (overrides + custom targets) into theme.json on disk.
  func persistTargetCustomization() {
    var doc = document
    doc.targetCustomization.pathOverrides = pathOverrides
    doc.targetCustomization.custom = customTargets.map { t in
      CustomTargetSpec(id: t.id, name: t.name, settingsPath: t.pathOverride ?? t.defaultSettingsPath)
    }
    do {
      try ThemeDocumentIO.write(doc, to: themeURL)
      document = doc
    } catch {
      status = "Failed to persist target customization: \(error.localizedDescription)"
    }
  }

  func setOverride(targetID: String, path: String?) {
    if let p = path, !p.isEmpty {
      pathOverrides[targetID] = p
    } else {
      pathOverrides.removeValue(forKey: targetID)
    }
    persistTargetCustomization()
    if targetID == activeTargetID { loadTargetWorkbenchColors() }
  }

  func addCustomTarget(name: String, path: String) -> EditorTarget {
    let id = "custom-\(UUID().uuidString.prefix(8).lowercased())"
    let target = EditorTarget(
      id: id,
      name: name,
      appSupportName: "",
      bundleID: nil,
      supportLevel: "Custom",
      pathOverride: path,
      isCustom: true
    )
    customTargets.append(target)
    targetApplyStates[id] = false
    persistTargetCustomization()
    return target
  }

  func updateCustomTarget(id: String, name: String, path: String) {
    guard let idx = customTargets.firstIndex(where: { $0.id == id }) else { return }
    customTargets[idx].name = name
    customTargets[idx].pathOverride = path
    persistTargetCustomization()
    if id == activeTargetID { loadTargetWorkbenchColors() }
  }

  func removeCustomTarget(id: String) {
    customTargets.removeAll { $0.id == id }
    targetApplyStates.removeValue(forKey: id)
    if activeTargetID == id {
      activeTargetID = "cursor"
    }
    persistTargetCustomization()
  }

  // MARK: - User Presets (saved custom themes)

  /// Persist current `userPresets` array to theme.json on disk.
  func persistUserPresets() {
    var doc = document
    doc.userPresets = userPresets
    do {
      try ThemeDocumentIO.write(doc, to: themeURL)
      document = doc
    } catch {
      status = "Failed to save user presets: \(error.localizedDescription)"
    }
  }

  /// Save the current palette state as a new named user preset.
  @discardableResult
  func saveUserPreset(name: String) -> UserPresetSpec {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let id = "user-\(UUID().uuidString.prefix(8).lowercased())"
    let stamp = ISO8601DateFormatter().string(from: Date())
    var snapshot: [String: String] = [:]
    for k in colors.keys { snapshot[k] = (colors[k] ?? "").uppercased() }
    let spec = UserPresetSpec(id: id, name: trimmed, createdAt: stamp, colors: snapshot)
    userPresets.append(spec)
    persistUserPresets()
    return spec
  }

  func updateUserPreset(id: String, name: String) {
    guard let idx = userPresets.firstIndex(where: { $0.id == id }) else { return }
    userPresets[idx].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    persistUserPresets()
  }

  func removeUserPreset(id: String) {
    userPresets.removeAll { $0.id == id }
    persistUserPresets()
  }

  /// Apply a stored user preset's colors as if it were a built-in preset.
  func applyUserPreset(_ spec: UserPresetSpec) {
    for (key, value) in spec.colors {
      colors[key] = value.uppercased()
      document.colors[key] = value.uppercased()
    }
    let applier = ThemeApplier(document: document)
    let pairs = applier.renderWorkbenchPairs()
    var nextDetailColors: [String: String] = [:]
    var nextDetailOrder: [String] = []
    for (k, v) in pairs {
      nextDetailColors[k] = v.uppercased()
      nextDetailOrder.append(k)
    }
    detailColors = nextDetailColors
    detailOrder = nextDetailOrder
    detailCategories = buildDetailCategories(order: nextDetailOrder)
    status = "Loaded user preset \"\(spec.name)\" · preview updated"
  }

  // MARK: - Backup Management

  struct BackupFile: Identifiable, Hashable {
    let id: String
    let url: URL
    let date: Date
    let size: Int
    let originalName: String
    var displayDate: String {
      let f = DateFormatter()
      f.dateStyle = .medium
      f.timeStyle = .short
      return f.string(from: date)
    }
  }

  func listBackups(forSettingsAt url: URL) -> [BackupFile] {
    migrateLegacyBackups(forSettingsAt: url)
    let dir = backupsDirectory(for: url)
    let baseName = url.lastPathComponent
    let prefix = "\(baseName).backup-"
    guard let entries = try? FileManager.default.contentsOfDirectory(
      at: dir,
      includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
    ) else { return [] }
    return entries
      .filter { $0.lastPathComponent.hasPrefix(prefix) }
      .compactMap { url -> BackupFile? in
        let attrs = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
        let date = attrs?.contentModificationDate ?? Date(timeIntervalSince1970: 0)
        let size = attrs?.fileSize ?? 0
        return BackupFile(id: url.path, url: url, date: date, size: size, originalName: baseName)
      }
      .sorted { $0.date > $1.date }
  }

  /// One-time best-effort move of legacy backups (which used to sit next to the
  /// source `settings.json` inside each editor's User folder) into the centralized
  /// `Backups/<encoded-path>/` directory. Idempotent — safe to call repeatedly.
  private func migrateLegacyBackups(forSettingsAt url: URL) {
    let fm = FileManager.default
    let legacyDir = url.deletingLastPathComponent()
    let newDir = backupsDirectory(for: url)
    // If legacy and new dir resolve to the same place (shouldn't, but defensively),
    // skip to avoid moving files onto themselves.
    if legacyDir.standardizedFileURL.path == newDir.standardizedFileURL.path { return }
    let baseName = url.lastPathComponent
    let prefix = "\(baseName).backup-"
    guard let entries = try? fm.contentsOfDirectory(at: legacyDir, includingPropertiesForKeys: nil) else { return }
    let legacy = entries.filter { $0.lastPathComponent.hasPrefix(prefix) }
    guard !legacy.isEmpty else { return }
    try? fm.createDirectory(at: newDir, withIntermediateDirectories: true)
    for src in legacy {
      var dst = newDir.appendingPathComponent(src.lastPathComponent)
      var i = 2
      while fm.fileExists(atPath: dst.path) {
        dst = newDir.appendingPathComponent("\(src.lastPathComponent)-\(i)")
        i += 1
      }
      try? fm.moveItem(at: src, to: dst)
    }
  }

  /// Most recent backup whose contents pass the brace/bracket sanity check.
  /// Used by the apply-failure recovery flow when the source file is already corrupt.
  func latestValidBackup(forSettingsAt url: URL) -> BackupFile? {
    let backups = listBackups(forSettingsAt: url)
    for b in backups {
      guard let s = try? String(contentsOf: b.url, encoding: .utf8) else { continue }
      if SettingsPatcher.hasBalancedBrackets(s) { return b }
    }
    return nil
  }

  // MARK: - Original ("factory") backups
  //
  // The first time the app sees a target's settings.json on disk, it copies
  // that file into `OriginalBackups/<encoded-path>/settings.json` and never
  // touches it again. Users can restore back to this snapshot anytime —
  // useful when they've Applied many themes and want to wipe the slate
  // back to the editor's pre-app state. These files are intentionally NOT
  // exposed to the regular delete UI; they're our last-line safety net.

  struct OriginalBackupInfo: Identifiable, Hashable {
    let targetID: String
    let targetName: String
    let snapshotURL: URL       // the protected snapshot file
    let originalPath: String   // path of the editor's settings.json
    let date: Date
    let size: Int

    var id: String { targetID }
    var displayDate: String {
      let f = DateFormatter()
      f.dateStyle = .medium
      f.timeStyle = .short
      return f.string(from: date)
    }
  }

  /// Returns the original snapshot for the given source path if one exists.
  func originalBackup(forSettingsAt url: URL, target: EditorTarget) -> OriginalBackupInfo? {
    let snapshot = originalBackupURL(for: url)
    guard FileManager.default.fileExists(atPath: snapshot.path),
          let attrs = try? snapshot.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
    else { return nil }
    return OriginalBackupInfo(
      targetID: target.id,
      targetName: target.name,
      snapshotURL: snapshot,
      originalPath: url.path,
      date: attrs.contentModificationDate ?? Date(timeIntervalSince1970: 0),
      size: attrs.fileSize ?? 0
    )
  }

  /// Capture an original snapshot for a target IF the source file exists and
  /// no snapshot exists yet. Idempotent — safe to call repeatedly.
  /// Returns the resulting info, or nil if there was nothing to capture.
  @discardableResult
  func ensureOriginalBackup(forSettingsAt url: URL, target: EditorTarget) -> OriginalBackupInfo? {
    let fm = FileManager.default
    let snapshot = originalBackupURL(for: url)
    if fm.fileExists(atPath: snapshot.path) {
      return originalBackup(forSettingsAt: url, target: target)
    }
    guard fm.fileExists(atPath: url.path) else { return nil }
    do {
      try fm.createDirectory(at: snapshot.deletingLastPathComponent(),
                             withIntermediateDirectories: true)
      try fm.copyItem(at: url, to: snapshot)
      // Mark read-only at filesystem level too — extra safety so a drag-to-trash
      // from Finder doesn't silently destroy the snapshot. User can still rm
      // manually from Terminal.
      try? fm.setAttributes([.immutable: true], ofItemAtPath: snapshot.path)
      return originalBackup(forSettingsAt: url, target: target)
    } catch {
      return nil
    }
  }

  /// Sweep every known target and capture originals for any that lack one.
  /// Called from `init()` and after `reload()` so newly-detected editors
  /// (e.g. user added a custom path mid-session) also get protected.
  func captureOriginalsIfNeeded() {
    for target in allTargets {
      _ = ensureOriginalBackup(forSettingsAt: target.settingsURL, target: target)
    }
    // Also snapshot the app's own theme.json the very first time, so users
    // can roll back the theme document itself if they trash their palette.
    let themeFakeTarget = EditorTarget(
      id: "__theme__",
      name: "theme.json (app)",
      appSupportName: "",
      bundleID: nil,
      supportLevel: "Internal"
    )
    _ = ensureOriginalBackup(forSettingsAt: themeURL, target: themeFakeTarget)
  }

  /// All originals we know about — one per target that has a snapshot file.
  var allOriginalBackups: [OriginalBackupInfo] {
    allTargets.compactMap { target in
      originalBackup(forSettingsAt: target.settingsURL, target: target)
    }
  }

  /// Used by the confirm modal — runs `restoreOriginal` and surfaces a
  /// success/failure modal so the user always gets explicit feedback.
  func restoreOriginalFromUI(_ info: OriginalBackupInfo) {
    do {
      try restoreOriginal(info)
      originalRestoreResult = .success(target: info.targetName, date: info.displayDate)
    } catch {
      originalRestoreResult = .failure(target: info.targetName, message: error.localizedDescription)
    }
  }

  /// Restore the editor's settings.json from its protected original.
  /// Before overwriting, we snapshot the CURRENT state into the regular
  /// backup folder so the user can undo the original-restore if needed.
  func restoreOriginal(_ info: OriginalBackupInfo) throws {
    let fm = FileManager.default
    let dest = URL(fileURLWithPath: info.originalPath)
    // Pre-snapshot current state into regular backups (best-effort)
    if fm.fileExists(atPath: dest.path) {
      _ = try? makeBackup(of: dest)
      pruneBackups(forSettingsAt: dest, keep: ThemeModel.backupRetentionLimit)
    }
    // Read the protected original via its own URL
    let data = try Data(contentsOf: info.snapshotURL)
    try fm.createDirectory(at: dest.deletingLastPathComponent(),
                           withIntermediateDirectories: true)
    try data.write(to: dest, options: .atomic)
    // Re-sync in-memory state to whatever was just restored on the active target
    if dest.path == activeTarget.settingsURL.path {
      syncStateFromRestoredSettings()
    }
    status = "Restored \(info.targetName) to its original (\(info.displayDate))"
  }

  /// Restore a backup by overwriting the target's settings.json.
  /// After the write, sync in-memory app + preview state to the restored content
  /// so the UI reflects exactly what's now on disk (not the user's pre-rollback edits).
  func restoreBackup(_ backup: BackupFile, to settingsURL: URL) throws {
    let data = try Data(contentsOf: backup.url)
    try data.write(to: settingsURL, options: .atomic)
    if settingsURL.path == activeTarget.settingsURL.path {
      syncStateFromRestoredSettings()
    }
    status = "Restored \(backup.originalName) from \(backup.displayDate) · preview synced"
  }

  /// Re-sync in-memory state to the active target's settings.json on disk.
  /// Called after a rollback so the app + preview match what was just restored:
  ///   - targetWorkbenchColors refreshed from disk
  ///   - detailOverrides cleared (any unsaved user edits are dropped intentionally)
  ///   - detailColors aligned with disk values (for keys present in the restored file)
  ///   - glass tint values pulled from disk if present
  private func syncStateFromRestoredSettings() {
    loadTargetWorkbenchColors()
    detailOverrides.removeAll()
    for (k, v) in targetWorkbenchColors {
      detailColors[k] = v
    }
  }

  /// Best-effort scalar int reader for a top-level `"key": <int>` pair in JSONC text.
  private func readScalarInt(in text: String, key: String) -> Int? {
    let escaped = NSRegularExpression.escapedPattern(for: key)
    let pattern = "\"\(escaped)\"\\s*:\\s*(-?[0-9]+)"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1,
          let r = Range(match.range(at: 1), in: text) else { return nil }
    return Int(text[r])
  }

  func deleteBackup(_ backup: BackupFile) throws {
    try FileManager.default.removeItem(at: backup.url)
    status = "Deleted backup \(backup.url.lastPathComponent)"
  }

  func reload() {
    do {
      let doc = try ThemeDocumentIO.read(from: themeURL)
      document = doc

      colors = doc.colors.values
      order = doc.colors.keys

      let applier = ThemeApplier(document: doc)
      let pairs = applier.renderWorkbenchPairs()
      var nextDetailColors: [String: String] = [:]
      var nextDetailOrder: [String] = []
      for (k, v) in pairs {
        nextDetailColors[k] = v.uppercased()
        nextDetailOrder.append(k)
      }
      detailColors = nextDetailColors
      detailOrder = nextDetailOrder
      detailOverrides = doc.uiOverrides.values
      detailCategories = buildDetailCategories(order: nextDetailOrder)
      if !detailCategories.contains(where: { $0.id == selectedDetailCategoryID }) {
        selectedDetailCategoryID = detailCategories.first?.id ?? "surfaces"
      }

      // Load custom target configuration
      pathOverrides = doc.targetCustomization.pathOverrides
      customTargets = doc.targetCustomization.custom.map { spec in
        EditorTarget(
          id: spec.id,
          name: spec.name,
          appSupportName: "",
          bundleID: nil,
          supportLevel: "Custom",
          pathOverride: spec.settingsPath,
          isCustom: true
        )
      }
      // Backfill applyStates for newly-loaded custom targets
      for t in customTargets where targetApplyStates[t.id] == nil {
        targetApplyStates[t.id] = false
      }
      userPresets = doc.userPresets

      loadTargetWorkbenchColors()
      let liveCount = targetWorkbenchColors.count
      status = "Loaded theme.json (\(colors.count) palette · \(pairs.count) keys) · \(activeTarget.name) on disk: \(liveCount) live keys"
      lastReloadStats = (palette: colors.count, keys: pairs.count, live: liveCount, target: activeTarget.name)
      lastReloadError = nil
    } catch {
      status = "Reload failed: \(error.localizedDescription)"
      lastReloadStats = nil
      lastReloadError = error.localizedDescription
    }
  }

  // Snapshots of the most recent reload outcome — used by `reloadFromUI()`
  // to populate the result modal after the user explicitly clicks Reload.
  private var lastReloadStats: (palette: Int, keys: Int, live: Int, target: String)? = nil
  private var lastReloadError: String? = nil

  /// User-initiated reload (from the toolbar button after confirmation).
  /// Wraps `reload()` and surfaces an explicit success/failure modal so the
  /// user gets concrete feedback instead of just a status-bar update.
  func reloadFromUI() {
    reload()
    if let s = lastReloadStats {
      reloadResult = .success(paletteCount: s.palette, keyCount: s.keys,
                              liveCount: s.live, targetName: s.target)
    } else {
      reloadResult = .failure(message: lastReloadError ?? "Unknown error")
    }
  }

  /// User-initiated backup (from the toolbar button after confirmation).
  /// Always shows a success/failure modal, even if no files were backed up
  /// (e.g. all targets had no settings.json yet).
  func backupFromUI() {
    do {
      let files = try backup()
      backupResult = .success(files: files)
    } catch {
      backupResult = .failure(message: error.localizedDescription)
    }
  }

  func loadPreset() {
    // Update palette in both UI state and document
    for (key, value) in selectedPreset.colors {
      colors[key] = value.uppercased()
      document.colors[key] = value.uppercased()
    }

    // Re-render workbench pairs so the live preview reflects the new palette immediately
    let applier = ThemeApplier(document: document)
    let pairs = applier.renderWorkbenchPairs()
    var nextDetailColors: [String: String] = [:]
    var nextDetailOrder: [String] = []
    for (k, v) in pairs {
      nextDetailColors[k] = v.uppercased()
      nextDetailOrder.append(k)
    }
    detailColors = nextDetailColors
    detailOrder = nextDetailOrder
    detailCategories = buildDetailCategories(order: nextDetailOrder)
    status = "Loaded \(selectedPreset.id) preset · preview updated"
  }

  /// Maximum number of backup files retained per source file (per target).
  /// When the count exceeds this number, the oldest backups are deleted automatically.
  static let backupRetentionLimit = 15

  /// Make a backup snapshot of a single file. Returns the backup URL,
  /// or nil if the source file doesn't exist (nothing to back up).
  /// Caller is responsible for keeping or discarding the backup based on whether
  /// the subsequent write succeeded.
  func makeBackup(of url: URL) throws -> URL? {
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
    let backupURL = uniqueBackupURL(for: url, stamp: stamp)
    try FileManager.default.copyItem(at: url, to: backupURL)
    return backupURL
  }

  /// User-facing "Backup now" button. Snapshots theme.json + every selected target's
  /// settings.json regardless of success (these are explicit user-requested snapshots,
  /// not automatic pre-write safety nets).
  func backup() throws -> [URL] {
    var results: [URL] = []
    if let b = try makeBackup(of: themeURL) {
      results.append(b)
      pruneBackups(forSettingsAt: themeURL, keep: ThemeModel.backupRetentionLimit)
    }
    for target in applyTargets {
      if let b = try makeBackup(of: target.settingsURL) {
        results.append(b)
        pruneBackups(forSettingsAt: target.settingsURL, keep: ThemeModel.backupRetentionLimit)
      }
    }
    return results
  }

  /// Delete oldest backups for a given source file beyond `keep` retention.
  /// Failures are logged into status but never thrown (best-effort cleanup).
  func pruneBackups(forSettingsAt url: URL, keep: Int) {
    let backups = listBackups(forSettingsAt: url)
    guard backups.count > keep else { return }
    let toDelete = Array(backups.dropFirst(keep))   // listBackups sorts newest-first
    var deletedCount = 0
    for b in toDelete {
      do {
        try FileManager.default.removeItem(at: b.url)
        deletedCount += 1
      } catch {
        // best-effort; ignore
      }
    }
    if deletedCount > 0 {
      let prevStatus = status
      status = "\(prevStatus) · pruned \(deletedCount) old backup\(deletedCount == 1 ? "" : "s")"
    }
  }

  // MARK: - Unsaved-edit detection
  //
  // The user can edit two independent layers without committing them via Apply:
  //   1. `colors[]`  — palette swatches (Palette mode)
  //   2. `detailOverrides[]` — workbench key custom values (Detailed mode)
  // Reset must be enabled (and act on) BOTH so the user can always revert
  // mid-edit, not only after Apply.

  /// Palette baseline = the last committed state stored in `document.colors`
  /// (updated on preset load, reload, and successful Apply).
  var hasUnsavedPaletteEdits: Bool {
    for key in colors.keys {
      let baseline = document.colors[key]?.uppercased()
      if baseline != colors[key]?.uppercased() { return true }
    }
    return false
  }

  var hasUnsavedDetailEdits: Bool { !detailOverrides.isEmpty }

  var hasAnyUnsavedEdits: Bool { hasUnsavedPaletteEdits || hasUnsavedDetailEdits }

  /// Palette keys that drift from the document baseline within a given list.
  private func driftedPaletteKeys(in keys: [String]) -> [String] {
    keys.filter { key in
      let baseline = document.colors[key]?.uppercased()
      return baseline != nil && colors[key]?.uppercased() != baseline
    }
  }

  func clearOverridesInSelectedGroup() {
    var clearedPalette = 0
    var clearedOverrides = 0

    // Revert palette swatches in the currently-visible base category back
    // to the document baseline (works whether the user is on Palette or
    // Detailed tab — Palette mode is the most common case here).
    let paletteKeys = selectedBaseCategory.keys
    for key in driftedPaletteKeys(in: paletteKeys) {
      if let baseline = document.colors[key] {
        colors[key] = baseline.uppercased()
        clearedPalette += 1
      }
    }

    // Clear workbench-level overrides for the currently-visible detail group.
    let detailKeys = selectedDetailCategory.keys
    for key in detailKeys where detailOverrides[key] != nil {
      detailOverrides.removeValue(forKey: key)
      clearedOverrides += 1
    }

    rebuildDetailColorsFromPalette()

    let total = clearedPalette + clearedOverrides
    let scope = (mode == .base) ? selectedBaseCategory.title : selectedDetailCategory.title
    status = "Cleared \(total) edit\(total == 1 ? "" : "s") in \(scope)"
    resetResult = .success(cleared: total, scope: scope)
  }

  func clearAllOverrides() {
    var clearedPalette = 0
    // Revert every palette key that drifts from baseline.
    for key in colors.keys {
      let baseline = document.colors[key]?.uppercased()
      if baseline != nil && colors[key]?.uppercased() != baseline {
        colors[key] = baseline ?? colors[key] ?? ""
        clearedPalette += 1
      }
    }

    let clearedOverrides = detailOverrides.count
    detailOverrides.removeAll()
    rebuildDetailColorsFromPalette()

    let total = clearedPalette + clearedOverrides
    status = "Cleared \(total) edit\(total == 1 ? "" : "s")"
    resetResult = .success(cleared: total, scope: "ทั้งหมด")
  }

  /// Re-render `detailColors` from the current in-memory palette so the
  /// preview falls back to palette-derived values immediately after a reset
  /// (otherwise `previewHex` could fall through to the on-disk state via
  /// `targetWorkbenchColors` and keep showing the old override).
  /// Also called whenever the user tweaks a palette swatch in Palette mode
  /// so the cached detailColors stays in sync with live edits.
  ///
  /// Critically, `document.uiOverrides` is **stripped** before passing into
  /// the applier. Otherwise the previously-applied custom values would be
  /// re-baked into `detailColors`, and a Reset wouldn't visually clear the
  /// user's edits — preview would stay stuck on the old custom hue.
  func rebuildDetailColorsFromPalette() {
    var doc = document
    for (key, value) in colors { doc.colors[key] = value.uppercased() }
    doc.uiOverrides.removeAll()
    let applier = ThemeApplier(document: doc)
    let pairs = applier.renderWorkbenchPairs()
    var next: [String: String] = [:]
    for (k, v) in pairs { next[k] = v.uppercased() }
    detailColors = next
  }

  /// Triggered by Apply button. Opens confirmation sheet (does not run yet).
  func requestApply() {
    pendingApplyConfirmation = true
  }

  /// Run after user confirms in the modal.
  func confirmAndApply() {
    pendingApplyConfirmation = false
    isApplying = true
    Task { @MainActor in
      await self.runApplyTask()
      self.isApplying = false
    }
  }

  private func runApplyTask() async {
    apply()
  }

  func apply() {
    do {
      var doc = document

      for key in doc.colors.keys {
        if let v = colors[key] { doc.colors[key] = v.uppercased() }
      }
      for (key, v) in colors where doc.colors[key] == nil {
        doc.colors[key] = v.uppercased()
      }

      doc.uiOverrides.removeAll()
      for key in detailOverrides.keys.sorted() {
        guard let v = detailOverrides[key] else { continue }
        doc.uiOverrides[key] = v.uppercased()
      }

      // Strip any legacy Cursor-only glass.* keys from theme.json — the app
      // now writes a single universal theme that works across every editor.
      doc.themeSettings.removeValue(forKey: "glass.theme.customTintHue")
      doc.themeSettings.removeValue(forKey: "glass.theme.customTintIntensity")

      doc.targetCustomization.pathOverrides = pathOverrides
      doc.targetCustomization.custom = customTargets.map { t in
        CustomTargetSpec(id: t.id, name: t.name, settingsPath: t.pathOverride ?? t.defaultSettingsPath)
      }

      let applier = ThemeApplier(document: doc)
      try applier.validate()

      // Snapshot theme.json (we always need it)
      let themeBackup = try? makeBackup(of: themeURL)
      try ThemeDocumentIO.write(doc, to: themeURL)
      // theme.json write succeeded → keep its backup (or remove if it was empty)
      if let b = themeBackup {
        pruneBackups(forSettingsAt: themeURL, keep: ThemeModel.backupRetentionLimit)
        _ = b
      }
      document = doc

      var appliedNames: [String] = []
      var failedDetails: [String] = []
      var corrupted: [CorruptedTargetInfo] = []
      for target in applyTargets {
        // Universal apply — same options for every editor (Cursor, VS Code, etc.)
        let options: ThemeApplier.ApplyOptions = .universal
        // 1. Snapshot current settings.json (no-op if file doesn't exist).
        let preBackup = try? makeBackup(of: target.settingsURL)
        do {
          try applier.apply(toSettingsAt: target.settingsURL, options: options)
          appliedNames.append(target.name)
          // 2. Write succeeded → keep the backup, then prune old ones.
          if preBackup != nil {
            pruneBackups(forSettingsAt: target.settingsURL, keep: ThemeModel.backupRetentionLimit)
          }
        } catch {
          // 3. Write failed → discard the just-created backup so the user's backup list
          //    only contains snapshots of successful applies.
          if let b = preBackup {
            try? FileManager.default.removeItem(at: b)
          }
          failedDetails.append("\(target.name): \(error.localizedDescription)")
          // If this was the source-corrupt pre-flight (code 98), record details so
          // the failure modal can offer a per-target restore button.
          let nsErr = error as NSError
          if nsErr.domain == "Theme" && nsErr.code == 98 {
            corrupted.append(CorruptedTargetInfo(
              id: target.id,
              targetName: target.name,
              settingsPath: target.settingsURL.path,
              latestValidBackup: latestValidBackup(forSettingsAt: target.settingsURL)
            ))
          }
        }
      }

      reload()

      if failedDetails.isEmpty {
        status = "Applied to \(appliedNames.joined(separator: ", "))"
        applyResult = .success(targets: appliedNames)
      } else {
        let summary = failedDetails.joined(separator: "\n")
        status = "Apply finished with errors"
        applyResult = .failure(message: summary, partial: appliedNames, corrupted: corrupted)
      }
    } catch {
      status = "Apply failed: \(error.localizedDescription)"
      applyResult = .failure(message: error.localizedDescription, partial: [], corrupted: [])
    }
  }

  /// Recovery action for the apply-failure modal: restore latest valid backup
  /// to the given target's settings.json. Returns true on success.
  @discardableResult
  func restoreLatestValidBackup(for info: CorruptedTargetInfo) -> Bool {
    guard let backup = info.latestValidBackup else { return false }
    let url = URL(fileURLWithPath: info.settingsPath)
    do {
      try restoreBackup(backup, to: url)
      return true
    } catch {
      status = "Restore failed: \(error.localizedDescription)"
      return false
    }
  }
}


@main
struct PaeniaApp: App {
  init() {
    // Speed up macOS tooltips. The default initial-show delay is ~1s which feels
    // sluggish for a dense toolbar. NSToolTipManager exposes this via KVC.
    if let cls = NSClassFromString("NSToolTipManager") as? NSObject.Type,
       let manager = cls.value(forKey: "sharedToolTipManager") as? NSObject {
      manager.setValue(0.15, forKey: "initialToolTipDelay")
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .navigationTitle("")
    }
    .windowStyle(.hiddenTitleBar)
    .windowToolbarStyle(.unified(showsTitle: false))
  }
}
