-- serenity.lua
-- Standalone neovim colorscheme based on the Pantone "Serenity" (#91A8D0)
-- and "Rose Quartz" (#F7CAC9) palette.
-- Mirrors ~/.config/kitty/kitty.conf

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
end
vim.o.termguicolors = true
vim.g.colors_name = "serenity"

local c = {
    -- backgrounds (darkest -> lightest)
    crust    = "#0f1019",
    mantle   = "#14151f",
    base     = "#1a1b26",
    surface0 = "#243446",
    surface1 = "#2a3950",
    surface2 = "#3d5375",

    -- foregrounds / overlays
    overlay0 = "#4a5b78",
    overlay1 = "#6b7e9c",
    overlay2 = "#8fa3be",
    subtext0 = "#b3cee5",
    subtext1 = "#c9d6e8",
    text     = "#c5d0de",
    bright   = "#d0d3df",

    -- accents (rose quartz family)
    rose_lt  = "#f7cac9",
    rose     = "#d8909a",

    -- pinks / lavenders
    pink     = "#d4bce6",
    mauve    = "#b69ace",

    -- warm sand
    sand_lt  = "#e8d49a",
    sand     = "#d4b97a",

    -- sage / mint
    sage     = "#95b894",
    mint     = "#b5d4a8",

    -- aqua / serenity blues
    aqua_lt  = "#b3dce8",
    aqua     = "#8fbed1",
    blue     = "#91a8d0",
    blue_lt  = "#b3cee5",

    -- selection (from kitty.conf)
    sel_fg   = "#1c2b3a",
    sel_bg   = "#b3cee5",

    none     = "NONE",
}

local hl = function(group, opts) vim.api.nvim_set_hl(0, group, opts) end

-- ============================================================
--  Editor UI
-- ============================================================
-- Main editor: leave bg = NONE so the terminal background shows through.
hl("Normal",       { fg = c.text, bg = c.none })
hl("NormalNC",     { fg = c.text, bg = c.none })
hl("NormalFloat",  { fg = c.text, bg = c.none })
hl("FloatBorder",  { fg = c.blue, bg = c.none })
hl("FloatTitle",   { fg = c.blue, bg = c.none, bold = true })

hl("Cursor",       { fg = c.base, bg = c.blue })
hl("lCursor",      { fg = c.base, bg = c.blue })
hl("CursorIM",     { fg = c.base, bg = c.blue })
hl("CursorLine",   { bg = c.surface0 })
hl("CursorColumn", { bg = c.surface0 })
hl("CursorLineNr", { fg = c.blue, bold = true })
hl("LineNr",       { fg = c.overlay0, bg = c.none })
hl("SignColumn",   { fg = c.overlay0, bg = c.none })
hl("ColorColumn",  { bg = c.surface0 })

hl("Visual",       { fg = c.sel_fg, bg = c.sel_bg })
hl("VisualNOS",    { fg = c.sel_fg, bg = c.sel_bg })
hl("Search",       { fg = c.sel_fg, bg = c.sel_bg })
hl("CurSearch",    { fg = c.sel_fg, bg = c.rose_lt, bold = true })
hl("IncSearch",    { fg = c.sel_fg, bg = c.rose_lt, bold = true })
hl("Substitute",   { fg = c.sel_fg, bg = c.rose_lt })
hl("MatchParen",   { fg = c.bright, bg = c.surface2, bold = true })

hl("StatusLine",   { fg = c.text,    bg = c.none })
hl("StatusLineNC", { fg = c.overlay1, bg = c.none })
hl("WinSeparator", { fg = c.surface2, bg = c.none })
hl("VertSplit",    { fg = c.surface2, bg = c.none })

hl("TabLine",      { fg = c.overlay2, bg = c.surface0 })
hl("TabLineSel",   { fg = c.bright,   bg = "#4a6b92", bold = true })
hl("TabLineFill",  { bg = c.mantle })

hl("Pmenu",        { fg = c.text, bg = c.mantle })
hl("PmenuSel",     { fg = c.bright, bg = c.surface2, bold = true })
hl("PmenuSbar",    { bg = c.surface0 })
hl("PmenuThumb",   { bg = c.overlay0 })
hl("WildMenu",     { fg = c.bright, bg = c.surface2 })

hl("Folded",       { fg = c.overlay2, bg = c.surface0 })
hl("FoldColumn",   { fg = c.overlay0, bg = c.none })
hl("Conceal",      { fg = c.overlay1 })

hl("Directory",    { fg = c.blue, bold = true })
hl("Title",        { fg = c.blue, bold = true })
hl("Question",     { fg = c.aqua })
hl("MoreMsg",      { fg = c.sage, bold = true })
hl("ModeMsg",      { fg = c.blue, bold = true })
hl("WarningMsg",   { fg = c.sand })
hl("ErrorMsg",     { fg = c.rose, bold = true })
hl("NonText",      { fg = c.overlay0, bg = c.none })
hl("Whitespace",   { fg = c.surface1, bg = c.none })
hl("SpecialKey",   { fg = c.overlay0, bg = c.none })
hl("EndOfBuffer",  { fg = c.base,     bg = c.none })

hl("SpellBad",     { sp = c.rose, undercurl = true })
hl("SpellCap",     { sp = c.sand, undercurl = true })
hl("SpellLocal",   { sp = c.aqua, undercurl = true })
hl("SpellRare",    { sp = c.mauve, undercurl = true })

-- ============================================================
--  Syntax (legacy)
-- ============================================================
hl("Comment",      { fg = c.overlay1, italic = true })

hl("Constant",     { fg = c.rose_lt })
hl("String",       { fg = c.sage })
hl("Character",    { fg = c.sage })
hl("Number",       { fg = c.sand })
hl("Boolean",      { fg = c.sand })
hl("Float",        { fg = c.sand })

hl("Identifier",   { fg = c.text })
hl("Function",     { fg = c.blue })

hl("Statement",    { fg = c.mauve })
hl("Conditional",  { fg = c.mauve })
hl("Repeat",       { fg = c.mauve })
hl("Label",        { fg = c.mauve })
hl("Operator",     { fg = c.aqua })
hl("Keyword",      { fg = c.mauve, italic = true })
hl("Exception",    { fg = c.rose })

hl("PreProc",      { fg = c.pink })
hl("Include",      { fg = c.pink })
hl("Define",       { fg = c.pink })
hl("Macro",        { fg = c.pink })
hl("PreCondit",    { fg = c.pink })

hl("Type",         { fg = c.sand_lt })
hl("StorageClass", { fg = c.sand_lt })
hl("Structure",    { fg = c.sand_lt })
hl("Typedef",      { fg = c.sand_lt })

hl("Special",      { fg = c.aqua })
hl("SpecialChar",  { fg = c.aqua })
hl("Tag",          { fg = c.blue })
hl("Delimiter",    { fg = c.subtext1 })
hl("SpecialComment", { fg = c.overlay2, italic = true })
hl("Debug",        { fg = c.rose })

hl("Underlined",   { fg = c.blue_lt, underline = true })
hl("Ignore",       { fg = c.overlay0 })
hl("Error",        { fg = c.rose, bold = true })
hl("Todo",         { fg = c.sand, bg = c.surface1, bold = true })

-- ============================================================
--  Diagnostics
-- ============================================================
hl("DiagnosticError",      { fg = c.rose })
hl("DiagnosticWarn",       { fg = c.sand })
hl("DiagnosticInfo",       { fg = c.blue })
hl("DiagnosticHint",       { fg = c.aqua })
hl("DiagnosticOk",         { fg = c.sage })

hl("DiagnosticUnderlineError", { sp = c.rose, undercurl = true })
hl("DiagnosticUnderlineWarn",  { sp = c.sand, undercurl = true })
hl("DiagnosticUnderlineInfo",  { sp = c.blue, undercurl = true })
hl("DiagnosticUnderlineHint",  { sp = c.aqua, undercurl = true })

hl("DiagnosticVirtualTextError", { fg = c.rose, bg = c.none })
hl("DiagnosticVirtualTextWarn",  { fg = c.sand, bg = c.none })
hl("DiagnosticVirtualTextInfo",  { fg = c.blue, bg = c.none })
hl("DiagnosticVirtualTextHint",  { fg = c.aqua, bg = c.none })

-- ============================================================
--  LSP
-- ============================================================
hl("LspReferenceText",  { bg = c.surface1 })
hl("LspReferenceRead",  { bg = c.surface1 })
hl("LspReferenceWrite", { bg = c.surface1 })
hl("LspSignatureActiveParameter", { fg = c.sand, bold = true })

hl("LspInlayHint",      { fg = c.overlay0, bg = c.mantle, italic = true })

-- ============================================================
--  Treesitter
-- ============================================================
hl("@variable",            { fg = c.text })
hl("@variable.builtin",    { fg = c.rose })
hl("@variable.parameter",  { fg = c.subtext1, italic = true })
hl("@variable.member",     { fg = c.blue_lt })

hl("@constant",            { fg = c.rose_lt })
hl("@constant.builtin",    { fg = c.sand })
hl("@constant.macro",      { fg = c.pink })

hl("@module",              { fg = c.sand_lt })
hl("@label",               { fg = c.mauve })

hl("@string",              { fg = c.sage })
hl("@string.escape",       { fg = c.pink })
hl("@string.special",      { fg = c.aqua })
hl("@string.special.url",  { fg = c.blue_lt, underline = true })
hl("@character",           { fg = c.sage })
hl("@character.special",   { fg = c.aqua })
hl("@number",              { fg = c.sand })
hl("@boolean",             { fg = c.sand })
hl("@float",               { fg = c.sand })

hl("@function",            { fg = c.blue })
hl("@function.builtin",    { fg = c.blue, italic = true })
hl("@function.call",       { fg = c.blue })
hl("@function.macro",      { fg = c.pink })
hl("@function.method",     { fg = c.blue })
hl("@function.method.call",{ fg = c.blue })
hl("@constructor",         { fg = c.sand_lt })

hl("@keyword",             { fg = c.mauve, italic = true })
hl("@keyword.function",    { fg = c.mauve, italic = true })
hl("@keyword.operator",    { fg = c.mauve })
hl("@keyword.return",      { fg = c.mauve, italic = true })
hl("@keyword.import",      { fg = c.pink })
hl("@keyword.conditional", { fg = c.mauve })
hl("@keyword.repeat",      { fg = c.mauve })
hl("@keyword.exception",   { fg = c.rose })

hl("@operator",            { fg = c.aqua })
hl("@punctuation.delimiter", { fg = c.subtext1 })
hl("@punctuation.bracket",   { fg = c.subtext0 })
hl("@punctuation.special",   { fg = c.aqua })

hl("@type",                { fg = c.sand_lt })
hl("@type.builtin",        { fg = c.sand_lt, italic = true })
hl("@type.definition",     { fg = c.sand_lt })
hl("@attribute",           { fg = c.pink })
hl("@property",            { fg = c.blue_lt })
hl("@field",               { fg = c.blue_lt })

hl("@comment",             { fg = c.overlay1, italic = true })
hl("@comment.todo",        { fg = c.sand, bg = c.surface1, bold = true })
hl("@comment.note",        { fg = c.aqua, bg = c.surface1, bold = true })
hl("@comment.warning",     { fg = c.sand_lt, bg = c.surface1, bold = true })
hl("@comment.error",       { fg = c.rose, bg = c.surface1, bold = true })

hl("@tag",                 { fg = c.blue })
hl("@tag.attribute",       { fg = c.pink, italic = true })
hl("@tag.delimiter",       { fg = c.subtext0 })

-- markdown / text
hl("@markup.heading",        { fg = c.blue, bold = true })
hl("@markup.heading.1",      { fg = c.blue, bold = true })
hl("@markup.heading.2",      { fg = c.mauve, bold = true })
hl("@markup.heading.3",      { fg = c.sand, bold = true })
hl("@markup.heading.4",      { fg = c.sage, bold = true })
hl("@markup.heading.5",      { fg = c.aqua, bold = true })
hl("@markup.heading.6",      { fg = c.pink, bold = true })
hl("@markup.strong",         { fg = c.bright, bold = true })
hl("@markup.italic",         { fg = c.text,  italic = true })
hl("@markup.strikethrough",  { fg = c.overlay2, strikethrough = true })
hl("@markup.underline",      { fg = c.text, underline = true })
hl("@markup.quote",          { fg = c.overlay2, italic = true })
hl("@markup.math",           { fg = c.aqua })
hl("@markup.link",           { fg = c.blue_lt, underline = true })
hl("@markup.link.label",     { fg = c.blue })
hl("@markup.link.url",       { fg = c.blue_lt, underline = true })
hl("@markup.raw",            { fg = c.sage, bg = c.mantle })
hl("@markup.raw.block",      { fg = c.text, bg = c.mantle })
hl("@markup.list",           { fg = c.aqua })
hl("@markup.list.checked",   { fg = c.sage })
hl("@markup.list.unchecked", { fg = c.overlay2 })

-- LSP semantic
hl("@lsp.type.namespace",      { link = "@module" })
hl("@lsp.type.type",           { link = "@type" })
hl("@lsp.type.class",          { link = "@type" })
hl("@lsp.type.enum",           { link = "@type" })
hl("@lsp.type.interface",      { link = "@type" })
hl("@lsp.type.struct",         { link = "@type" })
hl("@lsp.type.parameter",      { link = "@variable.parameter" })
hl("@lsp.type.variable",       { link = "@variable" })
hl("@lsp.type.property",       { link = "@property" })
hl("@lsp.type.enumMember",     { link = "@constant" })
hl("@lsp.type.function",       { link = "@function" })
hl("@lsp.type.method",         { link = "@function.method" })
hl("@lsp.type.macro",          { link = "@function.macro" })
hl("@lsp.type.decorator",      { link = "@attribute" })

-- ============================================================
--  Git / Diff
-- ============================================================
hl("DiffAdd",      { bg = "#1f3324" })
hl("DiffChange",   { bg = "#1f2a3a" })
hl("DiffDelete",   { fg = c.rose, bg = "#3a1f24" })
hl("DiffText",     { bg = "#2d4060", bold = true })

hl("diffAdded",    { fg = c.sage })
hl("diffRemoved",  { fg = c.rose })
hl("diffChanged",  { fg = c.blue })
hl("diffFile",     { fg = c.sand_lt })
hl("diffLine",     { fg = c.mauve })
hl("diffNewFile",  { fg = c.sage })
hl("diffOldFile",  { fg = c.rose })

-- gitsigns
hl("GitSignsAdd",          { fg = c.sage })
hl("GitSignsChange",       { fg = c.blue })
hl("GitSignsDelete",       { fg = c.rose })
hl("GitSignsAddNr",        { fg = c.sage })
hl("GitSignsChangeNr",     { fg = c.blue })
hl("GitSignsDeleteNr",     { fg = c.rose })
hl("GitSignsAddLn",        { bg = "#1f3324" })
hl("GitSignsChangeLn",     { bg = "#1f2a3a" })
hl("GitSignsDeleteLn",     { bg = "#3a1f24" })
hl("GitSignsCurrentLineBlame", { fg = c.overlay1, italic = true })

-- ============================================================
--  Telescope
-- ============================================================
hl("TelescopeNormal",         { fg = c.text,    bg = c.none })
hl("TelescopeBorder",         { fg = c.blue,    bg = c.none })
hl("TelescopeTitle",          { fg = c.bright,  bg = c.surface2, bold = true })
hl("TelescopePromptNormal",   { fg = c.text,    bg = c.none })
hl("TelescopePromptBorder",   { fg = c.blue,    bg = c.none })
hl("TelescopePromptTitle",    { fg = c.bright,  bg = c.blue, bold = true })
hl("TelescopePromptPrefix",   { fg = c.rose_lt, bg = c.none })
hl("TelescopeResultsNormal",  { fg = c.text,    bg = c.none })
hl("TelescopeResultsBorder",  { fg = c.blue,    bg = c.none })
hl("TelescopePreviewNormal",  { fg = c.text,    bg = c.none })
hl("TelescopePreviewBorder",  { fg = c.blue,    bg = c.none })
hl("TelescopeSelection",      { fg = c.bright,  bg = c.surface1, bold = true })
hl("TelescopeSelectionCaret", { fg = c.rose_lt, bg = c.surface1 })
hl("TelescopeMatching",       { fg = c.sand,    bold = true })
hl("TelescopeMultiSelection", { fg = c.mauve })

-- ============================================================
--  NeoTree
-- ============================================================
hl("NeoTreeNormal",            { fg = c.text, bg = c.none })
hl("NeoTreeNormalNC",          { fg = c.text, bg = c.none })
hl("NeoTreeEndOfBuffer",       { fg = c.overlay0, bg = c.none })
hl("NeoTreeRootName",          { fg = c.blue, bold = true })
hl("NeoTreeDirectoryName",     { fg = c.text })
hl("NeoTreeDirectoryIcon",     { fg = c.blue })
hl("NeoTreeFileName",          { fg = c.subtext1 })
hl("NeoTreeFileIcon",          { fg = c.overlay2 })
hl("NeoTreeIndentMarker",      { fg = c.surface2 })
hl("NeoTreeExpander",          { fg = c.overlay2 })
hl("NeoTreeWinSeparator",      { fg = c.surface2, bg = c.none })
hl("NeoTreeStatusLine",        { bg = c.none })
hl("NeoTreeStatusLineNC",      { fg = c.overlay0, bg = c.none })
hl("NeoTreeGitAdded",          { fg = c.sage })
hl("NeoTreeGitConflict",       { fg = c.rose })
hl("NeoTreeGitDeleted",        { fg = c.rose })
hl("NeoTreeGitIgnored",        { fg = c.overlay0 })
hl("NeoTreeGitModified",       { fg = c.blue })
hl("NeoTreeGitUntracked",      { fg = c.mauve })
hl("NeoTreeFloatBorder",       { fg = c.blue, bg = c.none })
hl("NeoTreeFloatTitle",        { fg = c.blue, bg = c.none, bold = true })
hl("NeoTreeCursorLine",        { bg = c.surface0 })

-- ============================================================
--  Indent-blankline
-- ============================================================
hl("IblIndent",      { fg = c.surface1 })
hl("IblScope",       { fg = c.blue })
hl("IblWhitespace",  { fg = c.surface1 })

-- ============================================================
--  cmp / completions
-- ============================================================
hl("CmpItemAbbr",              { fg = c.text })
hl("CmpItemAbbrDeprecated",    { fg = c.overlay1, strikethrough = true })
hl("CmpItemAbbrMatch",         { fg = c.sand, bold = true })
hl("CmpItemAbbrMatchFuzzy",    { fg = c.sand_lt, bold = true })
hl("CmpItemMenu",              { fg = c.overlay2 })
hl("CmpItemKindDefault",       { fg = c.subtext0 })
hl("CmpItemKindFunction",      { fg = c.blue })
hl("CmpItemKindMethod",        { fg = c.blue })
hl("CmpItemKindConstructor",   { fg = c.sand_lt })
hl("CmpItemKindVariable",      { fg = c.text })
hl("CmpItemKindField",         { fg = c.blue_lt })
hl("CmpItemKindProperty",      { fg = c.blue_lt })
hl("CmpItemKindClass",         { fg = c.sand_lt })
hl("CmpItemKindInterface",     { fg = c.sand_lt })
hl("CmpItemKindStruct",        { fg = c.sand_lt })
hl("CmpItemKindModule",        { fg = c.pink })
hl("CmpItemKindKeyword",       { fg = c.mauve })
hl("CmpItemKindOperator",      { fg = c.aqua })
hl("CmpItemKindSnippet",       { fg = c.mint })
hl("CmpItemKindText",          { fg = c.text })
hl("CmpItemKindFile",          { fg = c.blue })
hl("CmpItemKindFolder",        { fg = c.blue })
hl("CmpItemKindEnum",          { fg = c.sand_lt })
hl("CmpItemKindEnumMember",    { fg = c.rose_lt })
hl("CmpItemKindConstant",      { fg = c.rose_lt })

-- ============================================================
--  Noice / Notify
-- ============================================================
hl("NoiceCmdline",             { fg = c.text, bg = c.none })
hl("NoiceCmdlinePopup",        { fg = c.text, bg = c.none })
hl("NoiceCmdlinePopupBorder",  { fg = c.blue, bg = c.none })
hl("NoiceCmdlineIcon",         { fg = c.blue })
hl("NoiceConfirm",             { fg = c.text, bg = c.none })
hl("NoiceConfirmBorder",       { fg = c.blue, bg = c.none })
hl("NoiceMini",                { fg = c.text, bg = c.none })
hl("NoicePopup",               { fg = c.text, bg = c.none })
hl("NoicePopupBorder",         { fg = c.blue, bg = c.none })
hl("NoiceCmdlinePopupTitle",   { fg = c.blue, bold = true })
hl("NoiceCmdlinePopupBorderSearch", { fg = c.sand, bg = c.none })
hl("NoiceFormatProgressDone",  { fg = c.base, bg = c.sage })
hl("NoiceFormatProgressTodo",  { fg = c.text, bg = c.surface1 })
hl("NoiceLspProgressClient",   { fg = c.blue })
hl("NoiceLspProgressSpinner",  { fg = c.mauve })
hl("NoiceLspProgressTitle",    { fg = c.text })

hl("NotifyERRORBorder", { fg = c.rose })
hl("NotifyWARNBorder",  { fg = c.sand })
hl("NotifyINFOBorder",  { fg = c.blue })
hl("NotifyDEBUGBorder", { fg = c.overlay2 })
hl("NotifyTRACEBorder", { fg = c.mauve })
hl("NotifyERRORIcon",   { fg = c.rose })
hl("NotifyWARNIcon",    { fg = c.sand })
hl("NotifyINFOIcon",    { fg = c.blue })
hl("NotifyDEBUGIcon",   { fg = c.overlay2 })
hl("NotifyTRACEIcon",   { fg = c.mauve })
hl("NotifyERRORTitle",  { fg = c.rose, bold = true })
hl("NotifyWARNTitle",   { fg = c.sand, bold = true })
hl("NotifyINFOTitle",   { fg = c.blue, bold = true })
hl("NotifyDEBUGTitle",  { fg = c.overlay2, bold = true })
hl("NotifyTRACETitle",  { fg = c.mauve, bold = true })

-- ============================================================
--  Mason
-- ============================================================
hl("MasonNormal",                 { fg = c.text, bg = c.none })
hl("MasonHeader",                 { fg = c.base, bg = c.blue, bold = true })
hl("MasonHeaderSecondary",        { fg = c.base, bg = c.mauve, bold = true })
hl("MasonHighlight",              { fg = c.blue })
hl("MasonHighlightBlock",         { fg = c.base, bg = c.blue })
hl("MasonHighlightBlockBold",     { fg = c.base, bg = c.blue, bold = true })
hl("MasonHighlightSecondary",     { fg = c.mauve })
hl("MasonHighlightBlockSecondary",{ fg = c.base, bg = c.mauve })
hl("MasonHighlightBlockBoldSecondary", { fg = c.base, bg = c.mauve, bold = true })
hl("MasonMuted",                  { fg = c.overlay1 })
hl("MasonMutedBlock",             { fg = c.overlay2, bg = c.surface0 })
hl("MasonMutedBlockBold",         { fg = c.bright, bg = c.surface1, bold = true })
hl("MasonError",                  { fg = c.rose })
hl("MasonWarning",                { fg = c.sand })
hl("MasonHeading",                { fg = c.blue, bold = true })
hl("MasonLink",                   { fg = c.blue_lt, underline = true })

-- ============================================================
--  Lazy
-- ============================================================
hl("LazyNormal",        { fg = c.text, bg = c.none })
hl("LazyButton",        { fg = c.text, bg = c.surface0 })
hl("LazyButtonActive",  { fg = c.bright, bg = c.surface2, bold = true })
hl("LazyH1",            { fg = c.bright, bg = c.blue, bold = true })
hl("LazyH2",            { fg = c.blue, bold = true })
hl("LazyProp",          { fg = c.subtext1 })
hl("LazyCommit",        { fg = c.sage })
hl("LazyDir",           { fg = c.blue })
hl("LazyUrl",           { fg = c.blue_lt, underline = true })

-- ============================================================
--  Alpha
-- ============================================================
hl("AlphaHeader",   { fg = c.blue })
hl("AlphaButtons",  { fg = c.subtext1 })
hl("AlphaShortcut", { fg = c.rose_lt })
hl("AlphaFooter",   { fg = c.overlay2, italic = true })

-- ============================================================
--  WhichKey
-- ============================================================
hl("WhichKey",          { fg = c.blue })
hl("WhichKeyGroup",     { fg = c.mauve })
hl("WhichKeyDesc",      { fg = c.text })
hl("WhichKeySeparator", { fg = c.overlay1 })
hl("WhichKeyFloat",     { bg = c.none })
hl("WhichKeyBorder",    { fg = c.blue, bg = c.none })

-- ============================================================
--  Oil
-- ============================================================
hl("OilDir",       { fg = c.blue, bold = true })
hl("OilDirIcon",   { fg = c.blue })
hl("OilLink",      { fg = c.aqua, underline = true })
hl("OilFile",      { fg = c.subtext1 })
hl("OilCreate",    { fg = c.sage })
hl("OilDelete",    { fg = c.rose })
hl("OilChange",    { fg = c.sand })
hl("OilCopy",      { fg = c.mauve })
hl("OilMove",      { fg = c.aqua })

-- ============================================================
--  Neogit
-- ============================================================
hl("NeogitBranch",         { fg = c.mauve, bold = true })
hl("NeogitRemote",         { fg = c.sage,  bold = true })
hl("NeogitHunkHeader",     { fg = c.subtext1, bg = c.surface0 })
hl("NeogitHunkHeaderHighlight", { fg = c.bright, bg = c.surface1, bold = true })
hl("NeogitDiffContextHighlight", { bg = c.surface0 })
hl("NeogitDiffAddHighlight",     { fg = c.sage, bg = "#1f3324" })
hl("NeogitDiffDeleteHighlight",  { fg = c.rose, bg = "#3a1f24" })

-- ============================================================
--  Obsidian
-- ============================================================
hl("ObsidianTodo",      { fg = c.sand, bold = true })
hl("ObsidianDone",      { fg = c.sage, bold = true })
hl("ObsidianRightArrow", { fg = c.aqua, bold = true })
hl("ObsidianTilde",     { fg = c.rose, bold = true })
hl("ObsidianBullet",    { fg = c.blue, bold = true })
hl("ObsidianRefText",   { fg = c.blue_lt, underline = true })
hl("ObsidianExtLinkIcon", { fg = c.aqua })
hl("ObsidianTag",       { fg = c.mauve })
hl("ObsidianHighlightText", { bg = c.sand, fg = c.sel_fg })

-- ============================================================
--  Lualine fallback (when no theme is set explicitly)
-- ============================================================
hl("lualine_a_normal",  { fg = c.base,   bg = c.blue,    bold = true })
hl("lualine_a_insert",  { fg = c.base,   bg = c.sage,    bold = true })
hl("lualine_a_visual",  { fg = c.base,   bg = c.mauve,   bold = true })
hl("lualine_a_replace", { fg = c.base,   bg = c.rose,    bold = true })
hl("lualine_a_command", { fg = c.base,   bg = c.sand,    bold = true })
hl("lualine_b_normal",  { fg = c.subtext1, bg = c.surface1 })
hl("lualine_c_normal",  { fg = c.subtext0, bg = c.mantle })
