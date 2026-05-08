import SwiftUI
import AppKit

// MARK: - Root

struct ContentView: View {
  @StateObject private var model = ThemeModel()

  var body: some View {
    NavigationSplitView {
      SidebarView(model: model)
        .navigationSplitViewColumnWidth(min: 230, ideal: 250, max: 290)
    } detail: {
      DetailContainer(model: model)
        .frame(minWidth: 760, minHeight: 560)
    }
    .navigationSplitViewStyle(.balanced)
    .background(AppBackground(model: model))
    .toolbar { mainToolbar }
    .sheet(isPresented: $model.showPreferences) {
      PreferencesSheet(model: model)
    }
    .sheet(isPresented: $model.pendingApplyConfirmation) {
      ConfirmApplySheet(model: model)
    }
    .sheet(item: $model.applyResult) { outcome in
      ApplyResultSheet(model: model, outcome: outcome)
    }
    .preferredColorScheme(model.appColorScheme)
    .tint(model.appAccent)
    .environment(\.themeChrome, ThemeChrome.from(model))
    .animation(.easeInOut(duration: 0.25), value: model.appColorScheme)
  }

  /// Compact icon + Thai label used in the toolbar so every button shows what it does
  /// at a glance — even before tooltips fire.
  private func toolbarLabel(_ icon: String, _ text: String) -> some View {
    HStack(spacing: 5) {
      Image(systemName: icon)
        .font(.system(size: 13, weight: .medium))
      Text(text)
        .font(.system(.caption, design: .rounded).weight(.semibold))
    }
    .padding(.horizontal, 4)
  }

  @ToolbarContentBuilder
  private var mainToolbar: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      TargetMenu(model: model)
    }
    ToolbarItemGroup(placement: .primaryAction) {
      Button {
        do {
          let files = try model.backup()
          model.status = "Backup created: \(files.count) files"
        } catch {
          model.status = "Backup failed: \(error.localizedDescription)"
        }
      } label: {
        toolbarLabel("tray.and.arrow.down", "สำรอง")
      }
      .keyboardShortcut("b", modifiers: .command)
      .help("สำรองไฟล์ settings.json ของทุก target ที่เลือกอยู่ในตอนนี้ทันที (⌘B)")

      Button(action: model.reload) {
        toolbarLabel("arrow.clockwise", "รีโหลด")
      }
      .keyboardShortcut("r", modifiers: .command)
      .help("โหลด theme.json และอ่าน settings.json ของ editor ใหม่จากดิสก์ (⌘R)")

      Button {
        NSWorkspace.shared.open(model.activeTarget.userDir)
      } label: {
        toolbarLabel("folder", "เปิดโฟลเดอร์")
      }
      .help("เปิดโฟลเดอร์ที่เก็บ settings.json ของ editor ปัจจุบันใน Finder")

      Button {
        model.showInspector.toggle()
      } label: {
        toolbarLabel(
          model.showInspector ? "sidebar.right" : "rectangle.righthalf.inset.filled",
          "พรีวิว"
        )
      }
      .keyboardShortcut("i", modifiers: [.command, .option])
      .help("ซ่อน/แสดงแถบ Inspector ด้านขวา (preview + รายละเอียดสีที่เลือก) (⌥⌘I)")

      Button {
        model.showPreferences = true
      } label: {
        toolbarLabel("gearshape", "ตั้งค่า")
      }
      .keyboardShortcut(",", modifiers: .command)
      .help("เปิดหน้าตั้งค่า — Glass Tint, Apply Targets, จัดการ Backup, custom paths (⌘,)")

      // Apply — prominent labeled button (opens confirmation sheet)
      Button(action: model.requestApply) {
        HStack(spacing: 5) {
          if model.isApplying {
            ProgressView().controlSize(.small)
          } else {
            Image(systemName: "checkmark.seal.fill")
          }
          Text(model.isApplying ? "Applying…" : "Apply")
            .font(.system(.body, design: .rounded).weight(.semibold))
        }
        .padding(.horizontal, 4)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.regular)
      .disabled(model.isApplying)
      .keyboardShortcut("s", modifiers: .command)
      .help("Apply — เขียนสีที่ตั้งไว้ลง settings.json ของ editor ที่เลือก (จะมี modal ยืนยันก่อนเขียน) (⌘S)")
    }
  }
}

// MARK: - Background

/// Pastel fallbacks used when no preset palette is available
/// (e.g. before first reload). Theme-driven colors take priority.
enum AppPalette {
  static let accent = Color(red: 0.74, green: 0.65, blue: 0.96)        // soft lavender
  static let accentSoft = Color(red: 0.86, green: 0.80, blue: 0.99)
  static let success = Color(red: 0.55, green: 0.85, blue: 0.70)       // pastel mint
  static let warning = Color(red: 0.98, green: 0.78, blue: 0.55)       // pastel peach
  static let danger = Color(red: 0.97, green: 0.62, blue: 0.70)        // pastel rose
  static let neutral = Color(red: 0.66, green: 0.70, blue: 0.82)       // soft slate
}

/// Theme-derived colors used by the app's own chrome.
/// They follow the loaded preset but contrast/readability stays correct
/// because we also flip `colorScheme` between dark/light themes.
extension ThemeModel {
  var isLightTheme: Bool {
    let raw = colors["bg0"] ?? "#000000"
    let nsc = nsColor(from: raw)
    let r = Double(nsc.redComponent)
    let g = Double(nsc.greenComponent)
    let b = Double(nsc.blueComponent)
    return (0.299 * r + 0.587 * g + 0.114 * b) > 0.5
  }

  var appColorScheme: ColorScheme { isLightTheme ? .light : .dark }

  private func themeColor(_ key: String, fallback: Color) -> Color {
    if let raw = colors[key] {
      return Color(nsColor: nsColor(from: raw))
    }
    return fallback
  }

  var appAccent: Color { themeColor("accent", fallback: AppPalette.accent) }
  var appAccentSoft: Color { themeColor("accentSoft", fallback: AppPalette.accentSoft) }
  var appBg0: Color { themeColor("bg0", fallback: Color(red: 0.108, green: 0.106, blue: 0.130)) }
  var appBg1: Color { themeColor("bg1", fallback: Color(red: 0.080, green: 0.078, blue: 0.098)) }
  var appBg2: Color { themeColor("bg2", fallback: Color(red: 0.13, green: 0.12, blue: 0.16)) }
  var appFg0: Color { themeColor("fg0", fallback: .primary) }
  var appFg1: Color { themeColor("fg1", fallback: .primary) }
  var appFg2: Color { themeColor("fg2", fallback: .secondary) }
  var appSuccess: Color { themeColor("green", fallback: AppPalette.success) }
  var appDanger: Color { themeColor("red", fallback: AppPalette.danger) }
  var appNeutral: Color { themeColor("muted", fallback: AppPalette.neutral) }
  var appBorder: Color { themeColor("border", fallback: AppPalette.accent) }

  /// Subtle text-tinted layer for "white opacity ..." replacements.
  /// In light theme, use black-tinted; in dark theme, white-tinted.
  func tintLayer(_ alpha: Double = 0.06) -> Color {
    isLightTheme ? Color.black.opacity(alpha) : Color.white.opacity(alpha)
  }
}

// MARK: - Environment-distributed theme chrome

struct ThemeChrome {
  let accent: Color
  let accentSoft: Color
  let success: Color
  let warning: Color
  let danger: Color
  let neutral: Color
  let bg0: Color
  let bg1: Color
  let bg2: Color
  let fg0: Color
  let fg1: Color
  let fg2: Color
  let isLight: Bool

  /// Subtle overlay tint that respects light/dark theme.
  /// Use instead of `.white.opacity(...)` for backgrounds/borders.
  func surface(_ alpha: Double = 0.06) -> Color {
    (isLight ? Color.black : Color.white).opacity(alpha)
  }

  static let fallback = ThemeChrome(
    accent: AppPalette.accent,
    accentSoft: AppPalette.accentSoft,
    success: AppPalette.success,
    warning: AppPalette.warning,
    danger: AppPalette.danger,
    neutral: AppPalette.neutral,
    bg0: Color(red: 0.108, green: 0.106, blue: 0.130),
    bg1: Color(red: 0.080, green: 0.078, blue: 0.098),
    bg2: Color(red: 0.13, green: 0.12, blue: 0.16),
    fg0: .primary,
    fg1: .primary,
    fg2: .secondary,
    isLight: false
  )

  @MainActor static func from(_ model: ThemeModel) -> ThemeChrome {
    ThemeChrome(
      accent: model.appAccent,
      accentSoft: model.appAccentSoft,
      success: model.appSuccess,
      warning: AppPalette.warning,
      danger: model.appDanger,
      neutral: model.appNeutral,
      bg0: model.appBg0,
      bg1: model.appBg1,
      bg2: model.appBg2,
      fg0: model.appFg0,
      fg1: model.appFg1,
      fg2: model.appFg2,
      isLight: model.isLightTheme
    )
  }
}

private struct ThemeChromeKey: EnvironmentKey {
  static let defaultValue: ThemeChrome = .fallback
}

extension EnvironmentValues {
  var themeChrome: ThemeChrome {
    get { self[ThemeChromeKey.self] }
    set { self[ThemeChromeKey.self] = newValue }
  }
}

/// App background that follows the loaded preset.
/// Uses theme bg0/bg1 with subtle accent glow at the corners.
struct AppBackground: View {
  @ObservedObject var model: ThemeModel

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [model.appBg0, model.appBg1],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      RadialGradient(
        colors: [model.appAccent.opacity(model.isLightTheme ? 0.06 : 0.08), .clear],
        center: .topLeading,
        startRadius: 0,
        endRadius: 600
      )
      RadialGradient(
        colors: [model.appAccentSoft.opacity(model.isLightTheme ? 0.05 : 0.06), .clear],
        center: .bottomTrailing,
        startRadius: 0,
        endRadius: 700
      )
    }
    .ignoresSafeArea()
  }
}

// MARK: - Target Menu (toolbar principal)

struct TargetMenu: View {
  @ObservedObject var model: ThemeModel
  @Environment(\.themeChrome) private var theme

  var body: some View {
    Menu {
      Section("Edit From") {
        ForEach(model.allTargets) { target in
          Button {
            model.setActiveTarget(target)
          } label: {
            HStack {
              if target.id == model.activeTargetID {
                Image(systemName: "checkmark")
              }
              Text(target.name)
              if target.isDetected { Text("· detected").foregroundStyle(.secondary) }
            }
          }
        }
      }
      Section("Apply To") {
        ForEach(model.allTargets) { target in
          Toggle(target.name, isOn: Binding(
            get: { model.targetApplyStates[target.id] ?? false },
            set: { model.targetApplyStates[target.id] = $0 }
          ))
        }
      }
    } label: {
      HStack(spacing: 8) {
        Circle()
          .fill(model.activeTarget.isDetected ? theme.success : Color.secondary.opacity(0.4))
          .frame(width: 8, height: 8)
        Text(model.activeTarget.name)
          .font(.system(.body, design: .rounded).weight(.semibold))
        Text("· \(model.applyTargets.count) target\(model.applyTargets.count == 1 ? "" : "s")")
          .foregroundStyle(.secondary)
          .font(.subheadline)
        Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundStyle(.secondary)
      }
      .padding(.horizontal, 12).padding(.vertical, 6)
      .background(theme.surface(0.06), in: Capsule())
    }
    .menuStyle(.borderlessButton)
    .frame(minWidth: 220)
    .help("เลือก editor ที่กำลังดู (Edit From) และเลือก editor ที่จะรับ Apply (Apply To) — เลือกได้หลายตัว")
  }
}

