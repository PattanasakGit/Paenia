import Foundation

// MARK: - Document Model

struct ThemeDocument: Codable {
  var version: Int = 1
  var themeSettings: [String: ThemeSettingValue] = [:]
  var colors: OrderedStringMap = OrderedStringMap()
  var ui: OrderedStringMap = OrderedStringMap()
  var uiOverrides: OrderedStringMap = OrderedStringMap()
  var tokenRules: [TokenRule] = []
  var targetCustomization: TargetCustomization = TargetCustomization()
  var userPresets: [UserPresetSpec] = []

  init() {}

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
    self.themeSettings = try c.decodeIfPresent([String: ThemeSettingValue].self, forKey: .themeSettings) ?? [:]
    self.colors = try c.decodeIfPresent(OrderedStringMap.self, forKey: .colors) ?? OrderedStringMap()
    self.ui = try c.decodeIfPresent(OrderedStringMap.self, forKey: .ui) ?? OrderedStringMap()
    self.uiOverrides = try c.decodeIfPresent(OrderedStringMap.self, forKey: .uiOverrides) ?? OrderedStringMap()
    self.tokenRules = try c.decodeIfPresent([TokenRule].self, forKey: .tokenRules) ?? []
    self.targetCustomization = try c.decodeIfPresent(TargetCustomization.self, forKey: .targetCustomization) ?? TargetCustomization()
    self.userPresets = try c.decodeIfPresent([UserPresetSpec].self, forKey: .userPresets) ?? []
  }

  enum CodingKeys: String, CodingKey {
    case version, themeSettings, colors, ui, uiOverrides, tokenRules, targetCustomization, userPresets
  }
}

struct UserPresetSpec: Codable, Hashable {
  var id: String
  var name: String
  var createdAt: String
  var colors: [String: String]
}

struct TargetCustomization: Codable {
  /// Built-in target id → custom path that overrides the default.
  var pathOverrides: [String: String] = [:]
  /// Fully user-defined targets.
  var custom: [CustomTargetSpec] = []

  init() {}

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.pathOverrides = try c.decodeIfPresent([String: String].self, forKey: .pathOverrides) ?? [:]
    self.custom = try c.decodeIfPresent([CustomTargetSpec].self, forKey: .custom) ?? []
  }

  enum CodingKeys: String, CodingKey {
    case pathOverrides, custom
  }
}

struct CustomTargetSpec: Codable, Hashable {
  var id: String
  var name: String
  var settingsPath: String
}

struct TokenRule: Codable {
  var scope: [String]
  var foreground: String
  var fontStyle: String?
}

enum ThemeSettingValue: Codable {
  case string(String)
  case bool(Bool)
  case int(Int)
  case double(Double)

  init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if let b = try? c.decode(Bool.self) { self = .bool(b); return }
    if let i = try? c.decode(Int.self) { self = .int(i); return }
    if let d = try? c.decode(Double.self) { self = .double(d); return }
    if let s = try? c.decode(String.self) { self = .string(s); return }
    throw DecodingError.typeMismatch(
      ThemeSettingValue.self,
      .init(codingPath: decoder.codingPath, debugDescription: "Unsupported themeSettings value type")
    )
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .string(let s): try c.encode(s)
    case .bool(let b): try c.encode(b)
    case .int(let i): try c.encode(i)
    case .double(let d): try c.encode(d)
    }
  }

  var jsonLiteral: String {
    switch self {
    case .string(let s):
      let data = try! JSONSerialization.data(withJSONObject: [s], options: [])
      let str = String(data: data, encoding: .utf8) ?? "[\"\"]"
      return String(str.dropFirst().dropLast())
    case .bool(let b): return b ? "true" : "false"
    case .int(let i): return String(i)
    case .double(let d): return String(d)
    }
  }

  var asInt: Int? {
    switch self {
    case .int(let i): return i
    case .double(let d): return Int(d)
    default: return nil
    }
  }
}

