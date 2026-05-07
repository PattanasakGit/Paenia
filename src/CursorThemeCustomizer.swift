import SwiftUI
import AppKit

let userDir = FileManager.default.homeDirectoryForCurrentUser
  .appendingPathComponent("Library/Application Support/Cursor/User")
let generatorURL = userDir.appendingPathComponent("cursor-minimal-dark-theme.mjs")
let settingsURL = userDir.appendingPathComponent("settings.json")

struct ThemePreset: Identifiable, Hashable {
  let id: String
  let colors: [String: String]
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
  ThemePreset(id: "Cyber Violet", colors: [
    "bg0": "#08060F", "bg1": "#100B1F", "bg2": "#17102A", "bg3": "#241642", "bg4": "#34205F",
    "fg0": "#FFF7FF", "fg1": "#E9D7FF", "fg2": "#B79CFF", "muted": "#7C6A99", "muted2": "#534566",
    "border": "#9D4EDD", "accent": "#FF4FD8", "accentSoft": "#FF9BE8", "blue": "#00D4FF",
    "green": "#5CFF95", "red": "#FF3864", "purple": "#C77DFF"
  ])
]

func regexCapture(_ pattern: String, in text: String) throws -> String? {
  let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
  let range = NSRange(text.startIndex..<text.endIndex, in: text)
  guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1,
        let swiftRange = Range(match.range(at: 1), in: text) else { return nil }
  return String(text[swiftRange])
}