// MARK: - Sidebar

struct SidebarView: View {
  @ObservedObject var model: ThemeModel

  var body: some View {
    VStack(spacing: 0) {
      // ── Header ────────────────────────────────────────────
      HStack(spacing: 10) {
        AppMark(colors: model.colors)
          .frame(width: 32, height: 32)
        VStack(alignment: .leading, spacing: 1) {
          Text("Workbench Theme")
            .font(.system(.subheadline, design: .rounded).weight(.bold))
          Text("Editor color customization")
            .font(.system(size: 10))
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
      }
      .padding(14)

      Divider().opacity(0.4)

      // ── Scrollable content ────────────────────────────────
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          sectionLabel("PRESETS")
          PresetPicker(model: model)
            .padding(.horizontal, 12)

          Spacer().frame(height: 2)

          sectionLabel("CATEGORIES")
          VStack(spacing: 2) {
            ForEach(currentCategories) { cat in
              SidebarCategoryRow(
                category: cat,
                isSelected: isSelected(cat),
                action: { select(cat) }
              )
            }
          }
          .padding(.horizontal, 8)
        }
        .padding(.vertical, 12)
      }

      Divider().opacity(0.4)

      // ── Mode toggle (icon segmented at bottom) ────────────
      ModeIconPicker(model: model)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    .background(.ultraThinMaterial)
  }

  private var currentCategories: [ColorCategory] {
    model.mode == .base ? baseCategories : model.detailCategories
  }

  private func sectionLabel(_ title: String) -> some View {
    Text(title)
      .font(.system(size: 11, weight: .semibold))
      .foregroundStyle(.secondary)
      .padding(.horizontal, 16)
  }

  private func isSelected(_ cat: ColorCategory) -> Bool {
    model.mode == .base
      ? model.selectedBaseCategory.id == cat.id
      : model.selectedDetailCategoryID == cat.id
  }

  private func select(_ cat: ColorCategory) {
    if model.mode == .base {
      model.selectedBaseCategory = cat
    } else {
      model.selectedDetailCategoryID = cat.id
    }
    model.selectedKey = nil
  }
}

struct ModeIconPicker: View {
  @ObservedObject var model: ThemeModel
  @Environment(\.themeChrome) private var theme

  var body: some View {
    HStack(spacing: 6) {
      ForEach(EditorMode.allCases) { mode in
        let selected = model.mode == mode
        Button {
          if model.mode != mode {
            model.mode = mode
            model.selectedKey = nil
          }
        } label: {
          HStack(spacing: 6) {
            Image(systemName: mode.icon)
              .font(.system(size: 11, weight: .semibold))
            Text(mode.shortLabel)
              .font(.system(.caption, design: .rounded).weight(.semibold))
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 7)
          .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
              .fill(selected ? theme.accent.opacity(0.22) : .clear)
          )
          .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
              .stroke(selected ? theme.accent.opacity(0.5) : theme.surface(0.06))
          )
          .foregroundStyle(selected ? theme.accent : .secondary)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(modeTooltip(mode))
      }
    }
    .padding(4)
    .background(
      RoundedRectangle(cornerRadius: 9, style: .continuous)
        .fill(theme.surface(0.04))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 9, style: .continuous)
        .stroke(theme.surface(0.06))
    )
  }

  private func modeTooltip(_ mode: EditorMode) -> String {
    switch mode {
    case .base:
      return "Palette — แก้สีหลักของธีม (bg0, accent, blue, ฯลฯ) เปลี่ยนทีเดียวกระทบทุก key ที่ใช้ตัวแปรนั้น"
    case .detailed:
      return "Detailed — แก้สีของ workbench key รายตัว (override ตัวที่ palette สร้างให้)"
    }
  }
}

struct SidebarCategoryRow: View {
  let category: ColorCategory
  let isSelected: Bool
  let action: () -> Void
  @Environment(\.themeChrome) private var theme

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: category.symbol)
          .font(.system(size: 13, weight: .medium))
          .frame(width: 22, height: 22)
          .foregroundStyle(isSelected ? theme.accent : .secondary)
        VStack(alignment: .leading, spacing: 1) {
          Text(category.title)
            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
        }
        Spacer(minLength: 4)
        Text("\(category.keys.count)")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 6).padding(.vertical, 1)
          .background(theme.surface(0.07), in: Capsule())
      }
      .padding(.horizontal, 10).padding(.vertical, 7)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(isSelected ? theme.accent.opacity(0.16) : .clear)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

struct PresetPicker: View {
  @ObservedObject var model: ThemeModel
  @State private var pickerOpen = false
  @State private var search = ""
  @State private var showSavePreset = false
  @Environment(\.themeChrome) private var theme

  private static let swatchKeys = ["bg0", "accent", "blue", "green", "red", "purple"]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Selected preset trigger
      Button {
        pickerOpen.toggle()
      } label: {
        HStack(spacing: 8) {
          PresetSwatchRow(preset: model.selectedPreset, height: 16)
            .frame(width: 78)
          VStack(alignment: .leading, spacing: 1) {
            Text(model.selectedPreset.id)
              .font(.system(.footnote, design: .rounded).weight(.semibold))
              .lineLimit(1)
              .foregroundStyle(.primary)
            Text("\(presets.count) presets")
              .font(.system(size: 9, weight: .medium))
              .foregroundStyle(.secondary)
          }
          Spacer(minLength: 0)
          Image(systemName: "chevron.down")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(pickerOpen ? 180 : 0))
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(
          RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(theme.surface(0.06))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 9, style: .continuous)
            .stroke(theme.surface(pickerOpen ? 0.2 : 0.08))
        )
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .help("เปิดรายการ Preset ทั้งหมด — เลือก preset แล้วโหลด palette + preview ทันที")
      .popover(isPresented: $pickerOpen, arrowEdge: .bottom) {
        PresetPickerPopover(
          model: model,
          search: $search,
          isOpen: $pickerOpen
        )
      }

      // Save current state as user preset
      Button {
        showSavePreset = true
      } label: {
        HStack(spacing: 5) {
          Image(systemName: "plus.circle")
          Text("บันทึกเป็น Preset")
            .font(.system(.caption, design: .rounded).weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .foregroundStyle(theme.accent)
        .background(theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(theme.accent.opacity(0.3)))
      }
      .buttonStyle(.plain)
      .help("บันทึก palette ปัจจุบันเป็น preset ของคุณเอง — เรียกใช้ภายหลังได้เร็วขึ้น")
      .sheet(isPresented: $showSavePreset) {
        SavePresetSheet(model: model, isOpen: $showSavePreset)
      }
    }
  }
}

// Mini swatch row reused in trigger and rows
struct PresetSwatchRow: View {
  let preset: ThemePreset
  let height: CGFloat
  @Environment(\.themeChrome) private var theme
  private let keys = ["bg0", "accent", "blue", "green", "red", "purple"]

  var body: some View {
    HStack(spacing: 2) {
      ForEach(keys, id: \.self) { k in
        let v = preset.colors[k] ?? "#000000"
        RoundedRectangle(cornerRadius: 3, style: .continuous)
          .fill(Color(nsColor: nsColor(from: v)))
          .frame(height: height)
          .overlay(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
              .stroke(theme.surface(0.16))
          )
      }
    }
  }
}

enum PresetFilter: String, CaseIterable, Identifiable {
  case all = "All"
  case dark = "Dark"
  case light = "Light"
  var id: String { rawValue }
  var icon: String {
    switch self {
    case .all: return "square.grid.2x2"
    case .dark: return "moon.fill"
    case .light: return "sun.max.fill"
    }
  }
}

// Custom popover content
struct PresetPickerPopover: View {
  @ObservedObject var model: ThemeModel
  @Binding var search: String
  @Binding var isOpen: Bool
  @State private var filter: PresetFilter = .all
  @Environment(\.themeChrome) private var theme

  private var filtered: [ThemePreset] {
    var result = presets
    if !search.isEmpty {
      let q = search.lowercased()
      result = result.filter { $0.id.lowercased().contains(q) }
    }
    switch filter {
    case .all: break
    case .dark: result = result.filter { !$0.isLight }
    case .light: result = result.filter { $0.isLight }
    }
    return result
  }

  private var darkPresets: [ThemePreset] { filtered.filter { !$0.isLight } }
  private var lightPresets: [ThemePreset] { filtered.filter { $0.isLight } }

  var body: some View {
    VStack(spacing: 0) {
      // Search bar
      HStack(spacing: 6) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
        TextField("Search presets…", text: $search)
          .textFieldStyle(.plain)
          .font(.callout)
        if !search.isEmpty {
          Button { search = "" } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 10).padding(.vertical, 8)
      .background(theme.surface(0.04))

      // Filter pills
      HStack(spacing: 6) {
        ForEach(PresetFilter.allCases) { f in
          let count = countFor(f)
          Button {
            filter = f
          } label: {
            HStack(spacing: 5) {
              Image(systemName: f.icon).font(.system(size: 9, weight: .semibold))
              Text(f.rawValue).font(.system(.caption, design: .rounded).weight(.semibold))
              Text("\(count)")
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 4).padding(.vertical, 1)
                .background(theme.surface(0.1), in: Capsule())
            }
            .padding(.horizontal, 9).padding(.vertical, 5)
            .background(
              Capsule().fill(filter == f ? theme.accent.opacity(0.22) : theme.surface(0.04))
            )
            .overlay(
              Capsule().stroke(filter == f ? theme.accent.opacity(0.5) : theme.surface(0.06))
            )
            .foregroundStyle(filter == f ? theme.accent : .secondary)
            .contentShape(Capsule())
          }
          .buttonStyle(.plain)
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 10).padding(.vertical, 7)
      Divider().opacity(0.4)

      // Preset list (grouped)
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 8) {
          if filtered.isEmpty {
            VStack(spacing: 6) {
              Image(systemName: "paintpalette")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.secondary)
              Text("No matching presets")
                .font(.callout).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
          } else {
            if !model.userPresets.isEmpty && search.isEmpty {
              groupHeader("MY PRESETS", icon: "heart.fill", count: model.userPresets.count)
              VStack(spacing: 4) {
                ForEach(model.userPresets, id: \.id) { spec in
                  userPresetRow(spec)
                }
              }
            }
            if !darkPresets.isEmpty {
              groupHeader("DARK", icon: "moon.fill", count: darkPresets.count)
                .padding(.top, !model.userPresets.isEmpty && search.isEmpty ? 4 : 0)
              VStack(spacing: 4) {
                ForEach(darkPresets) { preset in
                  presetRow(preset)
                }
              }
            }
            if !lightPresets.isEmpty {
              groupHeader("LIGHT", icon: "sun.max.fill", count: lightPresets.count)
                .padding(.top, !darkPresets.isEmpty ? 4 : 0)
              VStack(spacing: 4) {
                ForEach(lightPresets) { preset in
                  presetRow(preset)
                }
              }
            }
          }
        }
        .padding(8)
      }
      .frame(width: 320, height: 400)