// MARK: - Ordered String Map (preserves JSON source order)

struct OrderedStringMap: Codable, Equatable {
  private(set) var keys: [String] = []
  private(set) var values: [String: String] = [:]

  init() {}

  init(_ pairs: [(String, String)]) {
    for (k, v) in pairs { self[k] = v }
  }

  struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: DynamicKey.self)
    for key in container.allKeys {
      let value = try container.decode(String.self, forKey: key)
      keys.append(key.stringValue)
      values[key.stringValue] = value
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: DynamicKey.self)
    for key in keys {
      let dyn = DynamicKey(stringValue: key)!
      try container.encode(values[key] ?? "", forKey: dyn)
    }
  }

  subscript(_ key: String) -> String? {
    get { values[key] }
    set {
      if let v = newValue {
        if values[key] == nil { keys.append(key) }
        values[key] = v
      } else {
        values.removeValue(forKey: key)
        keys.removeAll { $0 == key }
      }
    }
  }

  mutating func removeAll() {
    keys.removeAll()
    values.removeAll()
  }

  mutating func setOrder(_ order: [String]) {
    keys = order.filter { values[$0] != nil }
    for k in values.keys where !keys.contains(k) {
      keys.append(k)
    }
  }

  var count: Int { keys.count }
}

// MARK: - Theme Document I/O

enum ThemeDocumentIO {
  static func read(from url: URL) throws -> ThemeDocument {
    let data = try Data(contentsOf: url)
    let text = String(data: data, encoding: .utf8) ?? ""
    let decoder = JSONDecoder()
    var doc = try decoder.decode(ThemeDocument.self, from: data)

    if let order = JSONKeyOrder.topLevelKeys(of: "themeSettings", in: text) {
      let filtered = order.filter { doc.themeSettings[$0] != nil }
      var rebuilt: [String: ThemeSettingValue] = [:]
      for k in filtered { rebuilt[k] = doc.themeSettings[k] }
      for (k, v) in doc.themeSettings where rebuilt[k] == nil { rebuilt[k] = v }
      doc.themeSettings = rebuilt
    }
    if let order = JSONKeyOrder.topLevelKeys(of: "colors", in: text) {
      doc.colors.setOrder(order)
    }
    if let order = JSONKeyOrder.topLevelKeys(of: "ui", in: text) {
      doc.ui.setOrder(order)
    }
    if let order = JSONKeyOrder.topLevelKeys(of: "uiOverrides", in: text) {
      doc.uiOverrides.setOrder(order)
    }
    return doc
  }

  static func write(_ doc: ThemeDocument, to url: URL) throws {
    let text = ThemeDocumentSerializer.serialize(doc)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data(text.utf8).write(to: url, options: .atomic)
  }
}

// MARK: - Custom serializer (preserves order, pretty-printed)

