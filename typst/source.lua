-- Pandoc Lua filter for the Source Typst template.
--
-- 1. Alerts become calls to the template's alert() function, so they keep
--    their kind and color: GitHub keywords (> [!NOTE] …, parsed by Pandoc's
--    "alerts" extension) and German keywords (> [!HINWEIS] …).
-- 2. Typographic quotes are passed to Typst verbatim. Pandoc would turn
--    “ ” into a plain " and Typst would then guess the wrong German quote.
-- 3. Local images are handed to Typst by their path relative to the note.
--    Pandoc would copy them into a temporary folder outside Typst's root.
-- 4. Front matter "logo" becomes the logo next to the title; "logo-height"
--    sets its maximum height (default 20mm, see the template).
-- 5. Task lists with owners ("- [ ] Task – Name, bis 17.10.") become a
--    table with the columns task, owner, due date and status.
-- 6. \newpage, \pagebreak and <!-- pagebreak --> start a new page.

local TEXT = {
  de = {
    alerts = {
      note = "Info",
      tip = "Tipp",
      important = "Wichtig",
      warning = "Hinweis",
      caution = "Achtung",
    },
    tasks = { "Aufgabe", "Wer", "Bis", "Status" },
  },
  en = {
    alerts = {
      note = "Note",
      tip = "Tip",
      important = "Important",
      warning = "Warning",
      caution = "Caution",
    },
    tasks = { "Task", "Owner", "Due", "Status" },
  },
}

-- German keywords -> alert kind
local GERMAN_KEYWORDS = {
  INFO = "note",
  TIPP = "tip",
  WICHTIG = "important",
  HINWEIS = "warning",
  ACHTUNG = "caution",
}

-- Words that introduce the due date after the owner
local DUE_WORDS = { "bis", "due", "by" }

local lang = "de"

local function text()
  return TEXT[lang] or TEXT.en
end

-- A Typst string literal
local function typst_string(s)
  return '"' .. s:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

-- --- Images ------------------------------------------------------------------

-- Path of a local image as Typst should see it, or nil for remote images
local function local_path(src)
  if src:match("^%a[%w+.-]*://") or src:match("^data:") then
    return nil
  end
  local path = src:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  if path:sub(1, 2) == "~/" then
    path = (os.getenv("HOME") or os.getenv("USERPROFILE") or "~") .. path:sub(2)
  end
  return (path:gsub("\\", "/"))
end

-- Typst length from an image attribute such as 50%, 8cm or 300px
local function typst_length(value)
  if not value then
    return nil
  end
  local number, unit = value:match("^%s*([%d.]+)%s*(%a*%%?)%s*$")
  if not number then
    return nil
  end
  if unit == "" or unit == "px" then
    return string.format("%gpt", tonumber(number) * 0.75)
  end
  if unit == "%" or unit == "cm" or unit == "mm" or unit == "in" or unit == "pt" or unit == "em" then
    return number .. unit
  end
  return nil
end

local function image(img)
  local path = local_path(img.src)
  if not path then
    return nil
  end
  local args = { typst_string(path) }
  local width = typst_length(img.attributes.width)
  local height = typst_length(img.attributes.height)
  if width then
    table.insert(args, "width: " .. width)
  end
  if height then
    table.insert(args, "height: " .. height)
  end
  -- Alt text is required for accessible PDFs: caption, else the file name
  local alt = pandoc.utils.stringify(img.caption)
  if alt == "" then
    alt = path:match("([^/]+)$"):gsub("%.%w+$", "")
  end
  table.insert(args, "alt: " .. typst_string(alt))
  return pandoc.RawInline("typst", "#box(image(" .. table.concat(args, ", ") .. "))")
end

-- --- Metadata ----------------------------------------------------------------

function Meta(meta)
  -- Accessible PDFs need a title; without "# Title" use the file name
  if not meta.title and PANDOC_STATE.input_files[1] then
    local name = PANDOC_STATE.input_files[1]:match("([^/\\]+)$")
    meta["pdf-title"] = (name:gsub("%.%w+$", ""))
  end
  if meta.lang then
    lang = pandoc.utils.stringify(meta.lang):sub(1, 2)
  end
  if meta.logo then
    local path = local_path(pandoc.utils.stringify(meta.logo))
    if path then
      meta["logo-path"] = pandoc.RawInline("typst", typst_string(path))
    end
  end
  if meta["logo-height"] then
    -- Absolute lengths only; a percentage has no meaning for the logo
    local height = typst_length(pandoc.utils.stringify(meta["logo-height"]))
    if height and height:sub(-1) == "%" then
      height = nil
    end
    meta["logo-height"] = height and pandoc.RawInline("typst", height) or nil
  end
  return meta
end

-- --- Alerts ------------------------------------------------------------------

local function alert_kind(div)
  for _, class in ipairs(div.classes) do
    if TEXT.de.alerts[class] then
      return class
    end
  end
end

local function alert_blocks(kind, body)
  local title = text().alerts[kind]
  local blocks = { pandoc.RawBlock("typst", string.format("#alert(%s, %s)[", typst_string(kind), typst_string(title))) }
  for _, block in ipairs(body) do
    table.insert(blocks, block)
  end
  table.insert(blocks, pandoc.RawBlock("typst", "]"))
  return blocks
end