func hexIsValid(_ value: String) -> Bool {
  value.range(of: #"^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$"#, options: .regularExpression) != nil
}

func nsColor(from hex: String) -> NSColor {
  var raw = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
  if raw.hasPrefix("#") { raw.removeFirst() }
  if raw.count < 6 { return .black }
  let rgb = String(raw.prefix(6))
  let scanner = Scanner(string: rgb)
  var value: UInt64 = 0
  scanner.scanHexInt64(&value)
  let r = CGFloat((value & 0xFF0000) >> 16) / 255
  let g = CGFloat((value & 0x00FF00) >> 8) / 255
  let b = CGFloat(value & 0x0000FF) / 255
  return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
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

func parseStringColorPairs(from body: String) throws -> (values: [String: String], order: [String]) {
  var values: [String: String] = [:]
  var order: [String] = []
  let regex = try NSRegularExpression(pattern: #""([^"]+)":\s*"(#[0-9A-Fa-f]{6,8})""#)
  for match in regex.matches(in: body, range: NSRange(body.startIndex..<body.endIndex, in: body)) {
    guard let keyRange = Range(match.range(at: 1), in: body),
          let valueRange = Range(match.range(at: 2), in: body) else { continue }
    let key = String(body[keyRange])
    values[key] = String(body[valueRange]).uppercased()
    if !order.contains(key) { order.append(key) }
  }
  return (values, order)
}

func uniqueBackupURL(for url: URL, stamp: String) -> URL {
  let directory = url.deletingLastPathComponent()
  let baseName = "\(url.lastPathComponent).backup-\(stamp)"
  var candidate = directory.appendingPathComponent(baseName)
  var index = 2
  while FileManager.default.fileExists(atPath: candidate.path) {
    candidate = directory.appendingPathComponent("\(baseName)-\(index)")
    index += 1
  }
  return candidate
}

func nodeExecutableURL() -> URL {
  let home = FileManager.default.homeDirectoryForCurrentUser
  let directPaths = [
    home.appendingPathComponent(".volta/bin/node").path,
    "/opt/homebrew/bin/node",
    "/usr/local/bin/node",
    "/usr/bin/node"
  ]
  for path in directPaths {
    if FileManager.default.isExecutableFile(atPath: path) {
      return URL(fileURLWithPath: path)
    }
  }

  let nvmDir = home.appendingPathComponent(".nvm/versions/node")
  if let versions = try? FileManager.default.contentsOfDirectory(at: nvmDir, includingPropertiesForKeys: nil) {
    let candidates = versions
      .map { $0.appendingPathComponent("bin/node") }
      .filter { FileManager.default.isExecutableFile(atPath: $0.path) }
      .sorted { $0.path.localizedStandardCompare($1.path) == .orderedDescending }
    if let node = candidates.first {
      return node
    }
  }

  return URL(fileURLWithPath: "/usr/bin/env")
}

func nodeArguments(generatorPath: String) -> [String] {
  let executable = nodeExecutableURL().path
  return executable == "/usr/bin/env" ? ["node", generatorPath] : [generatorPath]
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
  @Published var tintHue = 188
  @Published var tintIntensity = 30
  @Published var selectedPreset = presets[0]
  @Published var selectedBaseCategory = baseCategories[0]
  @Published var selectedDetailCategoryID = "surfaces"
  @Published var status = "Ready"

  init() {
    reload()
  }

  var selectedDetailCategory: ColorCategory {
    detailCategories.first { $0.id == selectedDetailCategoryID } ?? detailCategories.first ?? ColorCategory(id: "empty", title: "Detailed Colors", subtitle: "ยังไม่พบสีจาก settings.json", symbol: "slider.horizontal.3", keys: [])
  }

  func reload() {
    do {
      let text = try String(contentsOf: generatorURL, encoding: .utf8)
      let colorBody = try regexCapture(#"const colors = \{([\s\S]*?)\n\};"#, in: text) ?? ""
      let themeBody = try regexCapture(#"const themeSettings = \{([\s\S]*?)\n\};"#, in: text) ?? ""
      let overrideBody = try regexCapture(#"const uiOverrides = \{([\s\S]*?)\n\};"#, in: text) ?? ""

      var nextColors: [String: String] = [:]
      var nextOrder: [String] = []
      let baseRegex = try NSRegularExpression(pattern: #"^\s*([A-Za-z0-9_]+):\s*"(#[0-9A-Fa-f]{6,8})",?\s*$"#)
      for line in colorBody.components(separatedBy: .newlines) {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        if let match = baseRegex.firstMatch(in: line, range: range),
           let keyRange = Range(match.range(at: 1), in: line),
           let valueRange = Range(match.range(at: 2), in: line) {
          let key = String(line[keyRange])
          nextColors[key] = String(line[valueRange]).uppercased()
          nextOrder.append(key)
        }
      }

      let themeRegex = try NSRegularExpression(pattern: #"^\s*"([^"]+)":\s*([^,]+),?\s*$"#)
      for line in themeBody.components(separatedBy: .newlines) {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = themeRegex.firstMatch(in: line, range: range),
              let keyRange = Range(match.range(at: 1), in: line),
              let valueRange = Range(match.range(at: 2), in: line) else { continue }
        let key = String(line[keyRange])
        let value = String(line[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        if key == "glass.theme.customTintHue" { tintHue = Int(value) ?? tintHue }
        if key == "glass.theme.customTintIntensity" { tintIntensity = Int(value) ?? tintIntensity }
      }

      let settings = try String(contentsOf: settingsURL, encoding: .utf8)
      let workbenchBody = try regexCapture(#""workbench\.colorCustomizations":\s*\{([\s\S]*?)\n\s*\},\n\s*"editor\.tokenColorCustomizations""#, in: settings) ?? ""
      let parsedDetail = try parseStringColorPairs(from: workbenchBody)
      let parsedOverrides = try parseStringColorPairs(from: overrideBody)

      colors = nextColors
      order = nextOrder
      detailColors = parsedDetail.values
      detailOrder = parsedDetail.order
      detailOverrides = parsedOverrides.values
      detailCategories = buildDetailCategories(order: parsedDetail.order)
      if !detailCategories.contains(where: { $0.id == selectedDetailCategoryID }) {
        selectedDetailCategoryID = detailCategories.first?.id ?? "surfaces"
      }
      status = "Loaded \(nextColors.count) base colors, \(parsedDetail.values.count) detailed colors"
    } catch {
      status = "Reload failed: \(error.localizedDescription)"
    }
  }

  func loadPreset() {
    for (key, value) in selectedPreset.colors {
      colors[key] = value
    }
    status = "Loaded \(selectedPreset.id)"
  }

  func backup() throws -> [URL] {
    let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
    var results: [URL] = []
    for url in [generatorURL, settingsURL] where FileManager.default.fileExists(atPath: url.path) {
      let backup = uniqueBackupURL(for: url, stamp: stamp)
      try FileManager.default.copyItem(at: url, to: backup)
      results.append(backup)
    }
    return results
  }

  func clearOverridesInSelectedGroup() {
    for key in selectedDetailCategory.keys {
      detailOverrides.removeValue(forKey: key)
    }
    status = "Cleared overrides in \(selectedDetailCategory.title)"
  }

  func clearAllOverrides() {
    detailOverrides.removeAll()
    status = "Cleared all detailed overrides"
  }

  func apply() {
    do {
      for key in order {
        let value = colors[key] ?? ""
        guard hexIsValid(value) else { throw NSError(domain: "Theme", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(key) is invalid: \(value)"]) }
      }
      for (key, value) in detailOverrides {
        guard hexIsValid(value) else { throw NSError(domain: "Theme", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(key) is invalid: \(value)"]) }
      }

      _ = try backup()
      var text = try String(contentsOf: generatorURL, encoding: .utf8)
      let colorLines = order.map { key in
        "  \(key): \"\((colors[key] ?? "#000000").uppercased())\","
      }.joined(separator: "\n")
      let themeLines = [
        #"  "workbench.colorTheme": "Default Dark Modern","#,
        #"  "glass.theme.detectColorScheme": false,"#,
        #"  "glass.theme.settingsId": "Default Dark Modern","#,
        #"  "glass.theme.darkSettingsId": "Default Dark Modern","#,
        #"  "glass.theme.customTintHue": \#(tintHue),"#,
        #"  "glass.theme.customTintIntensity": \#(tintIntensity),"#
      ].joined(separator: "\n")
      let overrideLines = detailOverrides.keys.sorted().map { key in
        "  \(String(reflecting: key)): \(String(reflecting: (detailOverrides[key] ?? "#000000").uppercased())),"
      }.joined(separator: "\n")

      text = try NSRegularExpression(pattern: #"const colors = \{[\s\S]*?\n\};"#)
        .stringByReplacingMatches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text), withTemplate: "const colors = {\n\(colorLines)\n};")
      text = try NSRegularExpression(pattern: #"const themeSettings = \{[\s\S]*?\n\};"#)
        .stringByReplacingMatches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text), withTemplate: "const themeSettings = {\n\(themeLines)\n};")

      if text.range(of: #"const uiOverrides = \{[\s\S]*?\n\};"#, options: .regularExpression) != nil {
        text = try NSRegularExpression(pattern: #"const uiOverrides = \{[\s\S]*?\n\};"#)
          .stringByReplacingMatches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text), withTemplate: "const uiOverrides = {\n\(overrideLines)\n};")
      } else {
        text = try NSRegularExpression(pattern: #"(const ui = \{[\s\S]*?\n\};)"#)
          .stringByReplacingMatches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text), withTemplate: "$1\n\n// Direct per-setting overrides written by Cursor Theme Customizer.\n// Keep this object small: base palette colors still drive everything else.\nconst uiOverrides = {\n\(overrideLines)\n};")
      }

      text = text.replacingOccurrences(of: "${Object.entries(ui)\n  .map", with: "${Object.entries({ ...ui, ...uiOverrides })\n  .map")
      try text.write(to: generatorURL, atomically: true, encoding: .utf8)

      let process = Process()
      let pipe = Pipe()
      process.executableURL = nodeExecutableURL()
      process.arguments = nodeArguments(generatorPath: generatorURL.path)
      process.standardError = pipe
      process.standardOutput = pipe
      try process.run()
      process.waitUntilExit()
      guard process.terminationStatus == 0 else {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        throw NSError(domain: "Theme", code: 2, userInfo: [NSLocalizedDescriptionKey: output.isEmpty ? "node generator failed" : output])
      }

      reload()
      status = "Applied to Cursor. Reload Cursor window if Glass cache stays active."
    } catch {
      status = "Apply failed: \(error.localizedDescription)"
    }
  }
}

struct BaseColorRow: View {
  @ObservedObject var model: ThemeModel
  let keyName: String

  var body: some View {
    let meta = colorMeta[keyName] ?? ColorMeta(title: keyName, subtitle: "")
    let value = Binding<String>(
      get: { model.colors[keyName] ?? "#000000" },
      set: { model.colors[keyName] = $0.uppercased() }
    )
    let picker = Binding<Color>(
      get: { Color(nsColor: nsColor(from: value.wrappedValue)) },
      set: { newColor in
        model.colors[keyName] = hex(from: NSColor(newColor), alphaSuffix: alphaSuffix(value.wrappedValue))
      }
    )

    ColorEditorShell(color: value.wrappedValue) {
      VStack(alignment: .leading, spacing: 5) {
        HStack(spacing: 8) {
          Text(meta.title).font(.headline)
          Text(keyName)
            .font(.system(.caption, design: .monospaced).weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.white.opacity(0.08), in: Capsule())
            .foregroundStyle(.secondary)
        }
        Text(meta.subtitle).font(.callout).foregroundStyle(.secondary)
      }
    } controls: {
      TextField("#RRGGBB", text: value)
        .font(.system(.body, design: .monospaced))
        .textFieldStyle(.roundedBorder)
        .frame(width: 130)
      ColorPicker("", selection: picker, supportsOpacity: false)
        .labelsHidden()
        .frame(width: 34)
    }
  }
}

struct DetailColorRow: View {
  @ObservedObject var model: ThemeModel
  let keyName: String

  var body: some View {
    let value = Binding<String>(
      get: { model.detailOverrides[keyName] ?? model.detailColors[keyName] ?? "#000000" },
      set: { newValue in
        let clean = newValue.uppercased()
        model.detailColors[keyName] = clean
        model.detailOverrides[keyName] = clean
      }
    )
    let picker = Binding<Color>(
      get: { Color(nsColor: nsColor(from: value.wrappedValue)) },
      set: { newColor in
        let next = hex(from: NSColor(newColor), alphaSuffix: alphaSuffix(value.wrappedValue))
        model.detailColors[keyName] = next
        model.detailOverrides[keyName] = next
      }
    )
    let isOverride = model.detailOverrides[keyName] != nil

    ColorEditorShell(color: value.wrappedValue) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 8) {
          Text(settingTitle(keyName)).font(.headline)
          if isOverride {
            Text("custom")
              .font(.system(.caption, design: .rounded).weight(.bold))
              .padding(.horizontal, 7)
              .padding(.vertical, 3)
              .background(.green.opacity(0.2), in: Capsule())
              .foregroundStyle(.green)
          }
        }
        Text(settingSubtitle(keyName))
          .font(.callout)
          .foregroundStyle(.secondary)
        Text(keyName)
          .font(.system(.caption, design: .monospaced))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    } controls: {
      TextField("#RRGGBB", text: value)
        .font(.system(.body, design: .monospaced))
        .textFieldStyle(.roundedBorder)
        .frame(width: 130)
      ColorPicker("", selection: picker, supportsOpacity: false)
        .labelsHidden()
        .frame(width: 34)
      Button {
        model.detailOverrides.removeValue(forKey: keyName)
        model.status = "Reset \(keyName) to palette-generated value"
      } label: {
        Image(systemName: "arrow.counterclockwise")
      }
      .disabled(!isOverride)
      .help("Reset this setting to base palette")
    }
  }
}

struct ColorEditorShell<LabelContent: View, ControlsContent: View>: View {
  let color: String
  @ViewBuilder var label: LabelContent
  @ViewBuilder var controls: ControlsContent

  var body: some View {
    HStack(spacing: 14) {
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(nsColor: nsColor(from: color)))
        .frame(width: 64, height: 54)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.2)))
        .shadow(color: Color(nsColor: nsColor(from: color)).opacity(0.24), radius: 10, y: 4)

      label
      Spacer(minLength: 12)
      HStack(spacing: 8) { controls }
    }
    .padding(14)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.12)))
  }
}

struct ContentView: View {
  @StateObject private var model = ThemeModel()
  private let previewKeys = ["bg0", "bg1", "bg2", "bg3", "bg4", "accent", "accentSoft", "blue", "green", "red", "purple"]

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(nsColor: nsColor(from: model.colors["bg0"] ?? "#0B0D0E")),
          Color(nsColor: nsColor(from: model.colors["bg1"] ?? "#101218")).opacity(0.96)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      NavigationSplitView {
        sidebar
          .navigationSplitViewColumnWidth(min: 300, ideal: 330)
      } detail: {
        detail
          .frame(minWidth: 720, minHeight: 680)
      }
      .scrollContentBackground(.hidden)
    }
  }

  private var sidebar: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 12) {
          AppMark(colors: model.colors)
            .frame(width: 44, height: 44)
          VStack(alignment: .leading, spacing: 2) {
            Text("Cursor Theme").font(.title2.bold())
            Text("Minimal Glass Editor").foregroundStyle(.secondary)
          }
        }

        Picker("Editor Mode", selection: $model.mode) {
          ForEach(EditorMode.allCases) { mode in
            Text(mode.rawValue).tag(mode)
          }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: .infinity)

        presetCard
        groupsCard
        tintCard
        actionsCard
      }
      .padding(18)
      .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    .background(.ultraThinMaterial)
  }

  private var presetCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Presets", systemImage: "sparkles")
        .font(.headline)
      Picker("Preset", selection: $model.selectedPreset) {
        ForEach(presets) { preset in
          Text(preset.id).tag(preset)
        }
      }
      .pickerStyle(.menu)
      .frame(maxWidth: .infinity, alignment: .leading)

      Button("Load Preset") { model.loadPreset() }
        .frame(maxWidth: .infinity)
    }
    .glassCard()
  }

  private var groupsCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(model.mode == .base ? "Base Groups" : "Detailed Groups", systemImage: "square.grid.2x2")
        .font(.headline)
      if model.mode == .base {
        ForEach(baseCategories) { category in
          categoryButton(category, selected: model.selectedBaseCategory == category) {
            model.selectedBaseCategory = category
          }
        }
      } else {
        ForEach(model.detailCategories) { category in
          categoryButton(category, selected: model.selectedDetailCategoryID == category.id) {
            model.selectedDetailCategoryID = category.id
          }
        }
      }
    }
    .glassCard()
  }

  private func categoryButton(_ category: ColorCategory, selected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: category.symbol)
          .frame(width: 24)
        VStack(alignment: .leading, spacing: 1) {
          Text(category.title).font(.callout.weight(.semibold))
          Text(category.subtitle).font(.caption).foregroundStyle(.secondary)
            .lineLimit(1)
        }
        Spacer(minLength: 0)
        Text("\(category.keys.count)")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .padding(10)
    .background(selected ? .white.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 12))
  }

  private var tintCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Glass Tint", systemImage: "circle.lefthalf.filled")
        .font(.headline)
      Stepper("Hue \(model.tintHue)", value: $model.tintHue, in: 0...360)
        .frame(maxWidth: .infinity, alignment: .leading)
      Stepper("Intensity \(model.tintIntensity)", value: $model.tintIntensity, in: 0...100)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .glassCard()
  }

  private var actionsCard: some View {
    VStack(spacing: 10) {
      Button("Apply to Cursor") { model.apply() }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)

      HStack {
        Button("Backup") {
          do {
            let files = try model.backup()
            model.status = "Backup created: \(files.count) files"
          } catch {
            model.status = "Backup failed: \(error.localizedDescription)"
          }
        }
        .frame(maxWidth: .infinity)
        Button("Reload") { model.reload() }
          .frame(maxWidth: .infinity)
        Button {
          NSWorkspace.shared.open(userDir)
        } label: {
          Image(systemName: "folder")
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)

      Text(model.status)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .glassCard()
  }

  private var detail: some View {
    VStack(alignment: .leading, spacing: 16) {
      detailHeader

      if model.mode == .base {
        palettePreview
        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(model.selectedBaseCategory.keys.filter { model.colors[$0] != nil }, id: \.self) { key in
              BaseColorRow(model: model, keyName: key)
            }
          }
          .padding(.vertical, 2)
        }
      } else {
        detailedToolbar
        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(model.selectedDetailCategory.keys, id: \.self) { key in
              DetailColorRow(model: model, keyName: key)
            }
          }
          .padding(.vertical, 2)
        }
      }
    }
    .padding(22)
  }

  private var detailHeader: some View {
    let category = model.mode == .base ? model.selectedBaseCategory : model.selectedDetailCategory
    return HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 6) {
        Label(category.title, systemImage: category.symbol)
          .font(.largeTitle.bold())
        Text(category.subtitle)
          .font(.title3)
          .foregroundStyle(.secondary)
      }
      Spacer()
      if model.mode == .detailed {
        VStack(alignment: .trailing, spacing: 4) {
          Text("\(model.detailOverrides.count) custom overrides")
            .font(.callout.weight(.semibold))
          Text("แก้สีราย key โดยไม่ทำลาย base palette")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private var palettePreview: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Live Palette").font(.headline)
      HStack(spacing: 8) {
        ForEach(previewKeys, id: \.self) { key in
          RoundedRectangle(cornerRadius: 10)
            .fill(Color(nsColor: nsColor(from: model.colors[key] ?? "#000000")))
            .frame(height: 42)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.16)))
            .help("\(colorMeta[key]?.title ?? key): \(model.colors[key] ?? "")")
        }
      }
    }
    .glassCard()
  }

  private var detailedToolbar: some View {
    HStack(spacing: 10) {
      Label("Direct workbench.colorCustomizations", systemImage: "slider.horizontal.3")
        .font(.headline)
      Spacer()
      Button("Reset This Group") { model.clearOverridesInSelectedGroup() }
      Button("Reset All Custom") { model.clearAllOverrides() }
    }
    .buttonStyle(.bordered)
    .glassCard()
  }
}

struct AppMark: View {
  let colors: [String: String]

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(.ultraThinMaterial)
        .overlay(
          LinearGradient(
            colors: [
              Color(nsColor: nsColor(from: colors["accent"] ?? "#00E5FF")).opacity(0.9),
              Color(nsColor: nsColor(from: colors["purple"] ?? "#D946EF")).opacity(0.86),
              Color(nsColor: nsColor(from: colors["blue"] ?? "#4D7CFF")).opacity(0.86)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          .blendMode(.plusLighter)
        )
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.22)))

      Image(systemName: "paintpalette.fill")
        .font(.system(size: 21, weight: .semibold))
        .foregroundStyle(.white)
        .shadow(radius: 8)
    }
  }
}

extension View {
  func glassCard() -> some View {
    self
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.12)))
  }
}

@main
struct CursorThemeCustomizerApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .windowStyle(.titleBar)
  }
}