enum ThemeDocumentSerializer {
  static func serialize(_ doc: ThemeDocument) -> String {
    var lines: [String] = []
    lines.append("{")
    lines.append("  \"version\": \(doc.version),")
    lines.append("  \"themeSettings\": {")
    let tsKeys = Array(doc.themeSettings.keys)
    for (i, key) in tsKeys.enumerated() {
      let comma = i == tsKeys.count - 1 ? "" : ","
      let val = doc.themeSettings[key]!.jsonLiteral
      lines.append("    \(jsonString(key)): \(val)\(comma)")
    }
    lines.append("  },")
    lines.append("  \"colors\": {")
    for (i, key) in doc.colors.keys.enumerated() {
      let comma = i == doc.colors.keys.count - 1 ? "" : ","
      let val = doc.colors[key] ?? ""
      lines.append("    \(jsonString(key)): \(jsonString(val))\(comma)")
    }
    lines.append("  },")
    lines.append("  \"ui\": {")
    for (i, key) in doc.ui.keys.enumerated() {
      let comma = i == doc.ui.keys.count - 1 ? "" : ","
      let val = doc.ui[key] ?? ""
      lines.append("    \(jsonString(key)): \(jsonString(val))\(comma)")
    }
    lines.append("  },")
    lines.append("  \"uiOverrides\": {")
    for (i, key) in doc.uiOverrides.keys.enumerated() {
      let comma = i == doc.uiOverrides.keys.count - 1 ? "" : ","
      let val = doc.uiOverrides[key] ?? ""
      lines.append("    \(jsonString(key)): \(jsonString(val))\(comma)")
    }
    lines.append("  },")
    lines.append("  \"tokenRules\": [")
    for (i, rule) in doc.tokenRules.enumerated() {
      let comma = i == doc.tokenRules.count - 1 ? "" : ","
      var parts: [String] = []
      let scopeJSON = (try? String(data: JSONSerialization.data(withJSONObject: rule.scope), encoding: .utf8)) ?? "[]"
      parts.append("\"scope\": \(scopeJSON)")
      parts.append("\"foreground\": \(jsonString(rule.foreground))")
      if let style = rule.fontStyle {
        parts.append("\"fontStyle\": \(jsonString(style))")
      }
      lines.append("    { \(parts.joined(separator: ", ")) }\(comma)")
    }
    lines.append("  ],")
    lines.append("  \"targetCustomization\": {")
    let overrideKeys = Array(doc.targetCustomization.pathOverrides.keys).sorted()
    lines.append("    \"pathOverrides\": {")
    for (i, key) in overrideKeys.enumerated() {
      let comma = i == overrideKeys.count - 1 ? "" : ","
      let value = doc.targetCustomization.pathOverrides[key] ?? ""
      lines.append("      \(jsonString(key)): \(jsonString(value))\(comma)")
    }
    lines.append("    },")
    lines.append("    \"custom\": [")
    for (i, target) in doc.targetCustomization.custom.enumerated() {
      let comma = i == doc.targetCustomization.custom.count - 1 ? "" : ","
      lines.append("      { \"id\": \(jsonString(target.id)), \"name\": \(jsonString(target.name)), \"settingsPath\": \(jsonString(target.settingsPath)) }\(comma)")
    }
    lines.append("    ]")
    lines.append("  },")
    lines.append("  \"userPresets\": [")
    for (i, preset) in doc.userPresets.enumerated() {
      let comma = i == doc.userPresets.count - 1 ? "" : ","
      let colorsJSON = (try? String(data: JSONSerialization.data(withJSONObject: preset.colors, options: [.sortedKeys]), encoding: .utf8)) ?? "{}"
      lines.append("    { \"id\": \(jsonString(preset.id)), \"name\": \(jsonString(preset.name)), \"createdAt\": \(jsonString(preset.createdAt)), \"colors\": \(colorsJSON) }\(comma)")
    }
    lines.append("  ]")
    lines.append("}")
    return lines.joined(separator: "\n") + "\n"
  }
}

// MARK: - JSON key-order extractor (raw text scan)

enum JSONKeyOrder {
  // Find the top-level object literal value for `sectionKey`, then return its keys in source order.
  static func topLevelKeys(of sectionKey: String, in text: String) -> [String]? {
    guard let bodyRange = locateObjectBody(of: sectionKey, in: text) else { return nil }
    let body = String(text[bodyRange])
    return extractKeys(fromObjectBody: body)
  }

  private static func locateObjectBody(of key: String, in text: String) -> Range<String.Index>? {
    let escaped = NSRegularExpression.escapedPattern(for: key)
    let pattern = "\"\(escaped)\"\\s*:\\s*\\{"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, range: range),
          let matchRange = Range(match.range, in: text) else { return nil }

    // Find the opening "{" within matchRange
    let openIdx = text.index(before: matchRange.upperBound)
    guard text[openIdx] == "{" else { return nil }