      // Footer count
      HStack {
        Text("\(filtered.count) of \(presets.count)")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Button("Close") { isOpen = false }
          .controlSize(.small)
          .keyboardShortcut(.cancelAction)
      }
      .padding(.horizontal, 12).padding(.vertical, 8)
      .background(theme.surface(0.04))
    }
  }

  private func countFor(_ f: PresetFilter) -> Int {
    let base: [ThemePreset]
    if !search.isEmpty {
      let q = search.lowercased()
      base = presets.filter { $0.id.lowercased().contains(q) }
    } else {
      base = presets
    }
    switch f {
    case .all: return base.count
    case .dark: return base.filter { !$0.isLight }.count
    case .light: return base.filter { $0.isLight }.count
    }
  }

  private func groupHeader(_ title: String, icon: String, count: Int) -> some View {
    HStack(spacing: 6) {
      Image(systemName: icon).font(.system(size: 9, weight: .semibold))
      Text(title)
        .font(.system(size: 10, weight: .bold, design: .rounded))
        .tracking(0.6)
      Text("· \(count)")
        .font(.system(size: 10, weight: .medium))
    }
    .foregroundStyle(.secondary)
    .padding(.horizontal, 6).padding(.top, 4).padding(.bottom, 2)
  }

  private func presetRow(_ preset: ThemePreset) -> some View {
    PresetCardRow(
      preset: preset,
      isSelected: preset.id == model.selectedPreset.id,
      action: {
        model.selectedPreset = preset
        model.loadPreset()
        isOpen = false
      }
    )
  }

  private func userPresetRow(_ spec: UserPresetSpec) -> some View {
    UserPresetCardRow(
      spec: spec,
      onSelect: {
        model.applyUserPreset(spec)
        isOpen = false
      },
      onDelete: { model.removeUserPreset(id: spec.id) }
    )
  }
}

// MARK: - User preset card row

struct UserPresetCardRow: View {
  let spec: UserPresetSpec
  let onSelect: () -> Void
  let onDelete: () -> Void
  @Environment(\.themeChrome) private var theme

  private let keys = ["bg0", "bg1", "fg0", "accent", "accentSoft", "blue", "green", "red"]

  var body: some View {
    HStack(spacing: 10) {
      Button(action: onSelect) {
        HStack(spacing: 10) {
          // Mini swatch grid
          HStack(spacing: 2) {
            ForEach(keys.prefix(8), id: \.self) { k in
              let v = spec.colors[k] ?? "#000000"
              RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(nsColor: nsColor(from: v)))
                .frame(width: 14, height: 32)
                .overlay(RoundedRectangle(cornerRadius: 2.5).stroke(theme.surface(0.15)))
            }
          }
          VStack(alignment: .leading, spacing: 3) {
            Text(spec.name).font(.system(.callout, design: .rounded).weight(.semibold))
            Text("USER PRESET")
              .font(.system(size: 9, weight: .bold))
              .foregroundStyle(theme.accent)
          }
          Spacer(minLength: 0)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface(0.04), in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(theme.surface(0.06)))
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)

      Button(action: onDelete) {
        Image(systemName: "trash").font(.system(size: 11))
      }
      .buttonStyle(.borderless)
      .foregroundStyle(theme.danger)
      .help("ลบ preset นี้ออกจากรายการ (ลบแล้วกู้คืนไม่ได้)")
    }
  }
}

struct PresetCardRow: View {
  let preset: ThemePreset
  let isSelected: Bool
  let action: () -> Void
  @Environment(\.themeChrome) private var theme

  // Slightly wider preview using extra palette keys
  private let keys = ["bg0", "bg1", "fg0", "accent", "accentSoft", "blue", "green", "red", "purple", "border"]

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        // Big swatch tile that mimics tiny editor preview
        miniPreview
          .frame(width: 64, height: 40)
          .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
              .stroke(theme.surface(0.14))
          )

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(preset.id)
              .font(.system(.callout, design: .rounded).weight(.semibold))
              .foregroundStyle(.primary)
            if isSelected {
              Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(theme.accent)
            }
            Spacer(minLength: 0)
          }
          // Compact swatch row
          HStack(spacing: 3) {
            ForEach(keys.prefix(8), id: \.self) { k in
              let v = preset.colors[k] ?? "#000000"
              RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                .fill(Color(nsColor: nsColor(from: v)))
                .frame(width: 14, height: 10)
                .overlay(
                  RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .stroke(theme.surface(0.15))
                )
            }
          }
        }
      }
      .padding(8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 9, style: .continuous)
          .fill(isSelected ? theme.accent.opacity(0.18) : theme.surface(0.025))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 9, style: .continuous)
          .stroke(isSelected ? theme.accent.opacity(0.4) : theme.surface(0.06))
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  // Mini visual: a tiny "editor card" using preset colors
  private var miniPreview: some View {
    let bg0 = Color(nsColor: nsColor(from: preset.colors["bg0"] ?? "#000"))
    let bg1 = Color(nsColor: nsColor(from: preset.colors["bg1"] ?? "#000"))
    let accent = Color(nsColor: nsColor(from: preset.colors["accent"] ?? "#FFF"))
    let fg0 = Color(nsColor: nsColor(from: preset.colors["fg0"] ?? "#FFF"))
    let blue = Color(nsColor: nsColor(from: preset.colors["blue"] ?? "#0AF"))
    let green = Color(nsColor: nsColor(from: preset.colors["green"] ?? "#0F0"))
    let purple = Color(nsColor: nsColor(from: preset.colors["purple"] ?? "#A0F"))
    let red = Color(nsColor: nsColor(from: preset.colors["red"] ?? "#F33"))

    return ZStack(alignment: .topLeading) {
      bg0
      // sidebar strip
      HStack(spacing: 0) {
        bg1.frame(width: 14)
        Spacer(minLength: 0)
      }
      // accent dot (top-left tab indicator)
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 2) {
          Spacer().frame(width: 18)
          Capsule().fill(accent).frame(width: 12, height: 2)
        }
        // mock code lines
        Group {
          line(start: 18, lengths: [8, 14], colors: [accent, blue])
          line(start: 18, lengths: [10, 12, 8], colors: [purple, fg0, green])
          line(start: 18, lengths: [6, 16], colors: [accent, red])
          line(start: 18, lengths: [12, 10], colors: [blue, fg0])
        }
      }
      .padding(.top, 5)
    }
  }

  private func line(start: CGFloat, lengths: [CGFloat], colors: [Color]) -> some View {
    HStack(spacing: 2) {
      Spacer().frame(width: start - 16)
      ForEach(Array(zip(lengths.indices, lengths)), id: \.0) { i, len in
        Capsule().fill(colors[i % colors.count]).frame(width: len, height: 2)
      }
      Spacer(minLength: 0)
    }
  }
}

// MARK: - Detail Container

struct DetailContainer: View {
  @ObservedObject var model: ThemeModel

  var body: some View {
    VStack(spacing: 0) {
      DetailHeader(model: model)
      Divider().opacity(0.4)

      HStack(spacing: 0) {
        ColorListView(model: model)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        if model.showInspector {
          Divider().opacity(0.4)
          InspectorView(model: model)
            .frame(width: 380)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
      }
      .animation(.easeInOut(duration: 0.18), value: model.showInspector)

      Divider().opacity(0.4)
      StatusBar(model: model)
    }
  }
}

struct DetailHeader: View {
  @ObservedObject var model: ThemeModel
  @FocusState private var filterFocused: Bool
  @Environment(\.themeChrome) private var theme

  var body: some View {
    HStack(alignment: .center, spacing: 14) {
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 8) {
          Image(systemName: currentCategory.symbol)
            .foregroundStyle(.secondary)
            .font(.system(size: 14))
          Text(currentCategory.title)
            .font(.system(.title3, design: .rounded).weight(.semibold))
          Text("·").foregroundStyle(.secondary)
          Text("\(visibleCount) keys")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          if model.mode == .detailed && model.detailOverrides.count > 0 {
            Text("·").foregroundStyle(.secondary)
            Label("\(model.detailOverrides.count) custom", systemImage: "checkmark.seal.fill")
              .labelStyle(.titleAndIcon)
              .font(.caption.weight(.semibold))
              .padding(.horizontal, 8).padding(.vertical, 3)
              .foregroundStyle(theme.success)
              .background(theme.success.opacity(0.15), in: Capsule())
          }
        }
        Text(currentCategory.subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer(minLength: 12)

      // Filter
      HStack(spacing: 6) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
        TextField("Filter keys…", text: $model.filterText)
          .textFieldStyle(.plain)
          .focused($filterFocused)
          .frame(width: 200)
        if !model.filterText.isEmpty {
          Button {
            model.filterText = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 10).padding(.vertical, 6)
      .background(theme.surface(0.06), in: RoundedRectangle(cornerRadius: 8))
      .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.surface(filterFocused ? 0.2 : 0.08)))
      .help("ค้นหาสีในกลุ่มนี้ — พิมพ์ชื่อ key หรือชื่อภาษาไทยที่อธิบาย")

      if model.mode == .detailed {
        Menu {
          Button("Reset This Group") { model.clearOverridesInSelectedGroup() }
            .disabled(model.detailOverrides.isEmpty)
          Button("Reset All Custom", role: .destructive) { model.clearAllOverrides() }
            .disabled(model.detailOverrides.isEmpty)
        } label: {
          Image(systemName: "ellipsis.circle")
            .font(.system(size: 14))
        }
        .menuStyle(.borderlessButton)
        .frame(width: 28)
        .help("เมนูสำหรับรีเซ็ตค่า override ในกลุ่มนี้")
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
  }

  private var currentCategory: ColorCategory {
    model.mode == .base ? model.selectedBaseCategory : model.selectedDetailCategory
  }

  private var visibleCount: Int {
    model.mode == .base ? model.filteredBaseKeys.count : model.filteredDetailKeys.count
  }
}

// MARK: - Color List

struct ColorListView: View {
  @ObservedObject var model: ThemeModel