local function alert(div)
  local kind = alert_kind(div)
  if not kind then
    return nil
  end
  local body = div.content
  local first = body[1]
  if first and first.t == "Div" and first.classes:includes("title") then
    body = { table.unpack(body, 2) }
  end
  return alert_blocks(kind, body)
end

-- > [!HINWEIS] … arrives as a plain block quote starting with "[!HINWEIS]"
local function german_alert(quote)
  local first = quote.content[1]
  if not first or (first.t ~= "Para" and first.t ~= "Plain") then
    return nil
  end
  local marker = first.content[1]
  if not marker or marker.t ~= "Str" then
    return nil
  end
  local keyword = marker.text:match("^%[!(%u+)%]$")
  local kind = keyword and GERMAN_KEYWORDS[keyword]
  if not kind then
    return nil
  end

  local inlines = first.content:clone()
  inlines:remove(1)
  while #inlines > 0 and (inlines[1].t == "LineBreak" or inlines[1].t == "SoftBreak" or inlines[1].t == "Space") do
    inlines:remove(1)
  end
  local body = { table.unpack(quote.content, 2) }
  if #inlines > 0 then
    table.insert(body, 1, pandoc.Para(inlines))
  end
  return alert_blocks(kind, body)
end

-- --- Tasks -------------------------------------------------------------------

local DASHES = { ["–"] = true, ["—"] = true, ["-"] = true }

-- Split "☐ Task – Name, bis 17.10." into its parts, or nil if it is no task
local function task_parts(item)
  if #item ~= 1 or (item[1].t ~= "Plain" and item[1].t ~= "Para") then
    return nil
  end
  local inlines = item[1].content
  local box = inlines[1]
  if not box or box.t ~= "Str" or (box.text ~= "☐" and box.text ~= "☒") then
    return nil
  end

  local dash
  for i = #inlines - 1, 3, -1 do
    local el = inlines[i]
    if el.t == "Str" and DASHES[el.text] and inlines[i - 1].t == "Space" and inlines[i + 1].t == "Space" then
      dash = i
      break
    end
  end

  local task = pandoc.List({ table.unpack(inlines, 3, (dash or #inlines + 2) - 2) })
  local owner, due = "", ""
  if dash then
    owner = pandoc.utils.stringify(pandoc.Inlines({ table.unpack(inlines, dash + 2) }))
    for _, word in ipairs(DUE_WORDS) do
      local before, after = owner:match("^(.-),?%s+" .. word .. "%s*(.-)%s*$")
      if before then
        owner, due = before, after
        break
      end
    end
  end
  return { box = box.text, task = task, owner = owner, due = due, has_owner = dash ~= nil }
end

local function plain(s)
  return { pandoc.Plain(pandoc.Inlines(s)) }
end

local function task_table(list)
  local rows, any_owner = {}, false
  for _, item in ipairs(list.content) do
    local parts = task_parts(item)
    if not parts then
      return nil
    end
    any_owner = any_owner or parts.has_owner
    table.insert(rows, {
      { pandoc.Plain(parts.task) },
      plain(parts.owner),
      plain(parts.due),
      plain(parts.box),
    })
  end
  if not any_owner then
    return nil
  end
  local header = {}
  for _, title in ipairs(text().tasks) do
    table.insert(header, plain(title))
  end
  local simple = pandoc.SimpleTable(
    {},
    { pandoc.AlignDefault, pandoc.AlignDefault, pandoc.AlignDefault, pandoc.AlignCenter },
    { 0.56, 0.2, 0.14, 0.1 },
    header,
    rows
  )
  return pandoc.utils.from_simple_table(simple)
end

-- --- Page breaks -------------------------------------------------------------

local PAGEBREAK = pandoc.RawBlock("typst", "#pagebreak(weak: true)")

local function raw_block(raw)
  local text = raw.text:match("^%s*(.-)%s*$")
  if raw.format == "tex" and (text == "\\newpage" or text == "\\pagebreak" or text == "\\clearpage") then
    return PAGEBREAK
  end
  if raw.format == "html" and text:match("^<!%-%-%s*pagebreak%s*%-%->$") then
    return PAGEBREAK
  end
end

-- --- Quotes ------------------------------------------------------------------

local QUOTES = { "„", "“", "”", "‚", "‘", "’", "»", "«", "›", "‹" }

local function quotes(str)
  local text = str.text
  local found = false
  for _, q in ipairs(QUOTES) do
    if text:find(q, 1, true) then
      found = true
      break
    end
  end
  if not found then
    return nil
  end

  local result = {}
  local buffer = ""
  local i = 1
  while i <= #text do
    local matched = nil
    for _, q in ipairs(QUOTES) do
      if text:sub(i, i + #q - 1) == q then
        matched = q
        break
      end
    end
    if matched then
      if buffer ~= "" then
        table.insert(result, pandoc.Str(buffer))
        buffer = ""
      end
      table.insert(result, pandoc.RawInline("typst", '#"' .. matched .. '"'))
      i = i + #matched
    else
      buffer = buffer .. text:sub(i, i)
      i = i + 1
    end
  end
  if buffer ~= "" then
    table.insert(result, pandoc.Str(buffer))
  end
  return result
end

return {
  { Meta = Meta },
  { BulletList = task_table, RawBlock = raw_block, Image = image },
  { Div = alert, BlockQuote = german_alert, Str = quotes },
}
