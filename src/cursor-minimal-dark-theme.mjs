import fs from "node:fs";

const settingsPath =
  "/Users/pattanasak/Library/Application Support/Cursor/User/settings.json";

const themeSettings = {
  "workbench.colorTheme": "Default Dark Modern",
  "glass.theme.detectColorScheme": false,
  "glass.theme.settingsId": "Default Dark Modern",
  "glass.theme.darkSettingsId": "Default Dark Modern",
  "glass.theme.customTintHue": 188,
  "glass.theme.customTintIntensity": 30,
};

const colors = {
  bg0: "#08060F",
  bg1: "#100B1F",
  bg2: "#17102A",
  bg3: "#241642",
  bg4: "#34205F",
  fg0: "#FFF7FF",
  fg1: "#E9D7FF",
  fg2: "#B79CFF",
  muted: "#7C6A99",
  muted2: "#534566",
  border: "#9D4EDD",
  accent: "#FF4FD8",
  accentSoft: "#FF9BE8",
  blue: "#00D4FF",
  green: "#5CFF95",
  red: "#FF3864",
  purple: "#C77DFF",
  transparent: "#FFFFFF00",
  overlayLow: "#FFFFFF08",
  overlayMid: "#FFFFFF10",
  overlayHigh: "#FFFFFF18",
  overlayActive: "#FFFFFF22",
};

const ui = {
  "editor.background": colors.bg0,
  "sideBar.background": colors.bg1,
  "activityBar.background": colors.bg0,
  "panel.background": colors.bg1,
  "terminal.background": "#090B0C",
  "terminal.foreground": colors.fg1,
  "terminalCursor.foreground": colors.accent,
  "titleBar.activeBackground": colors.bg0,
  "titleBar.inactiveBackground": colors.bg0,
  "editorGutter.background": colors.bg0,
  "editorGroupHeader.tabsBackground": colors.bg0,
  "editorGroupHeader.noTabsBackground": colors.bg0,
  "tab.activeBackground": colors.bg0,
  "tab.inactiveBackground": colors.bg1,
  "tab.unfocusedActiveBackground": colors.bg0,
  "tab.unfocusedInactiveBackground": colors.bg1,
  "sideBarSectionHeader.background": colors.bg1,
  "secondarySideBar.background": colors.bg1,
  "minimap.background": colors.bg0,
  "statusBar.background": colors.bg0,

  "contrastBorder": colors.border,
  "panel.border": colors.border,
  "sideBar.border": colors.border,
  "activityBar.border": colors.border,
  "editorGroup.border": colors.border,
  "editorGroupHeader.border": colors.border,
  "tab.border": colors.bg3,
  "titleBar.border": colors.border,
  "statusBar.border": colors.border,
  "input.border": colors.border,
  "commandCenter.border": colors.border,
  "widget.border": colors.border,
  "editorWidget.border": colors.border,
  "editorWidget.resizeBorder": colors.accent,
  "sash.hoverBorder": colors.accent,
  "focusBorder": colors.accent,

  "activityBar.activeBorder": colors.accent,
  "activityBarTop.activeBorder": colors.accent,
  "activityBarBadge.background": colors.accent,
  "activityBarBadge.foreground": colors.bg0,
  "progressBar.background": colors.accent,
  "settings.modifiedItemIndicator": colors.accent,
  "panelTitle.activeBorder": colors.accent,
  "inputOption.activeBorder": colors.accent,
  "tab.activeBorder": `${colors.accent}33`,
  "tab.activeBorderTop": `${colors.accent}33`,
  "tab.unfocusedActiveBorder": `${colors.accent}66`,
  "tab.unfocusedActiveBorderTop": `${colors.accent}33`,
  "tab.activeModifiedBorder": colors.accent,
  "statusBarItem.remoteBackground": colors.accent,
  "statusBarItem.remoteForeground": colors.bg0,
  "statusBarItem.remoteHoverBackground": colors.accentSoft,
  "statusBarItem.remoteHoverForeground": colors.bg0,
  "notebook.inactiveFocusedCellBorder": colors.accent,
  "commandCenter.activeBorder": colors.border,

  "sideBar.foreground": colors.fg1,
  "sideBarTitle.foreground": colors.fg0,
  "sideBarSectionHeader.foreground": colors.fg2,
  "list.activeSelectionBackground": colors.bg4,
  "list.inactiveSelectionBackground": colors.bg3,
  "list.hoverBackground": colors.bg3,
  "list.activeSelectionForeground": colors.accentSoft,
  "list.inactiveSelectionForeground": colors.accent,
  "list.hoverForeground": colors.fg0,
  "list.highlightForeground": colors.accent,
  "list.activeSelectionIconForeground": colors.accentSoft,
  "list.inactiveSelectionIconForeground": colors.accent,
  "breadcrumb.activeSelectionForeground": colors.accentSoft,
  "menu.selectionForeground": colors.accentSoft,
  "menubar.selectionForeground": colors.accentSoft,
  "notificationLink.foreground": colors.accent,
  "editorSuggestWidget.highlightForeground": colors.accent,
  "pickerGroup.foreground": colors.accent,
  "textLink.foreground": colors.blue,
  "chat.slashCommandForeground": colors.accent,
  "chat.avatarForeground": colors.accent,

  "input.background": colors.bg2,
  "dropdown.background": colors.bg2,
  "quickInput.background": colors.bg2,
  "quickInputTitle.background": colors.bg1,
  "quickInputList.focusBackground": colors.bg4,
  "quickInputList.focusForeground": colors.accentSoft,
  "editorWidget.background": colors.bg2,

  "editor.lineHighlightBackground": colors.overlayLow,
  "editor.lineHighlightBorder": colors.transparent,
  "editorIndentGuide.background1": colors.bg4,
  "editorIndentGuide.activeBackground1": "#3A4650",
  "editorLineNumber.foreground": colors.muted2,
  "editorLineNumber.activeForeground": colors.accent,
  "editor.findMatchBorder": colors.accent,
  "selection.background": `${colors.accent}40`,

  "button.background": colors.accent,
  "button.hoverBackground": colors.accentSoft,
  "button.foreground": colors.bg0,
  "toolbar.activeBackground": colors.bg4,
  "extensionButton.foreground": colors.bg0,
  "extensionButton.separator": colors.accent,
  "extensionButton.background": colors.accent,
  "extensionButton.hoverBackground": colors.accentSoft,
  "extensionButton.prominentForeground": colors.bg0,
  "extensionButton.prominentBackground": colors.accent,
  "extensionButton.prominentHoverBackground": colors.accentSoft,

  "scrollbarSlider.background": colors.overlayMid,
  "scrollbarSlider.hoverBackground": colors.overlayHigh,
  "scrollbarSlider.activeBackground": colors.overlayActive,
  "scrollbarSlider.hoverBorder": colors.transparent,
  "scrollbarSlider.activeBorder": colors.transparent,

  "gitDecoration.modifiedResourceForeground": colors.accent,
  "gitDecoration.addedResourceForeground": colors.green,
  "gitDecoration.deletedResourceForeground": colors.red,
  "gitDecoration.untrackedResourceForeground": colors.green,
  "gitDecoration.ignoredResourceForeground": colors.muted2,
  "gitDecoration.conflictingResourceForeground": colors.purple,
  "gitDecoration.stageModifiedResourceForeground": colors.accentSoft,
  "gitDecoration.stageDeletedResourceForeground": colors.red,
};