  var body: some View {
    ScrollView {
      LazyVStack(spacing: 4) {
        let keys = model.mode == .base ? model.filteredBaseKeys : model.filteredDetailKeys
        if keys.isEmpty {
          EmptyStateView(model: model)
            .padding(.top, 40)
        } else {
          ForEach(keys, id: \.self) { key in
            CompactColorRow(
              model: model,
              keyName: key,
              isBase: model.mode == .base
            )
          }
        }
      }
      .padding(14)
    }
  }
}

struct EmptyStateView: View {
  @ObservedObject var model: ThemeModel
  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 32, weight: .light))
        .foregroundStyle(.secondary)
      Text("No matching keys")
        .font(.headline)
      Text(model.filterText.isEmpty ? "This category is empty." : "Try a different filter.")
        .font(.callout)
        .foregroundStyle(.secondary)
      if !model.filterText.isEmpty {
        Button("Clear filter") { model.filterText = "" }
          .buttonStyle(.bordered)
          .padding(.top, 4)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 30)
  }
}

struct CompactColorRow: View {
  @ObservedObject var model: ThemeModel
  let keyName: String
  let isBase: Bool
  @Environment(\.themeChrome) private var theme

  var body: some View {
    let value = Binding<String>(
      get: { currentValue },
      set: { write($0.uppercased()) }
    )
    let picker = Binding<Color>(
      get: { Color(nsColor: nsColor(from: currentValue)) },
      set: { write(hex(from: NSColor($0), alphaSuffix: alphaSuffix(currentValue))) }
    )
    let selected = model.selectedKey == keyName

    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 7, style: .continuous)
        .fill(Color(nsColor: nsColor(from: currentValue)))
        .frame(width: 38, height: 38)
        .overlay(
          RoundedRectangle(cornerRadius: 7, style: .continuous)
            .stroke(theme.surface(0.18))
        )
        .shadow(color: Color(nsColor: nsColor(from: currentValue)).opacity(0.16), radius: 4, y: 2)

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(displayTitle)
            .font(.system(size: 13, weight: .semibold))
          if isOverride {
            Text("custom")
              .font(.system(size: 9, weight: .bold))
              .padding(.horizontal, 5).padding(.vertical, 1)
              .background(theme.success.opacity(0.18), in: Capsule())
              .foregroundStyle(theme.success)
          }
          if isBase {
            Text("$\(keyName)")
              .font(.system(size: 9, design: .monospaced).weight(.semibold))
              .padding(.horizontal, 5).padding(.vertical, 1)
              .background(theme.surface(0.07), in: Capsule())
              .foregroundStyle(.secondary)
          }
        }
        Text(displaySubtitle)
          .font(.system(size: 11))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      Spacer(minLength: 10)

      TextField("#RRGGBB", text: value)
        .font(.system(.caption, design: .monospaced))
        .textFieldStyle(.roundedBorder)
        .frame(width: 102)

      ColorPicker("", selection: picker, supportsOpacity: false)
        .labelsHidden()
        .frame(width: 30)

      if !isBase {
        Button {
          model.detailOverrides.removeValue(forKey: keyName)
          model.status = "Reset \(keyName) to palette-generated value"
        } label: {
          Image(systemName: "arrow.counterclockwise")
            .font(.system(size: 11))
        }
        .buttonStyle(.plain)
        .frame(width: 24, height: 24)
        .background(theme.surface(isOverride ? 0.06 : 0), in: Circle())
        .disabled(!isOverride)
        .opacity(isOverride ? 1 : 0.25)
        .help("ลบค่า custom ของ key นี้ — จะกลับไปใช้สีจาก palette อัตโนมัติ")
      }
    }
    .padding(.horizontal, 12).padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(selected ? theme.surface(0.08) : theme.surface(0.025))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(selected ? theme.accent.opacity(0.5) : theme.surface(0.06))
    )
    .contentShape(Rectangle())
    .onTapGesture { model.selectedKey = keyName }
  }

  // MARK: helpers

  private var currentValue: String {
    if isBase { return model.colors[keyName] ?? "#000000" }
    return model.detailOverrides[keyName] ?? model.detailColors[keyName] ?? "#000000"
  }

  private func write(_ value: String) {
    if isBase {
      model.colors[keyName] = value
    } else {
      model.detailColors[keyName] = value
      model.detailOverrides[keyName] = value
    }
  }

  private var isOverride: Bool {
    !isBase && model.detailOverrides[keyName] != nil
  }

  private var displayTitle: String {
    isBase ? (colorMeta[keyName]?.title ?? keyName) : settingTitle(keyName)
  }

  private var displaySubtitle: String {
    if isBase { return colorMeta[keyName]?.subtitle ?? "" }
    return keyName
  }
}

// MARK: - Inspector

struct InspectorView: View {
  @ObservedObject var model: ThemeModel

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        section("LIVE PREVIEW · \(model.activeTarget.name)") {
          IDEPreview(model: model)
        }
        section("PALETTE") {
          PaletteGrid(model: model)
        }
        section("INSPECTOR") {
          SelectedKeyInfo(model: model)
        }
      }
      .padding(16)
    }
    .background(.ultraThinMaterial)
  }

  private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(.secondary)
      content()
    }
  }
}

// MARK: - Cute IDE Preview

struct IDEPreview: View {
  @ObservedObject var model: ThemeModel

  // Fetch a workbench color through the model's preview chain.
  private func c(_ key: String, palette: String? = nil, literal: String = "#000000") -> NSColor {
    nsColor(from: model.previewHex(key, palette: palette, literal: literal))
  }
  private func p(_ key: String, _ fallback: String) -> NSColor {
    nsColor(from: model.colors[key] ?? fallback)
  }

  var body: some View {
    let editorBg = c("editor.background", palette: "bg0", literal: "#08060F")
    let sidebarBg = c("sideBar.background", palette: "bg1", literal: "#100B1F")
    let activityBg = c("activityBar.background", palette: "bg0", literal: "#08060F")
    let titleBg = c("titleBar.activeBackground", palette: "bg0", literal: "#08060F")
    let titleFg = c("titleBar.activeForeground", palette: "fg1", literal: "#E9D7FF")
    let tabActiveBg = c("tab.activeBackground", palette: "bg0", literal: "#08060F")
    let tabInactiveBg = c("tab.inactiveBackground", palette: "bg1", literal: "#100B1F")
    let tabsStripBg = c("editorGroupHeader.tabsBackground", palette: "bg0", literal: "#08060F")
    let tabBorderTop = c("tab.activeBorderTop", palette: "accent", literal: "#FF4FD8")
    let statusBg = c("statusBar.background", palette: "bg0", literal: "#08060F")
    let statusRemoteBg = c("statusBarItem.remoteBackground", palette: "accent", literal: "#FF4FD8")
    let statusRemoteFg = c("statusBarItem.remoteForeground", palette: "bg0", literal: "#08060F")
    let lineHighlight = c("editor.lineHighlightBackground", literal: "#FFFFFF10")
    let gitModified = c("gitDecoration.modifiedResourceForeground", palette: "accent", literal: "#FF4FD8")
    let gitAdded = c("gitDecoration.addedResourceForeground", palette: "green", literal: "#5CFF95")
    let badgeBg = c("activityBarBadge.background", palette: "accent", literal: "#FF4FD8")

    // Foreground / syntax palette
    let synAccent = p("accent", "#FF4FD8")
    let synBlue = p("blue", "#00D4FF")
    let synGreen = p("green", "#5CFF95")
    let synPurple = p("purple", "#C77DFF")
    let synMuted = p("muted", "#7C6A99")
    let synFg0 = p("fg0", "#FFF7FF")
    let synFg1 = p("fg1", "#E9D7FF")
    let muted2 = p("muted2", "#534566")

    VStack(alignment: .leading, spacing: 0) {
      // ── Title bar (slim) ─────────────────────────────────────
      HStack(spacing: 4) {
        HStack(spacing: 3) {
          Circle().fill(Color(red: 1.0, green: 0.37, blue: 0.36)).frame(width: 6, height: 6)
          Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.18)).frame(width: 6, height: 6)
          Circle().fill(Color(red: 0.16, green: 0.78, blue: 0.27)).frame(width: 6, height: 6)
        }
        Spacer(minLength: 0)
        Text(model.activeTarget.name)
          .font(.system(size: 7, weight: .semibold, design: .rounded))
          .foregroundStyle(Color(nsColor: titleFg).opacity(0.7))
        Spacer(minLength: 0)
        Color.clear.frame(width: 24, height: 6)
      }
      .padding(.horizontal, 8).padding(.vertical, 5)
      .background(Color(nsColor: titleBg))