    var depth = 0
    var inString = false
    var escape = false
    var idx = openIdx
    while idx < text.endIndex {
      let ch = text[idx]
      if escape { escape = false; idx = text.index(after: idx); continue }
      if ch == "\\" { escape = true; idx = text.index(after: idx); continue }
      if ch == "\"" { inString.toggle(); idx = text.index(after: idx); continue }
      if !inString {
        if ch == "{" { depth += 1 }
        else if ch == "}" {
          depth -= 1
          if depth == 0 {
            let bodyStart = text.index(after: openIdx)
            return bodyStart..<idx
          }
        }
      }
      idx = text.index(after: idx)
    }
    return nil
  }

  private static func extractKeys(fromObjectBody body: String) -> [String] {
    var keys: [String] = []
    var depth = 0
    var idx = body.startIndex
    while idx < body.endIndex {
      let ch = body[idx]
      if ch == "\"" && depth == 0 {
        var collected = ""
        var j = body.index(after: idx)
        var esc = false
        while j < body.endIndex {
          let c = body[j]
          if esc { collected.append(c); esc = false; j = body.index(after: j); continue }
          if c == "\\" { esc = true; j = body.index(after: j); continue }
          if c == "\"" { break }
          collected.append(c)
          j = body.index(after: j)
        }
        var k = j < body.endIndex ? body.index(after: j) : body.endIndex
        while k < body.endIndex, body[k].isWhitespace { k = body.index(after: k) }
        if k < body.endIndex && body[k] == ":" {
          keys.append(collected)
          idx = body.index(after: k)
          continue
        }
        idx = j < body.endIndex ? body.index(after: j) : body.endIndex
        continue
      }
      if ch == "{" || ch == "[" { depth += 1 }
      else if ch == "}" || ch == "]" { depth -= 1 }
      else if ch == "\"" {
        var j = body.index(after: idx)
        var esc = false
        while j < body.endIndex {
          let c = body[j]
          if esc { esc = false; j = body.index(after: j); continue }
          if c == "\\" { esc = true; j = body.index(after: j); continue }
          if c == "\"" { break }
          j = body.index(after: j)
        }
        idx = j < body.endIndex ? body.index(after: j) : body.endIndex
        continue
      }
      idx = body.index(after: idx)
    }
    return keys
  }
}

// MARK: - Color Resolver

enum ColorResolver {
  static func resolve(_ value: String, palette: [String: String]) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.hasPrefix("$") else { return trimmed }
    let body = String(trimmed.dropFirst())

    if let base = palette[body] { return base }

    if body.count >= 3 {
      let suffix = String(body.suffix(2))
      let varName = String(body.dropLast(2))
      let isHex = suffix.range(of: "^[0-9A-Fa-f]{2}$", options: .regularExpression) != nil
      if isHex, let base = palette[varName] {
        let head = base.hasPrefix("#") ? String(base.prefix(7)) : base
        return head + suffix.uppercased()
      }
    }
    return trimmed
  }
}

// MARK: - Theme Applier (writes settings.json)

enum ThemeApplyError: Error, LocalizedError {
  case invalidColor(key: String, value: String)

  var errorDescription: String? {
    switch self {
    case .invalidColor(let key, let value): return "Invalid color for \(key): \(value)"
    }
  }
}

struct ThemeApplier {
  let document: ThemeDocument

  func validate() throws {
    let palette = document.colors.values
    for key in document.colors.keys {
      let v = palette[key] ?? ""
      if !isValidLiteralHex(v) {
        throw ThemeApplyError.invalidColor(key: "colors.\(key)", value: v)
      }
    }
    for key in document.ui.keys {
      let v = document.ui[key] ?? ""
      let resolved = ColorResolver.resolve(v, palette: palette)
      if !isValidLiteralHex(resolved) {
        throw ThemeApplyError.invalidColor(key: "ui.\(key)", value: v)
      }
    }
    for key in document.uiOverrides.keys {
      let v = document.uiOverrides[key] ?? ""
      let resolved = ColorResolver.resolve(v, palette: palette)
      if !isValidLiteralHex(resolved) {
        throw ThemeApplyError.invalidColor(key: "uiOverrides.\(key)", value: v)
      }
    }
  }