// Direct per-setting overrides written by Cursor Theme Customizer.
// Keep this object small: base palette colors still drive everything else.
const uiOverrides = {
};

const tokenRules = [
  [["comment", "punctuation.definition.comment"], colors.muted],
  [["comment.documentation", "comment.block.documentation"], "#7D858C"],
  [["keyword", "keyword.control", "storage.type", "storage.modifier"], colors.accent],
  [["entity.name.tag", "entity.name.attribute-name"], colors.blue],
  [["keyword.operator"], colors.fg1],
  [["variable", "variable.other.readwrite", "support.variable"], colors.fg0],
  [["variable.parameter"], colors.accentSoft],
  [["variable.language.this", "support.variable.magic"], colors.red],
  [
    [
      "entity.name.type",
      "entity.name.class",
      "support.type",
      "entity.name.namespace",
      "entity.name.function.constructor",
    ],
    colors.purple,
  ],
  [
    ["variable.object.property", "variable.other.property", "support.type.property-name"],
    colors.fg1,
  ],
  [["entity.name.decorator", "meta.decorator", "storage.type.annotation"], colors.accentSoft],
  [
    ["entity.name.function", "support.function", "meta.function-call entity.name.function"],
    colors.blue,
    "",
  ],
  [["string", "string.quoted"], colors.green],
  [["constant.numeric"], colors.purple],
  [["constant.language", "constant.other"], colors.accentSoft],
  [["punctuation.section.block", "punctuation.section.bracket", "punctuation.section.parens"], colors.fg2],
  [["punctuation.definition.string"], colors.green],
  [["punctuation.separator", "punctuation.terminator"], colors.fg2],
];

const indent = (value, spaces = 2) =>
  JSON.stringify(value, null, 2)
    .split("\n")
    .map((line) => " ".repeat(spaces) + line)
    .join("\n")
    .trimStart();

const colorBlock = `"workbench.colorCustomizations": {
    // Generated from cursor-minimal-dark-theme.mjs
    // Change the colors object in that file, then run:
    // node "/Users/pattanasak/Library/Application Support/Cursor/User/cursor-minimal-dark-theme.mjs"
${Object.entries({ ...ui, ...uiOverrides })
  .map(([key, value]) => `    ${JSON.stringify(key)}: ${JSON.stringify(value)}`)
  .join(",\n")}
  }`;

const tokenBlock = `"editor.tokenColorCustomizations": {
    "comments": ${JSON.stringify(colors.muted)},
    "textMateRules": ${indent(
      tokenRules.map(([scope, foreground, fontStyle]) => ({
        scope,
        settings: {
          foreground,
          ...(fontStyle === undefined ? {} : { fontStyle }),
        },
      })),
      4,
    )}
  }`;

let settings = fs.readFileSync(settingsPath, "utf8");

for (const [key, value] of Object.entries(themeSettings)) {
  const serialized = `${JSON.stringify(key)}: ${JSON.stringify(value)}`;
  const matcher = new RegExp(`${JSON.stringify(key)}\\s*:\\s*[^,\\n]+`);

  if (matcher.test(settings)) {
    settings = settings.replace(matcher, serialized);
  } else {
    settings = settings.replace(/^\{\n/, `{\n  ${serialized},\n`);
  }
}

settings = settings.replace(
  /"workbench\.colorCustomizations":\s*\{[\s\S]*?\n  \},\n  "editor\.tokenColorCustomizations"/,
  `${colorBlock},\n  "editor.tokenColorCustomizations"`,
);

settings = settings.replace(
  /"editor\.tokenColorCustomizations":\s*\{[\s\S]*?\n  \},\n  \/\/----------------------------------------------------------/,
  `${tokenBlock},\n  //----------------------------------------------------------`,
);

fs.writeFileSync(settingsPath, settings);