      // ── Main split ───────────────────────────────────────────
      HStack(spacing: 0) {
        // Activity bar (very slim)
        VStack(spacing: 9) {
          dotIcon("square.grid.2x2.fill", isActive: true, accent: synAccent, mute: synFg1)
          dotIcon("magnifyingglass", isActive: false, accent: synAccent, mute: synFg1)
          ZStack(alignment: .topTrailing) {
            dotIcon("arrow.triangle.branch", isActive: false, accent: synAccent, mute: synFg1)
            Circle().fill(Color(nsColor: badgeBg)).frame(width: 4, height: 4).offset(x: 2, y: -2)
          }
          dotIcon("puzzlepiece.extension.fill", isActive: false, accent: synAccent, mute: synFg1)
          Spacer()
          dotIcon("gearshape.fill", isActive: false, accent: synAccent, mute: synFg1)
        }
        .padding(.vertical, 8)
        .frame(width: 22)
        .background(Color(nsColor: activityBg))

        // Sidebar (compact)
        VStack(alignment: .leading, spacing: 3) {
          Text("FILES")
            .font(.system(size: 6, weight: .bold, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(Color(nsColor: muted2))
            .padding(.horizontal, 8).padding(.top, 7).padding(.bottom, 1)

          fileChip("App.tsx", dotColor: Color(nsColor: gitModified), selected: false, fg: synFg1)
          fileChip("preview.tsx", dotColor: nil, selected: true, fg: synFg0, selectedAccent: synAccent)
          fileChip("utils.ts", dotColor: Color(nsColor: gitAdded), selected: false, fg: synFg1)
          fileChip("hooks.ts", dotColor: nil, selected: false, fg: synFg1)
          fileChip("README.md", dotColor: nil, selected: false, fg: synFg1)

          Spacer()

          HStack(spacing: 4) {
            ForEach(["accent", "blue", "green", "purple"], id: \.self) { k in
              Circle()
                .fill(Color(nsColor: nsColor(from: model.colors[k] ?? "#FFFFFF")))
                .frame(width: 5, height: 5)
            }
          }
          .padding(.horizontal, 8).padding(.bottom, 7)
        }
        .frame(width: 88)
        .background(Color(nsColor: sidebarBg))

        // Editor area
        VStack(spacing: 0) {
          // Tab strip — multi-tab
          HStack(spacing: 0) {
            previewTab(name: "App.tsx", active: false, modified: true,
                       activeBg: tabActiveBg, inactiveBg: tabInactiveBg,
                       borderTop: tabBorderTop, fg0: synFg0, fg1: synFg1, accent: synAccent)
            previewTab(name: "preview.tsx", active: true, modified: false,
                       activeBg: tabActiveBg, inactiveBg: tabInactiveBg,
                       borderTop: tabBorderTop, fg0: synFg0, fg1: synFg1, accent: synAccent)
            previewTab(name: "utils.ts", active: false, modified: false,
                       activeBg: tabActiveBg, inactiveBg: tabInactiveBg,
                       borderTop: tabBorderTop, fg0: synFg0, fg1: synFg1, accent: synAccent)
            // Trailing strip filler so the row feels like the real chrome
            Rectangle()
              .fill(Color(nsColor: tabsStripBg))
              .frame(maxWidth: .infinity)
          }
          .frame(height: 18)
          .background(Color(nsColor: tabsStripBg))

          // Code body — small, dense
          VStack(alignment: .leading, spacing: 0) {
            codeLine(num: 1, tokens: [("// hello, theme ✨", synMuted)], active: false, hl: lineHighlight, gutterFg: muted2, gutterActive: synAccent)
            codeLine(num: 2, tokens: [("import ", synAccent), ("React", synBlue), (" from ", synAccent), ("\"react\"", synGreen)], active: false, hl: lineHighlight, gutterFg: muted2, gutterActive: synAccent)
            codeLine(num: 3, tokens: [("import ", synAccent), ("{ ", synFg1), ("useState", synBlue), (" } ", synFg1), ("from ", synAccent), ("\"react\"", synGreen)], active: false, hl: lineHighlight, gutterFg: muted2, gutterActive: synAccent)
            codeLine(num: 4, tokens: [], active: false, hl: lineHighlight, gutterFg: muted2, gutterActive: synAccent)
            codeLine(num: 5, tokens: [("export ", synAccent), ("function ", synAccent), ("Hello", synBlue), ("() {", synFg1)], active: true, hl: lineHighlight, gutterFg: muted2, gutterActive: synAccent)
            codeLine(num: 6, tokens: [("  const ", synAccent), ("[count, setCount]", synFg0), (" = ", synFg1), ("useState", synBlue), ("(", synFg1), ("0", synPurple), (")", synFg1)], active: false, hl: lineHighlight, gutterFg: muted2, gutterActive: synAccent)
            codeLine(num: 7, tokens: [("  return ", synAccent), ("<", synFg1), ("p", synBlue), (">", synFg1), ("Hi 👋", synFg0), ("</", synFg1), ("p", synBlue), (">", synFg1)], active: false, hl: lineHighlight, gutterFg: muted2, gutterActive: synAccent)
            codeLine(num: 8, tokens: [("}", synFg1)], active: false, hl: lineHighlight, gutterFg: muted2, gutterActive: synAccent)
            Spacer(minLength: 0)
          }
          .padding(.top, 2).padding(.bottom, 4)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
          .background(Color(nsColor: editorBg))
        }
      }
      .frame(maxHeight: .infinity)

      // ── Status bar (slim) ────────────────────────────────────
      HStack(spacing: 0) {
        HStack(spacing: 3) {
          Image(systemName: "arrow.triangle.branch")
            .font(.system(size: 6, weight: .bold))
          Text("main")
            .font(.system(size: 7, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(Color(nsColor: statusRemoteBg))
        .foregroundStyle(Color(nsColor: statusRemoteFg))

        Spacer(minLength: 0)

        HStack(spacing: 8) {
          HStack(spacing: 2) {
            Circle().fill(Color(nsColor: synGreen)).frame(width: 4, height: 4)
            Text("0").font(.system(size: 7, weight: .medium, design: .rounded))
          }
          HStack(spacing: 2) {
            Circle().fill(Color(nsColor: gitModified)).frame(width: 4, height: 4)
            Text("2").font(.system(size: 7, weight: .medium, design: .rounded))
          }
          Text("TSX")
            .font(.system(size: 7, weight: .semibold, design: .rounded))
            .padding(.horizontal, 5).padding(.vertical, 1)
            .background(Color(nsColor: synBlue).opacity(0.18), in: Capsule())
            .foregroundStyle(Color(nsColor: synBlue))
        }
        .foregroundStyle(Color(nsColor: synFg1).opacity(0.7))
        .padding(.trailing, 8)
      }
      .background(Color(nsColor: statusBg))
    }
    .frame(height: 220)
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .stroke(.white.opacity(0.08), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.35), radius: 14, y: 5)
  }

  // MARK: - Subviews

  @ViewBuilder
  private func dotIcon(_ name: String, isActive: Bool, accent: NSColor, mute: NSColor) -> some View {
    ZStack {
      if isActive {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .fill(Color(nsColor: accent).opacity(0.18))
          .frame(width: 14, height: 14)
      }
      Image(systemName: name)
        .font(.system(size: 7, weight: .semibold))
        .foregroundStyle(Color(nsColor: isActive ? accent : mute).opacity(isActive ? 1 : 0.55))
    }
  }

  @ViewBuilder
  private func fileChip(_ name: String, dotColor: Color?, selected: Bool, fg: NSColor, selectedAccent: NSColor = .clear) -> some View {
    HStack(spacing: 4) {
      RoundedRectangle(cornerRadius: 1.5)
        .fill(Color(nsColor: fg).opacity(0.6))
        .frame(width: 5, height: 6)
      Text(name)
        .font(.system(size: 7, weight: selected ? .semibold : .regular, design: .rounded))
        .foregroundStyle(Color(nsColor: fg).opacity(selected ? 1 : 0.7))
        .lineLimit(1)
      Spacer(minLength: 0)
      if let d = dotColor {
        Circle().fill(d).frame(width: 3, height: 3)
      }
    }
    .padding(.horizontal, 6).padding(.vertical, 3)
    .background(
      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .fill(selected ? Color(nsColor: selectedAccent).opacity(0.18) : .clear)
    )
    .padding(.horizontal, 4)
  }

  @ViewBuilder
  private func previewTab(
    name: String,
    active: Bool,
    modified: Bool,
    activeBg: NSColor,
    inactiveBg: NSColor,
    borderTop: NSColor,
    fg0: NSColor,
    fg1: NSColor,
    accent: NSColor
  ) -> some View {
    HStack(spacing: 4) {
      // tiny doc icon
      RoundedRectangle(cornerRadius: 1)
        .fill(Color(nsColor: active ? fg0 : fg1).opacity(active ? 0.85 : 0.5))
        .frame(width: 4, height: 5)
      Text(name)
        .font(.system(size: 7, weight: active ? .semibold : .regular, design: .rounded))
        .foregroundStyle(Color(nsColor: active ? fg0 : fg1).opacity(active ? 1 : 0.6))
        .lineLimit(1)
      if modified {
        Circle()
          .fill(Color(nsColor: accent))
          .frame(width: 4, height: 4)
      } else {
        Image(systemName: "xmark")
          .font(.system(size: 5, weight: .medium))
          .foregroundStyle(Color(nsColor: fg1).opacity(active ? 0.6 : 0.35))
      }
    }
    .padding(.horizontal, 6)
    .frame(height: 18)
    .background(Color(nsColor: active ? activeBg : inactiveBg))
    .overlay(alignment: .top) {
      Rectangle()
        .fill(active ? Color(nsColor: borderTop) : Color.clear)
        .frame(height: 1.2)
    }
    .overlay(alignment: .trailing) {
      // subtle separator between tabs
      Rectangle()
        .fill(.white.opacity(0.06))
        .frame(width: 0.5)
    }
  }

  @ViewBuilder
  private func codeLine(num: Int, tokens: [(String, NSColor)], active: Bool, hl: NSColor, gutterFg: NSColor, gutterActive: NSColor) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 4) {
      Text("\(num)")
        .font(.system(size: 6, design: .monospaced))
        .foregroundStyle(Color(nsColor: active ? gutterActive : gutterFg).opacity(active ? 1 : 0.55))
        .frame(width: 10, alignment: .trailing)
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        ForEach(Array(tokens.enumerated()), id: \.offset) { _, tok in
          Text(tok.0)
            .font(.system(size: 7, design: .monospaced))
            .foregroundStyle(Color(nsColor: tok.1))
        }
        Spacer(minLength: 0)
      }
    }
    .padding(.leading, 4).padding(.trailing, 6)
    .frame(height: 11)
    .background(active ? Color(nsColor: hl) : .clear)
  }
}

struct PaletteGrid: View {
  @ObservedObject var model: ThemeModel
  private let keys = ["bg0", "bg1", "bg2", "bg3", "bg4", "fg0", "fg1", "fg2", "accent", "accentSoft", "blue", "green", "red", "purple", "border", "muted"]

  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 8) {
      ForEach(keys, id: \.self) { k in
        let value = model.colors[k] ?? "#000000"
        VStack(spacing: 3) {
          RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(Color(nsColor: nsColor(from: value)))
            .frame(height: 36)
            .overlay(
              RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.white.opacity(0.14))
            )
          Text(k)
            .font(.system(size: 9, design: .monospaced).weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
        .help("\(colorMeta[k]?.title ?? k)\n\(value)")
      }
    }
  }
}

struct SelectedKeyInfo: View {
  @ObservedObject var model: ThemeModel
  @Environment(\.themeChrome) private var theme

  var body: some View {
    Group {
      if let key = model.selectedKey {
        let isBase = model.mode == .base
        let hex = isBase ? (model.colors[key] ?? "#000000") : model.resolvedHex(for: key)
        let isOverride = !isBase && model.detailOverrides[key] != nil

        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(Color(nsColor: nsColor(from: hex)))
              .frame(width: 52, height: 52)
              .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                  .stroke(theme.surface(0.18))
              )
            VStack(alignment: .leading, spacing: 3) {
              Text(isBase ? (colorMeta[key]?.title ?? key) : settingTitle(key))
                .font(.callout.weight(.semibold))
                .lineLimit(2)
              Text(hex.uppercased())
                .font(.system(.caption, design: .monospaced).weight(.semibold))
              Text(key)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            }
          }

          if isBase {
            statusPill(icon: "paintpalette.fill", text: "Base palette variable", color: theme.accent)
          } else if isOverride {
            statusPill(icon: "checkmark.seal.fill", text: "Custom override", color: theme.success)
          } else {
            statusPill(icon: "link", text: "Derived from palette", color: theme.neutral)
          }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(theme.surface(0.08))
        )
      } else {
        VStack(spacing: 8) {
          Image(systemName: "hand.point.up.left")
            .font(.system(size: 22, weight: .light))
            .foregroundStyle(.secondary)
          Text("Click any color row to inspect")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(theme.surface(0.03), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
    }
  }

  private func statusPill(icon: String, text: String, color: Color) -> some View {
    HStack(spacing: 6) {
      Image(systemName: icon).font(.caption)
      Text(text).font(.caption.weight(.semibold))
    }
    .padding(.horizontal, 8).padding(.vertical, 4)
    .foregroundStyle(color)
    .background(color.opacity(0.14), in: Capsule())
  }
}

// MARK: - Status Bar