  private func isValidLiteralHex(_ value: String) -> Bool {
    value.range(of: #"^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$"#, options: .regularExpression) != nil
  }

  // Returns ordered (key, resolvedHex) pairs for workbench.colorCustomizations.
  func renderWorkbenchPairs() -> [(String, String)] {
    let palette = document.colors.values
    var pairs: [(String, String)] = []
    var indexByKey: [String: Int] = [:]
    for key in document.ui.keys {
      let raw = document.ui[key] ?? ""
      pairs.append((key, ColorResolver.resolve(raw, palette: palette)))
      indexByKey[key] = pairs.count - 1
    }
    for key in document.uiOverrides.keys {
      let raw = document.uiOverrides[key] ?? ""
      let resolved = ColorResolver.resolve(raw, palette: palette)
      if let idx = indexByKey[key] {
        pairs[idx] = (key, resolved)
      } else {
        pairs.append((key, resolved))
        indexByKey[key] = pairs.count - 1
      }
    }
    return pairs
  }

  func renderWorkbenchBlock() -> String {
    let pairs = renderWorkbenchPairs()
    var lines: [String] = []
    lines.append("    // Generated from Workbench Theme Studio.")
    lines.append("    // Edit theme.json or use the native app.")
    for (i, pair) in pairs.enumerated() {
      let suffix = i == pairs.count - 1 ? "" : ","
      lines.append("    \(jsonString(pair.0)): \(jsonString(pair.1))\(suffix)")
    }
    return "\"workbench.colorCustomizations\": {\n\(lines.joined(separator: "\n"))\n  }"
  }

  func renderTokenBlock() -> String {
    let palette = document.colors.values
    let commentsHex = palette["muted"] ?? "#7C6A99"
    var rulesArray: [[String: Any]] = []
    for rule in document.tokenRules {
      var settings: [String: Any] = [
        "foreground": ColorResolver.resolve(rule.foreground, palette: palette)
      ]
      if let style = rule.fontStyle { settings["fontStyle"] = style }
      rulesArray.append([
        "scope": rule.scope,
        "settings": settings
      ])
    }
    let data = (try? JSONSerialization.data(
      withJSONObject: rulesArray,
      options: [.prettyPrinted, .sortedKeys]
    )) ?? Data("[]".utf8)
    let raw = String(data: data, encoding: .utf8) ?? "[]"
    let indented = indent(raw, leadingSpaces: 4, skipFirstLine: true)
    return """
    "editor.tokenColorCustomizations": {
        "comments": \(jsonString(commentsHex)),
        "textMateRules": \(indented)
      }
    """
  }

  // MARK: - Settings.json mutation

  /// Per-target capabilities controlling what gets written.
  struct ApplyOptions {
    /// Write `workbench.colorTheme` (the active theme name).
    var writeColorTheme: Bool = false
    /// Write Cursor-only `glass.theme.*` settings.
    var writeGlassSettings: Bool = false

    static let cursor = ApplyOptions(writeColorTheme: true, writeGlassSettings: true)
    static let standard = ApplyOptions(writeColorTheme: false, writeGlassSettings: false)
  }

  func apply(toSettingsAt url: URL, options: ApplyOptions = .standard) throws {
    try validate()
    let dir = url.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

    var text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      text = "{\n}\n"
    }

    for (key, value) in document.themeSettings {
      let isGlassKey = key.hasPrefix("glass.")
      let isColorTheme = key == "workbench.colorTheme"

      // Filter keys based on target capabilities
      if isGlassKey && !options.writeGlassSettings {
        // Strip orphaned glass.* keys that may have been written by older versions
        text = SettingsPatcher.removeScalar(from: text, key: key)
        continue
      }
      if isColorTheme && !options.writeColorTheme {
        continue
      }

      text = SettingsPatcher.upsertScalar(in: text, key: key, valueLiteral: value.jsonLiteral)
    }

    text = SettingsPatcher.upsertObjectBlock(
      in: text,
      key: "workbench.colorCustomizations",
      block: renderWorkbenchBlock()
    )
    text = SettingsPatcher.upsertObjectBlock(
      in: text,
      key: "editor.tokenColorCustomizations",
      block: renderTokenBlock()
    )

    // Sanity gate: refuse to write a structurally broken file.
    // This catches regressions and protects users from any future bugs in the patcher.
    guard SettingsPatcher.hasBalancedBrackets(text) else {
      throw NSError(
        domain: "Theme",
        code: 99,
        userInfo: [NSLocalizedDescriptionKey:
          "settings.json ที่กำลังจะเขียนมี braces/brackets ไม่สมดุล — ปฏิเสธเพื่อป้องกันไฟล์เสีย\n" +
          "Path: \(url.path)\n" +
          "ถ้าไฟล์เดิมเสียอยู่แล้ว: ใช้ backup ในโฟลเดอร์เดียวกัน (settings.json.backup-...)"
        ]
      )
    }

    let data = Data(text.utf8)
    try data.write(to: url, options: .atomic)
  }
}