struct StatusBar: View {
  @ObservedObject var model: ThemeModel
  @Environment(\.themeChrome) private var theme

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: statusIcon)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(statusColor)
      Text(model.status)
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .truncationMode(.middle)
      Spacer()
      Group {
        Text("\(model.colors.count) palette")
        Text("·").foregroundStyle(.secondary.opacity(0.5))
        Text("\(model.detailOrder.count) keys")
        Text("·").foregroundStyle(.secondary.opacity(0.5))
        Text("\(model.detailOverrides.count) overrides")
      }
      .font(.system(size: 11))
      .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 16).padding(.vertical, 7)
    .background(.ultraThinMaterial)
  }

  private var statusIcon: String {
    let s = model.status.lowercased()
    if s.contains("failed") || s.contains("error") { return "exclamationmark.triangle.fill" }
    if s.contains("applied") || s.contains("backup") || s.contains("loaded") { return "checkmark.circle.fill" }
    return "circle.fill"
  }

  private var statusColor: Color {
    let s = model.status.lowercased()
    if s.contains("failed") || s.contains("error") { return theme.danger }
    if s.contains("applied") || s.contains("backup") || s.contains("loaded") { return theme.success }
    return .secondary
  }
}

// MARK: - Preferences Sheet

struct PreferencesSheet: View {
  @ObservedObject var model: ThemeModel
  @Environment(\.themeChrome) private var theme
  @State private var showAddCustom = false

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Preferences").font(.title2.weight(.semibold))
          Text("Settings, target apps, and theme metadata")
            .font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        Button("Done") { model.showPreferences = false }
          .keyboardShortcut(.defaultAction)
          .buttonStyle(.borderedProminent)
      }
      .padding(20)
      Divider().opacity(0.4)

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          prefSection(
            "Glass Tint",
            subtitle: "Hue and intensity for the Cursor Glass theme background"
          ) {
            VStack(alignment: .leading, spacing: 14) {
              sliderRow(
                label: "Hue",
                value: Binding(get: { Double(model.tintHue) }, set: { model.tintHue = Int($0) }),
                range: 0...360,
                suffix: "°"
              )
              sliderRow(
                label: "Intensity",
                value: Binding(get: { Double(model.tintIntensity) }, set: { model.tintIntensity = Int($0) }),
                range: 0...100,
                suffix: "%"
              )
            }
          }

          prefSection(
            "Apply Targets",
            subtitle: "Choose which editors will receive theme updates on Apply"
          ) {
            VStack(spacing: 4) {
              ForEach(model.allTargets) { target in
                targetToggleRow(target)
              }
              Divider().opacity(0.3).padding(.vertical, 4)
              Button {
                showAddCustom = true
              } label: {
                HStack(spacing: 6) {
                  Image(systemName: "plus.circle.fill")
                  Text("เพิ่ม Editor เอง")
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                  Spacer()
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .foregroundStyle(theme.accent)
                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.accent.opacity(0.3)))
                .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
            }
          }

          prefSection(
            "Backup Management",
            subtitle: "ดู / กู้คืน / ลบ backup ของแต่ละ editor"
          ) {
            BackupSection(model: model)
          }

          prefSection(
            "File Locations",
            subtitle: "All paths used by the app"
          ) {
            VStack(alignment: .leading, spacing: 10) {
              locationRow(label: "theme.json", path: themeURL.path) {
                NSWorkspace.shared.activateFileViewerSelecting([themeURL])
              }
              locationRow(label: "Active settings.json", path: model.activeTarget.settingsURL.path) {
                NSWorkspace.shared.open(model.activeTarget.userDir)
              }
            }
          }
        }
        .padding(20)
      }
    }
    .frame(width: 560, height: 600)
    .background(.background)
    .sheet(isPresented: $showAddCustom) {
      CustomTargetEditor(
        model: model,
        existing: nil,
        onSave: { _, _ in showAddCustom = false },
        onCancel: { showAddCustom = false }
      )
    }
  }

  private func prefSection<Content: View>(
    _ title: String,
    subtitle: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).font(.headline)
      if !subtitle.isEmpty {
        Text(subtitle).font(.caption).foregroundStyle(.secondary)
      }
      content()
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(theme.surface(0.06))
        )
    }
  }

  private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
    HStack(spacing: 12) {
      Text(label).frame(width: 80, alignment: .leading)
      Slider(value: value, in: range)
      Text("\(Int(value.wrappedValue))\(suffix)")
        .font(.system(.body, design: .monospaced))
        .frame(width: 60, alignment: .trailing)
    }
  }

  private func targetToggleRow(_ target: EditorTarget) -> some View {
    TargetRow(model: model, target: target)
  }

  private func locationRow(label: String, path: String, reveal: @escaping () -> Void) -> some View {
    HStack(alignment: .top, spacing: 10) {
      VStack(alignment: .leading, spacing: 2) {
        Text(label).font(.caption.weight(.semibold))
        Text(path)
          .font(.system(size: 11, design: .monospaced))
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .truncationMode(.middle)
      }
      Spacer()
      Button("Reveal") { reveal() }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
  }
}

// MARK: - Brand mark

struct AppMark: View {
  let colors: [String: String]

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 9, style: .continuous)
        .fill(
          LinearGradient(
            colors: [
              Color(red: 0.78, green: 0.72, blue: 0.95),  // soft lavender
              Color(red: 0.95, green: 0.78, blue: 0.88),  // soft rose
              Color(red: 0.72, green: 0.85, blue: 0.95)   // soft sky
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 9, style: .continuous)
            .stroke(.white.opacity(0.25))
        )
      Image(systemName: "paintpalette.fill")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white.opacity(0.95))
        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }
  }
}

// MARK: - Target Row (in Preferences)

struct TargetRow: View {
  @ObservedObject var model: ThemeModel
  let target: EditorTarget
  @Environment(\.themeChrome) private var theme
  @State private var alertKind: AlertKind? = nil
  @State private var pendingPath: String? = nil
  @State private var alertMessage = ""
  @State private var showEditSheet = false

  enum AlertKind: Identifiable {
    case warning, blocked
    var id: String { self == .warning ? "w" : "b" }
  }

  var body: some View {
    Toggle(isOn: Binding(
      get: { model.targetApplyStates[target.id] ?? false },
      set: { model.targetApplyStates[target.id] = $0 }
    )) {
      HStack(spacing: 10) {
        VStack(alignment: .leading, spacing: 3) {
          HStack(spacing: 6) {
            Text(target.name).font(.callout.weight(.semibold))
            if target.isCustom {
              tagPill("CUSTOM", color: theme.accent)
            }
            if target.pathOverride != nil && !target.isCustom {
              tagPill("OVERRIDDEN", color: theme.accent)
            }
          }
          if !target.isCustom {
            Text(target.appSupportName + " · " + target.supportLevel)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Text(target.settingsURL.path)
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
        }
        Spacer(minLength: 8)
        VStack(alignment: .trailing, spacing: 4) {
          readinessTag(target.detectionStatus)
          HStack(spacing: 4) {
            if target.isCustom {
              Button { showEditSheet = true } label: {
                Image(systemName: "pencil").font(.system(size: 10))
              }
              .buttonStyle(.borderless)
              .help("แก้ไขชื่อหรือ path ของ editor ที่เพิ่มเอง")
              Button { model.removeCustomTarget(id: target.id) } label: {
                Image(systemName: "trash").font(.system(size: 10))
              }
              .buttonStyle(.borderless)
              .help("ลบ editor ที่เพิ่มเองออกจากรายการ")
              .foregroundStyle(theme.danger)
            } else {
              Button { pickCustomPath() } label: {
                Image(systemName: "folder.badge.gearshape").font(.system(size: 10))
              }
              .buttonStyle(.borderless)
              .help("ตั้ง path ของ settings.json เอง — ใช้เมื่อ editor ลงในตำแหน่งที่แอปหาไม่เจอ")
              if target.pathOverride != nil {
                Button { model.setOverride(targetID: target.id, path: nil) } label: {
                  Image(systemName: "arrow.counterclockwise").font(.system(size: 10))
                }
                .buttonStyle(.borderless)
                .help("กลับไปใช้ path มาตรฐาน — ลบ path ที่ตั้งเองออก")
              }
            }
          }
        }
      }
    }
    .toggleStyle(.checkbox)
    .padding(.vertical, 4)
    .alert(item: $alertKind) { kind in
      switch kind {
      case .warning:
        return Alert(
          title: Text("ตรวจพบจุดน่าสงสัย"),
          message: Text(alertMessage),
          primaryButton: .default(Text("ดำเนินการต่อ")) {
            if let p = pendingPath { model.setOverride(targetID: target.id, path: p) }
            pendingPath = nil
          },
          secondaryButton: .cancel(Text("ยกเลิก")) { pendingPath = nil }
        )
      case .blocked:
        return Alert(
          title: Text("ไม่อนุญาต"),
          message: Text(alertMessage),
          dismissButton: .default(Text("OK"))
        )
      }
    }
    .sheet(isPresented: $showEditSheet) {
      CustomTargetEditor(
        model: model,
        existing: target,
        onSave: { _, _ in showEditSheet = false },
        onCancel: { showEditSheet = false }
      )
    }
  }

  private func tagPill(_ label: String, color: Color) -> some View {
    Text(label)
      .font(.system(size: 8, weight: .bold, design: .rounded))
      .padding(.horizontal, 5).padding(.vertical, 1)
      .foregroundStyle(color)
      .background(color.opacity(0.16), in: Capsule())
  }

  private func readinessTag(_ status: DetectionStatus) -> some View {
    HStack(spacing: 4) {
      Image(systemName: status.icon)
        .font(.system(size: 9, weight: .bold))
      Text(status.rawValue)
        .font(.system(.caption2, design: .rounded).weight(.bold))
    }
    .padding(.horizontal, 7).padding(.vertical, 3)
    .foregroundStyle(tagColor(status))
    .background(Capsule().fill(tagColor(status).opacity(0.14)))
    .overlay(Capsule().stroke(tagColor(status).opacity(0.3)))
  }

  private func tagColor(_ status: DetectionStatus) -> Color {
    switch status {
    case .ready: return theme.success
    case .willCreate: return theme.accent
    case .installedOnly: return theme.neutral
    case .notFound: return theme.danger
    }
  }

  private func pickCustomPath() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsOtherFileTypes = true
    panel.message = "เลือก settings.json ของ \(target.name)"
    if panel.runModal() == .OK, let url = panel.url {
      let validation = PathValidator.validate(url.path)
      switch validation {
      case .ok:
        model.setOverride(targetID: target.id, path: url.path)
      case .warning(let msg):
        pendingPath = url.path
        alertMessage = "\(msg)\n\nPath: \(url.path)"
        alertKind = .warning
      case .blocked(let msg):
        alertMessage = msg
        alertKind = .blocked
      }
    }
  }
}

// MARK: - Custom Target Editor

struct CustomTargetEditor: View {
  @ObservedObject var model: ThemeModel
  let existing: EditorTarget?
  let onSave: (String, String) -> Void
  let onCancel: () -> Void

  @Environment(\.themeChrome) private var theme
  @State private var name: String = ""
  @State private var path: String = ""
  @State private var validation: PathValidation = .ok
  @State private var hasValidated: Bool = false

  var isEditing: Bool { existing != nil }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text(isEditing ? "แก้ไข Custom Editor" : "เพิ่ม Custom Editor")
            .font(.title3.weight(.semibold))
          Text("ตั้งชื่อและ path ของ settings.json")
            .font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
      }
      .padding(20)
      Divider().opacity(0.4)

      VStack(alignment: .leading, spacing: 14) {
        VStack(alignment: .leading, spacing: 6) {
          Text("ชื่อ").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
          TextField("เช่น My Editor", text: $name)
            .textFieldStyle(.roundedBorder)
        }

        VStack(alignment: .leading, spacing: 6) {
          Text("Path ของ settings.json").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
          HStack(spacing: 6) {
            TextField("/path/to/User/settings.json", text: $path)
              .textFieldStyle(.roundedBorder)
              .font(.system(.caption, design: .monospaced))
              .onChange(of: path) { _, _ in revalidate() }
            Button("เลือกไฟล์…") { pickFile() }
          }
        }

        if hasValidated {
          ValidationBanner(result: validation)
        }
      }
      .padding(20)

      Spacer()

      HStack {
        Spacer()
        Button("ยกเลิก", action: onCancel).keyboardShortcut(.cancelAction)
        Button(isEditing ? "บันทึก" : "เพิ่ม") {
          submit()
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .disabled(!canSave)
      }
      .padding(20)
    }
    .frame(width: 540, height: 380)
    .onAppear {
      if let e = existing {
        name = e.name
        path = e.pathOverride ?? e.defaultSettingsPath
        revalidate()
      }
    }
  }

  private var canSave: Bool {
    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
    if path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
    if case .blocked = validation { return false }
    return true
  }

  private func revalidate() {
    validation = PathValidator.validate(path)
    hasValidated = !path.isEmpty
  }

  private func pickFile() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsOtherFileTypes = true
    panel.message = "เลือก settings.json"
    if panel.runModal() == .OK, let url = panel.url {
      path = url.path
      revalidate()
    }
  }

  private func submit() {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    if let e = existing {
      model.updateCustomTarget(id: e.id, name: trimmedName, path: trimmedPath)
    } else {
      _ = model.addCustomTarget(name: trimmedName, path: trimmedPath)
    }
    onSave(trimmedName, trimmedPath)
  }
}

struct ValidationBanner: View {
  let result: PathValidation
  @Environment(\.themeChrome) private var theme

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: 14, weight: .bold))
      VStack(alignment: .leading, spacing: 2) {
        Text(headline).font(.callout.weight(.semibold))
        if let detail = detail {
          Text(detail).font(.caption).foregroundStyle(.secondary)
        }
      }
      Spacer()
    }
    .padding(10)
    .foregroundStyle(color)
    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3)))
  }

  private var icon: String {
    switch result {
    case .ok: return "checkmark.seal.fill"
    case .warning: return "exclamationmark.triangle.fill"
    case .blocked: return "xmark.octagon.fill"
    }
  }

  private var color: Color {
    switch result {
    case .ok: return theme.success
    case .warning: return theme.warning
    case .blocked: return theme.danger
    }
  }

  private var headline: String {
    switch result {
    case .ok: return "Path ใช้ได้ — ปลอดภัย"
    case .warning: return "Path มีจุดน่าสงสัย"
    case .blocked: return "ไม่อนุญาตให้ใช้ path นี้"
    }
  }

  private var detail: String? {
    switch result {
    case .ok: return nil
    case .warning(let msg), .blocked(let msg): return msg
    }
  }
}

// MARK: - Confirm Apply Sheet

struct ConfirmApplySheet: View {
  @ObservedObject var model: ThemeModel
  @Environment(\.themeChrome) private var theme

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("ยืนยันการ Apply")
            .font(.title3.weight(.semibold))
          Text("ตรวจสอบ targets ก่อนเขียนไฟล์ settings.json")
            .font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
      }
      .padding(20)
      Divider().opacity(0.4)

      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          summary
          targetList
          tips
        }
        .padding(20)
      }

      Divider().opacity(0.4)
      HStack {
        Spacer()
        Button("ยกเลิก") {
          model.pendingApplyConfirmation = false
        }
        .keyboardShortcut(.cancelAction)
        Button {
          model.confirmAndApply()
        } label: {
          HStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
            Text("Apply ทันที")
          }
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .disabled(model.applyTargets.isEmpty)
      }
      .padding(20)
    }
    .frame(width: 540, height: 460)
  }

  private var summary: some View {
    HStack(spacing: 12) {
      Image(systemName: "doc.badge.gearshape.fill")
        .font(.title)
        .foregroundStyle(theme.accent)
      VStack(alignment: .leading, spacing: 3) {
        Text("จะ Apply ลง \(model.applyTargets.count) target")
          .font(.headline)
        Text("ระบบจะ backup settings.json ก่อนเขียนทุกครั้ง")
          .font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
    }
    .padding(12)
    .background(theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
  }

  private var targetList: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("TARGETS").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
      VStack(spacing: 6) {
        ForEach(model.applyTargets) { target in
          HStack(spacing: 8) {
            Image(systemName: target.detectionStatus.icon)
              .foregroundStyle(target.detectionStatus == .ready ? theme.success : theme.neutral)
            VStack(alignment: .leading, spacing: 1) {
              Text(target.name).font(.callout.weight(.semibold))
              Text(target.settingsURL.path)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            if target.id == "cursor" {
              Text("FULL").font(.system(size: 8, weight: .bold))
                .padding(.horizontal, 5).padding(.vertical, 1)
                .foregroundStyle(theme.accent)
                .background(theme.accent.opacity(0.16), in: Capsule())
            } else {
              Text("COLORS").font(.system(size: 8, weight: .bold))
                .padding(.horizontal, 5).padding(.vertical, 1)
                .foregroundStyle(theme.success)
                .background(theme.success.opacity(0.16), in: Capsule())
            }
          }
          .padding(10)
          .background(theme.surface(0.04), in: RoundedRectangle(cornerRadius: 8))
        }
      }
    }
  }

  private var tips: some View {
    VStack(alignment: .leading, spacing: 6) {
      Label("Cursor: เขียนทุก field รวม glass.theme.* + workbench.colorTheme",
            systemImage: "info.circle")
        .font(.caption)
      Label("Editor อื่น: เขียนเฉพาะ workbench.colorCustomizations + tokenColorCustomizations",
            systemImage: "info.circle")
        .font(.caption)
      Label("ถ้าสียังไม่อัพเดท: กด Cmd+Shift+P > Reload Window ใน editor",
            systemImage: "arrow.clockwise")
        .font(.caption)
    }
    .foregroundStyle(.secondary)
    .padding(10)
    .background(theme.surface(0.03), in: RoundedRectangle(cornerRadius: 8))
  }
}

// MARK: - Apply Result Sheet

struct ApplyResultSheet: View {
  @ObservedObject var model: ThemeModel
  let outcome: ThemeModel.ApplyOutcome
  @Environment(\.themeChrome) private var theme

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider().opacity(0.4)
      ScrollView {
        body_
          .padding(20)
      }
      Divider().opacity(0.4)
      HStack {
        Spacer()
        Button("OK") { model.applyResult = nil }
          .keyboardShortcut(.defaultAction)
          .buttonStyle(.borderedProminent)
      }
      .padding(20)
    }
    .frame(width: 520, height: 380)
  }

  @ViewBuilder
  private var header: some View {
    let isSuccess: Bool = {
      if case .success = outcome { return true } else { return false }
    }()
    let isPartial: Bool = {
      if case .failure(_, let partial) = outcome, !partial.isEmpty { return true }
      return false
    }()

    HStack(spacing: 14) {
      ZStack {
        Circle()
          .fill((isSuccess ? theme.success : (isPartial ? theme.warning : theme.danger)).opacity(0.18))
          .frame(width: 52, height: 52)
        Image(systemName: isSuccess ? "checkmark.seal.fill" : (isPartial ? "exclamationmark.triangle.fill" : "xmark.octagon.fill"))
          .font(.title2.weight(.bold))
          .foregroundStyle(isSuccess ? theme.success : (isPartial ? theme.warning : theme.danger))
      }
      VStack(alignment: .leading, spacing: 2) {
        Text(headlineText)
          .font(.title3.weight(.semibold))
        Text(subtitleText)
          .font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
    }
    .padding(20)
  }

  @ViewBuilder
  private var body_: some View {
    switch outcome {
    case .success(let targets):
      VStack(alignment: .leading, spacing: 14) {
        Text("เขียน settings.json สำเร็จที่ targets ต่อไปนี้:")
          .font(.callout)
        VStack(alignment: .leading, spacing: 6) {
          ForEach(targets, id: \.self) { name in
            Label(name, systemImage: "checkmark.circle.fill")
              .foregroundStyle(theme.success)
          }
        }
        Divider().opacity(0.3)
        Label("กด Cmd+Shift+P > Reload Window ใน editor ถ้าสียังไม่เปลี่ยน",
              systemImage: "arrow.clockwise")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    case .failure(let message, let partial):
      VStack(alignment: .leading, spacing: 14) {
        if !partial.isEmpty {
          Label("Apply สำเร็จบางส่วน: \(partial.joined(separator: ", "))",
                systemImage: "checkmark.circle.fill")
            .foregroundStyle(theme.success)
        }
        Text("Errors:").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
        ScrollView {
          Text(message)
            .font(.system(.caption, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 160)
        .padding(10)
        .background(theme.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.danger.opacity(0.2)))
      }
    }
  }

  private var headlineText: String {
    switch outcome {
    case .success: return "Apply สำเร็จ"
    case .failure(_, let partial): return partial.isEmpty ? "Apply ล้มเหลว" : "Apply สำเร็จบางส่วน"
    }
  }

  private var subtitleText: String {
    switch outcome {
    case .success(let t): return "เขียน \(t.count) target สำเร็จ"
    case .failure(_, let p): return p.isEmpty ? "ไม่มี target ใดเขียนสำเร็จ" : "\(p.count) สำเร็จ ยังเหลือบาง target ที่ error"
    }
  }
}

// MARK: - Save Preset Sheet

struct SavePresetSheet: View {
  @ObservedObject var model: ThemeModel
  @Binding var isOpen: Bool
  @Environment(\.themeChrome) private var theme
  @State private var name: String = ""

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Save as Preset")
            .font(.title3.weight(.semibold))
          Text("บันทึก palette ปัจจุบันเป็น preset เพื่อเรียกใช้ภายหลัง")
            .font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
      }
      .padding(20)
      Divider().opacity(0.4)

      VStack(alignment: .leading, spacing: 14) {
        VStack(alignment: .leading, spacing: 6) {
          Text("ชื่อ Preset")
            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
          TextField("เช่น My Sunset Theme", text: $name)
            .textFieldStyle(.roundedBorder)
        }

        // Preview swatches
        VStack(alignment: .leading, spacing: 6) {
          Text("Palette Snapshot")
            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
          HStack(spacing: 4) {
            ForEach(["bg0", "bg1", "fg0", "accent", "accentSoft", "blue", "green", "red", "purple", "border"], id: \.self) { k in
              if let hex = model.colors[k] {
                RoundedRectangle(cornerRadius: 4)
                  .fill(Color(nsColor: nsColor(from: hex)))
                  .frame(height: 32)
                  .overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.surface(0.12)))
              }
            }
          }
        }
      }
      .padding(20)

      Spacer()

      HStack {
        Spacer()
        Button("ยกเลิก") { isOpen = false }
          .keyboardShortcut(.cancelAction)
        Button("บันทึก") {
          let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
          if !trimmed.isEmpty {
            _ = model.saveUserPreset(name: trimmed)
            isOpen = false
          }
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .padding(20)
    }
    .frame(width: 480, height: 340)
  }
}