// MARK: - Settings.json string patcher

enum SettingsPatcher {
  static func upsertScalar(in settings: String, key: String, valueLiteral: String) -> String {
    let escaped = NSRegularExpression.escapedPattern(for: key)
    let pattern = "\"\(escaped)\"\\s*:\\s*[^,\\n\\}]+"
    let serialized = "\(jsonString(key)): \(valueLiteral)"
    let range = NSRange(settings.startIndex..<settings.endIndex, in: settings)
    if let regex = try? NSRegularExpression(pattern: pattern),
       regex.firstMatch(in: settings, range: range) != nil {
      let template = NSRegularExpression.escapedTemplate(for: serialized)
      return regex.stringByReplacingMatches(in: settings, range: range, withTemplate: template)
    }
    return insertAtTop(in: settings, line: serialized)
  }

  /// Remove a top-level scalar key entry. Handles trailing/leading commas cleanly.
  /// Used to clean up keys that were written by older versions but no longer apply
  /// for the current target (e.g. removing `glass.theme.*` from VS Code's settings).
  static func removeScalar(from settings: String, key: String) -> String {
    let escaped = NSRegularExpression.escapedPattern(for: key)
    // Match a full line:  whitespace + "key": value [,] + newline
    let pattern = "[ \\t]*\"\(escaped)\"\\s*:\\s*[^,\\n\\}]+,?\\s*\\n?"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return settings }
    let range = NSRange(settings.startIndex..<settings.endIndex, in: settings)
    return regex.stringByReplacingMatches(in: settings, range: range, withTemplate: "")
  }

  static func upsertObjectBlock(in settings: String, key: String, block: String) -> String {
    var result = settings

    // Remove ALL existing top-level entries for this key. This is robust against
    // legacy corrupted files that contained multiple partial duplicates.
    while let entryRange = locateTopLevelObjectEntry(of: key, in: result) {
      var endIdx = entryRange.upperBound
      // Consume trailing comma if present
      if endIdx < result.endIndex && result[endIdx] == "," {
        endIdx = result.index(after: endIdx)
      }
      // Consume trailing whitespace up to and including a newline
      while endIdx < result.endIndex && (result[endIdx] == " " || result[endIdx] == "\t") {
        endIdx = result.index(after: endIdx)
      }
      if endIdx < result.endIndex && result[endIdx] == "\n" {
        endIdx = result.index(after: endIdx)
      }
      result.removeSubrange(entryRange.lowerBound..<endIdx)
    }

    return insertAtTop(in: result, line: block)
  }

  /// Locate the full range of a top-level entry `"key": {...}` using a brace-balanced parser.
  /// Returns the range from the opening `"` of the key to the matching closing `}` (inclusive).
  /// Returns nil if not found.
  static func locateTopLevelObjectEntry(of key: String, in text: String) -> Range<String.Index>? {
    let escaped = NSRegularExpression.escapedPattern(for: key)
    let pattern = "\"\(escaped)\"\\s*:\\s*\\{"
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, range: range),
          let matchRange = Range(match.range, in: text) else { return nil }

    let openIdx = text.index(before: matchRange.upperBound)
    guard text[openIdx] == "{" else { return nil }

    // Walk forward, tracking brace depth + string state, to find the matching `}`.
    var depth = 0
    var inString = false
    var escape = false
    var idx = openIdx
    while idx < text.endIndex {
      let ch = text[idx]
      if escape { escape = false; idx = text.index(after: idx); continue }
      if ch == "\\" { escape = true; idx = text.index(after: idx); continue }
      if ch == "\"" { inString.toggle(); idx = text.index(after: idx); continue }
      if !inString {
        if ch == "{" { depth += 1 }
        else if ch == "}" {
          depth -= 1
          if depth == 0 {
            let endIdx = text.index(after: idx)
            return matchRange.lowerBound..<endIdx
          }
        }
      }
      idx = text.index(after: idx)
    }
    return nil
  }

  /// Verify balanced braces and brackets across the whole text, ignoring strings + JSONC comments.
  /// Used as a post-build sanity gate so we never write a clearly broken file.
  static func hasBalancedBrackets(_ text: String) -> Bool {
    var braceDepth = 0
    var bracketDepth = 0
    var inString = false
    var inLineComment = false
    var inBlockComment = false
    var escape = false
    var idx = text.startIndex
    while idx < text.endIndex {
      let ch = text[idx]
      let next = text.index(after: idx)
      if escape { escape = false; idx = next; continue }
      if inLineComment {
        if ch == "\n" { inLineComment = false }
        idx = next; continue
      }
      if inBlockComment {
        if ch == "*", next < text.endIndex, text[next] == "/" {
          inBlockComment = false
          idx = text.index(after: next); continue
        }
        idx = next; continue
      }
      if inString {
        if ch == "\\" { escape = true }
        else if ch == "\"" { inString = false }
        idx = next; continue
      }
      if ch == "\"" { inString = true; idx = next; continue }
      if ch == "/", next < text.endIndex {
        if text[next] == "/" { inLineComment = true; idx = text.index(after: next); continue }
        if text[next] == "*" { inBlockComment = true; idx = text.index(after: next); continue }
      }
      if ch == "{" { braceDepth += 1 }
      else if ch == "}" { braceDepth -= 1; if braceDepth < 0 { return false } }
      else if ch == "[" { bracketDepth += 1 }
      else if ch == "]" { bracketDepth -= 1; if bracketDepth < 0 { return false } }
      idx = next
    }
    return braceDepth == 0 && bracketDepth == 0
  }

  private static func insertAtTop(in settings: String, line: String) -> String {
    let pattern = "^\\{\\n?"
    if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
      let range = NSRange(settings.startIndex..<settings.endIndex, in: settings)
      let template = NSRegularExpression.escapedTemplate(for: "{\n  \(line),\n")
      return regex.stringByReplacingMatches(in: settings, range: range, withTemplate: template)
    }
    return settings
  }
}

// MARK: - Helpers

func jsonString(_ s: String) -> String {
  let data = (try? JSONSerialization.data(withJSONObject: [s], options: [])) ?? Data("[\"\"]".utf8)
  let str = String(data: data, encoding: .utf8) ?? "[\"\"]"
  return String(str.dropFirst().dropLast())
}

private func indent(_ text: String, leadingSpaces: Int, skipFirstLine: Bool) -> String {
  let pad = String(repeating: " ", count: leadingSpaces)
  let parts = text.split(separator: "\n", omittingEmptySubsequences: false)
  return parts.enumerated().map { i, line in
    (skipFirstLine && i == 0) ? String(line) : pad + String(line)
  }.joined(separator: "\n")
}