// MARK: - Backup Section (in Preferences)

struct BackupSection: View {
  @ObservedObject var model: ThemeModel
  @Environment(\.themeChrome) private var theme
  @State private var expandedTargetID: String? = nil
  @State private var pendingRestore: PendingItem? = nil
  @State private var pendingDelete: PendingItem? = nil

  struct PendingItem: Identifiable {
    let id: String
    let target: EditorTarget
    let backup: ThemeModel.BackupFile
  }

  var body: some View {
    VStack(spacing: 8) {
      // Retention info banner
      retentionBanner
      ForEach(model.allTargets) { target in
        targetRow(target)
      }
    }
    .sheet(item: $pendingRestore) { item in
      RestoreConfirmSheet(
        model: model,
        target: item.target,
        backup: item.backup,
        onCancel: { pendingRestore = nil },
        onConfirm: {
          do {
            try model.restoreBackup(item.backup, to: item.target.settingsURL)
          } catch {
            model.status = "Restore failed: \(error.localizedDescription)"
          }
          pendingRestore = nil
        }
      )
    }
    .sheet(item: $pendingDelete) { item in
      DeleteBackupConfirmSheet(
        backup: item.backup,
        onCancel: { pendingDelete = nil },
        onConfirm: {
          do { try model.deleteBackup(item.backup) } catch {
            model.status = "Delete failed: \(error.localizedDescription)"
          }
          pendingDelete = nil
        }
      )
    }
  }

  private var retentionBanner: some View {
    let totalExcess = computeExcess()
    return HStack(spacing: 8) {
      Image(systemName: "archivebox.fill").foregroundStyle(theme.accent)
      VStack(alignment: .leading, spacing: 2) {
        Text("เก็บ backup สูงสุด \(ThemeModel.backupRetentionLimit) ไฟล์/editor")
          .font(.caption.weight(.semibold))
        Text(totalExcess > 0
             ? "ตอนนี้มีไฟล์เกิน \(totalExcess) อัน — กด Prune now เพื่อล้าง"
             : "อยู่ในเกณฑ์")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      Spacer()
      if totalExcess > 0 {
        Button("Prune now (-\(totalExcess))") {
          for target in model.allTargets {
            model.pruneBackups(forSettingsAt: target.settingsURL, keep: ThemeModel.backupRetentionLimit)
          }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
      }
    }
    .padding(10)
    .background(theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.accent.opacity(0.2)))
  }

  private func computeExcess() -> Int {
    var total = 0
    for target in model.allTargets {
      let count = model.listBackups(forSettingsAt: target.settingsURL).count
      if count > ThemeModel.backupRetentionLimit {
        total += count - ThemeModel.backupRetentionLimit
      }
    }
    return total
  }

  @ViewBuilder
  private func targetRow(_ target: EditorTarget) -> some View {
    let backups = model.listBackups(forSettingsAt: target.settingsURL)
    let isExpanded = expandedTargetID == target.id
    VStack(spacing: 0) {
      Button {
        if backups.isEmpty { return }
        expandedTargetID = isExpanded ? nil : target.id
      } label: {
        HStack(spacing: 10) {
          Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.secondary)
            .opacity(backups.isEmpty ? 0.3 : 1)
          VStack(alignment: .leading, spacing: 1) {
            Text(target.name).font(.callout.weight(.semibold))
            Text("\(backups.count) backup\(backups.count == 1 ? "" : "s")")
              .font(.caption).foregroundStyle(.secondary)
          }
          Spacer()
          if let latest = backups.first {
            Text("ล่าสุด: \(latest.displayDate)")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
        .padding(10)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .disabled(backups.isEmpty)

      if isExpanded {
        VStack(spacing: 4) {
          ForEach(backups) { backup in
            backupRow(backup, target: target)
          }
        }
        .padding(.bottom, 8)
        .padding(.horizontal, 8)
      }
    }
    .background(theme.surface(0.04), in: RoundedRectangle(cornerRadius: 8))
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.surface(0.06)))
  }

  @ViewBuilder
  private func backupRow(_ backup: ThemeModel.BackupFile, target: EditorTarget) -> some View {
    HStack(spacing: 8) {
      Image(systemName: "clock.arrow.circlepath")
        .font(.caption)
        .foregroundStyle(.secondary)
      VStack(alignment: .leading, spacing: 1) {
        Text(backup.displayDate).font(.caption.weight(.semibold))
        Text("\(backup.size) bytes · \(backup.url.lastPathComponent)")
          .font(.system(size: 9, design: .monospaced))
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .truncationMode(.middle)
      }
      Spacer()
      Button {
        pendingRestore = PendingItem(id: backup.id, target: target, backup: backup)
      } label: {
        Image(systemName: "arrow.uturn.backward.circle")
          .font(.system(size: 14))
      }
      .buttonStyle(.borderless)
      .help("กู้คืน — เขียน backup นี้ทับ settings.json ปัจจุบันของ editor (จะมี modal ยืนยันก่อน)")
      .foregroundStyle(theme.accent)

      Button {
        NSWorkspace.shared.activateFileViewerSelecting([backup.url])
      } label: {
        Image(systemName: "folder")
          .font(.system(size: 13))
      }
      .buttonStyle(.borderless)
      .help("เปิดตำแหน่งไฟล์ backup ใน Finder")

      Button {
        pendingDelete = PendingItem(id: "del-" + backup.id, target: target, backup: backup)
      } label: {
        Image(systemName: "trash")
          .font(.system(size: 13))
      }
      .buttonStyle(.borderless)
      .help("ลบไฟล์ backup นี้ถาวร (ลบแล้วกู้คืนไม่ได้)")
      .foregroundStyle(theme.danger)
    }
    .padding(.horizontal, 8).padding(.vertical, 6)
    .background(theme.surface(0.03), in: RoundedRectangle(cornerRadius: 6))
  }
}

// MARK: - Restore Confirm Sheet (used by BackupSection)

struct RestoreConfirmSheet: View {
  @ObservedObject var model: ThemeModel
  let target: EditorTarget
  let backup: ThemeModel.BackupFile
  let onCancel: () -> Void
  let onConfirm: () -> Void
  @Environment(\.themeChrome) private var theme

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        ZStack {
          Circle().fill(theme.warning.opacity(0.18)).frame(width: 44, height: 44)
          Image(systemName: "arrow.uturn.backward.circle.fill")
            .font(.title2.weight(.bold))
            .foregroundStyle(theme.warning)
        }
        VStack(alignment: .leading, spacing: 2) {
          Text("กู้คืน Backup")
            .font(.title3.weight(.semibold))
          Text("จะเขียนทับ settings.json ปัจจุบัน — ใช้ backup ปัจจุบันเป็น snapshot ก่อน")
            .font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
      }
      .padding(20)
      Divider().opacity(0.4)

      VStack(alignment: .leading, spacing: 12) {
        infoRow(label: "Editor", value: target.name)
        infoRow(label: "Backup file", value: backup.url.lastPathComponent, mono: true)
        infoRow(label: "วันที่ backup", value: backup.displayDate)
        infoRow(label: "ขนาดไฟล์", value: "\(backup.size) bytes")
        infoRow(label: "เป้าหมาย", value: target.settingsURL.path, mono: true)

        Divider().opacity(0.3)

        HStack(spacing: 10) {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(theme.warning)
          VStack(alignment: .leading, spacing: 2) {
            Text("ปฏิบัติการนี้จะเขียนทับไฟล์ปัจจุบัน").font(.callout.weight(.semibold))
            Text("ระบบจะไม่สร้าง backup ใหม่อัตโนมัติ — ถ้าต้องการเก็บไฟล์ปัจจุบัน กดยกเลิกแล้วกด Apply เพื่อสร้าง backup ก่อน")
              .font(.caption).foregroundStyle(.secondary)
          }
        }
        .padding(10)
        .background(theme.warning.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.warning.opacity(0.3)))
      }
      .padding(20)

      Spacer()

      HStack {
        Spacer()
        Button("ยกเลิก", action: onCancel)
          .keyboardShortcut(.cancelAction)
        Button(action: onConfirm) {
          HStack(spacing: 5) {
            Image(systemName: "arrow.uturn.backward")
            Text("กู้คืน")
          }
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .tint(theme.warning)
      }
      .padding(20)
    }
    .frame(width: 540, height: 440)
  }

  private func infoRow(label: String, value: String, mono: Bool = false) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Text(label)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(width: 100, alignment: .trailing)
      Text(value)
        .font(mono ? .system(.caption, design: .monospaced) : .callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(2)
        .truncationMode(.middle)
    }
  }
}

// MARK: - Delete Backup Confirm Sheet

struct DeleteBackupConfirmSheet: View {
  let backup: ThemeModel.BackupFile
  let onCancel: () -> Void
  let onConfirm: () -> Void
  @Environment(\.themeChrome) private var theme

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        ZStack {
          Circle().fill(theme.danger.opacity(0.18)).frame(width: 44, height: 44)
          Image(systemName: "trash.fill")
            .font(.title2.weight(.bold))
            .foregroundStyle(theme.danger)
        }
        VStack(alignment: .leading, spacing: 2) {
          Text("ลบ Backup").font(.title3.weight(.semibold))
          Text("ลบแล้วกู้คืนไม่ได้").font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
      }
      .padding(20)
      Divider().opacity(0.4)

      VStack(alignment: .leading, spacing: 8) {
        Text(backup.url.lastPathComponent)
          .font(.system(.callout, design: .monospaced))
        Text("\(backup.displayDate) · \(backup.size) bytes")
          .font(.caption).foregroundStyle(.secondary)
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)

      Spacer()

      HStack {
        Spacer()
        Button("ยกเลิก", action: onCancel).keyboardShortcut(.cancelAction)
        Button(action: onConfirm) {
          HStack(spacing: 5) {
            Image(systemName: "trash")
            Text("ลบถาวร")
          }
        }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .tint(theme.danger)
      }
      .padding(20)
    }
    .frame(width: 460, height: 260)
  }
}
