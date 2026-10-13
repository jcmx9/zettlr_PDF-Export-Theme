-- Pandoc Lua filter for the Source Typst template.
--
-- 1. Alerts become calls to the template's alert() function, so they keep
--    their kind and color: GitHub keywords (> [!NOTE] …, parsed by Pandoc's
--    "alerts" extension) and German keywords (> [!HINWEIS] …).
-- 2. Typographic quotes are passed to Typst verbatim. Pandoc would turn
--    “ ” into a plain " and Typst would then guess the wrong German quote.
-- 3. Local images are handed to Typst by their path (relative to the note
--    or absolute; ~, $VAR, ${VAR} and %VAR% are expanded). Pandoc would copy
--    them into a temporary folder outside Typst's root. A missing image or
--    logo leaves a note instead of breaking the export.
-- 4. Front matter "logo" becomes the logo next to the title; "logo-height"
--    sets its maximum height (default 20mm, see the template).
-- 5. Task lists ("- [ ] Task – Name, bis 17.10.") become a table with the
--    columns task, owner and due date (only when used) and status.
-- 6. \newpage, \pagebreak and <!-- pagebreak --> start a new page.
-- 9. A line such as "18. Oktober 2026" is a date, not an ordered list
--    starting at 18: numbered "lists" whose items start with a month name
--    become plain paragraphs again.
-- 8. ==highlight== becomes Typst's highlight (the CommonMark reader, which
--    parses notes the way Zettlr's editor does, has no "mark" extension).
-- 7. The title comes from the front matter. A note without "title:" that
--    starts with "# Title" keeps the old behavior: that heading becomes the
--    title and the other headings move up one level.

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
    missing = "Bild fehlt",
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
    missing = "Image missing",
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

-- Environment variables in paths; USER/HOME fall back to their Windows names
local function env(name)
  return os.getenv(name)
    or (name == "USER" and os.getenv("USERNAME"))
    or (name == "USERNAME" and os.getenv("USER"))
    or (name == "HOME" and os.getenv("USERPROFILE"))
    or (name == "USERPROFILE" and os.getenv("HOME"))
    or nil
end

local function expand(path)
  local first = path:sub(1, 1)
  if first == "~" and (#path == 1 or path:sub(2, 2) == "/" or path:sub(2, 2) == "\\") then
    path = (env("HOME") or "~") .. path:sub(2)
  end
  path = path:gsub("%$%{([%w_]+)%}", env):gsub("%$([%a_][%w_]*)", env):gsub("%%([%a_][%w_]*)%%", env)
  path = path:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  return (path:gsub("\\", "/"))
end

local function exists(path)
  local file = io.open(path, "rb")
  if file then
    file:close()
    return true
  end
  return false
end

-- A local image path as Typst reads it, or nil and the path for display.
-- Typst runs with root "/", relative paths start at the note's folder.
-- On Windows, absolute paths work on the drive the note is on.
local function resolve(src)
  local path = expand(src)
  local cwd = pandoc.system.get_working_directory():gsub("\\", "/")
  local drive, rest = path:match("^(%a):(/.*)$")
  local full, typst_path
  if drive then
    full = path
    local cwd_drive = cwd:match("^(%a):")
    typst_path = cwd_drive and cwd_drive:lower() == drive:lower() and rest or nil
  elseif path:sub(1, 1) == "/" then
    full, typst_path = path, path
  else
    full, typst_path = cwd .. "/" .. path, path
  end
  if typst_path and exists(full) then
    return typst_path
  end
  return nil, path
end

local function is_remote(src)
  return src:match("^%a[%w+.-]*://") ~= nil or src:match("^data:") ~= nil
end

local function warn(message)
  io.stderr:write("[Source PDF] " .. message .. "\n")
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
  if is_remote(img.src) then
    return nil
  end
  local path, shown = resolve(img.src)
  if not path then
    -- A missing image must not break the export: show a note instead
    warn("image not found: " .. shown)
    return pandoc.Emph({ pandoc.Str("[" .. text().missing .. ": " .. shown .. "]") })
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

-- --- Title -------------------------------------------------------------------

local function title_from_heading(doc)
  local first = doc.blocks[1]
  if doc.meta.title or not first or first.t ~= "Header" or first.level ~= 1 then
    return nil
  end
  doc.meta.title = pandoc.MetaInlines(first.content)
  doc.blocks:remove(1)
  doc.blocks = doc.blocks:walk({
    Header = function(h)
      h.level = math.max(1, h.level - 1)
      return h
    end,
  })
  return doc
end

-- --- Lists -------------------------------------------------------------------

-- CommonMark starts a new list where task items begin. Back to back, Typst
-- would join them into one loose list with paragraph spacing; merge them.
local function merge_lists(blocks)
  local result = pandoc.Blocks({})
  local changed = false
  for _, block in ipairs(blocks) do
    local previous = result[#result]
    if block.t == "BulletList" and previous and previous.t == "BulletList" then
      previous.content:extend(block.content)
      changed = true
    else
      result:insert(block)
    end
  end
  return changed and result or nil
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
  local logo = meta.logo and pandoc.utils.stringify(meta.logo) or ""
  if logo ~= "" and not is_remote(logo) then
    local path, shown = resolve(logo)
    if path then
      meta["logo-path"] = pandoc.RawInline("typst", typst_string(path))
    else
      warn("logo not found: " .. shown)
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
  return { box = box.text, task = task, owner = owner, due = due }
end

local function plain(s)
  return { pandoc.Plain(pandoc.Inlines(s)) }
end

local function task_table(list)
  local tasks = {}
  local has_owner, has_due = false, false
  for _, item in ipairs(list.content) do
    local parts = task_parts(item)
    if not parts then
      return nil
    end
    has_owner = has_owner or parts.owner ~= ""
    has_due = has_due or parts.due ~= ""
    table.insert(tasks, parts)
  end

  -- Columns: task, owner and due date only when used, status
  local titles = text().tasks
  local columns = {
    { title = titles[1], align = pandoc.AlignDefault, width = 0.56, cell = function(t) return { pandoc.Plain(t.task) } end },
  }
  if has_owner then
    table.insert(columns, { title = titles[2], align = pandoc.AlignDefault, width = 0.2, cell = function(t) return plain(t.owner) end })
  end
  if has_due then
    table.insert(columns, { title = titles[3], align = pandoc.AlignDefault, width = 0.14, cell = function(t) return plain(t.due) end })
  end
  table.insert(columns, { title = titles[4], align = pandoc.AlignCenter, width = 0.1, cell = function(t) return plain(t.box) end })

  local used = 0
  for _, column in ipairs(columns) do
    used = used + column.width
  end
  local header, aligns, widths, rows = {}, {}, {}, {}
  for i, column in ipairs(columns) do
    header[i] = plain(column.title)
    aligns[i] = column.align
    -- the task column takes the width of the dropped columns
    widths[i] = i == 1 and column.width + (1 - used) or column.width
  end
  for _, task in ipairs(tasks) do
    local row = {}
    for i, column in ipairs(columns) do
      row[i] = column.cell(task)
    end
    table.insert(rows, row)
  end
  return pandoc.utils.from_simple_table(pandoc.SimpleTable({}, aligns, widths, header, rows))
end

-- --- Dates -------------------------------------------------------------------

local MONTHS = {}
for _, name in ipairs({
  "januar", "jänner", "februar", "märz", "maerz", "april", "mai", "juni", "juli",
  "august", "september", "oktober", "november", "dezember",
  "jan", "feb", "mär", "mrz", "apr", "jun", "jul", "aug", "sep", "sept", "okt", "nov", "dez",
  "january", "february", "march", "may", "june", "july", "october", "december", "mar", "oct", "dec",
}) do
  MONTHS[name] = true
end

local function starts_with_month(item)
  if #item ~= 1 or (item[1].t ~= "Plain" and item[1].t ~= "Para") then
    return false
  end
  local first = item[1].content[1]
  return first ~= nil and first.t == "Str" and MONTHS[first.text:lower():gsub("[%.,]$", "")] == true
end

local function date_lines(list)
  for _, item in ipairs(list.content) do
    if not starts_with_month(item) then
      return nil
    end
  end
  -- One line per item, as typed
  local inlines = pandoc.Inlines({})
  for i, item in ipairs(list.content) do
    if i > 1 then
      inlines:insert(pandoc.LineBreak())
    end
    inlines:extend({ pandoc.Str((list.start + i - 1) .. "."), pandoc.Space() })
    inlines:extend(item[1].content)
  end
  return pandoc.Para(inlines)
end

-- --- Page breaks -------------------------------------------------------------

local PAGEBREAK = pandoc.RawBlock("typst", "#pagebreak(weak: true)")
local PAGEBREAK_COMMANDS = { ["\\newpage"] = true, ["\\pagebreak"] = true, ["\\clearpage"] = true }

-- The CommonMark reader keeps \newpage as a paragraph of its own
local function pagebreak_para(para)
  if #para.content == 1 and para.content[1].t == "Str" and PAGEBREAK_COMMANDS[para.content[1].text] then
    return PAGEBREAK
  end
end

local function raw_block(raw)
  local text = raw.text:match("^%s*(.-)%s*$")
  if raw.format == "tex" and (text == "\\newpage" or text == "\\pagebreak" or text == "\\clearpage") then
    return PAGEBREAK
  end
  if raw.format == "html" and text:match("^<!%-%-%s*pagebreak%s*%-%->$") then
    return PAGEBREAK
  end
end

-- --- Highlight ---------------------------------------------------------------

-- Trailing punctuation that may follow the closing ==
local function split_close(text)
  local inner, rest = text:match("^(.-)==([%.,;:!%?%)]*)$")
  return inner, rest
end

local function highlight(inlines)
  local result = pandoc.Inlines({})
  local i = 1
  local changed = false
  while i <= #inlines do
    local el = inlines[i]
    local close_at
    if el.t == "Str" and el.text:sub(1, 2) == "==" and #el.text > 2 then
      for j = i, #inlines do
        local candidate = inlines[j]
        if candidate.t == "Str" and split_close(j == i and candidate.text:sub(3) or candidate.text) then
          close_at = j
          break
        end
      end
    end
    if close_at then
      local first = el.text:sub(3)
      local inner = pandoc.Inlines({})
      local rest = ""
      if close_at == i then
        local text
        text, rest = split_close(first)
        inner:insert(pandoc.Str(text))
      else
        inner:insert(pandoc.Str(first))
        for k = i + 1, close_at - 1 do
          inner:insert(inlines[k])
        end
        local text
        text, rest = split_close(inlines[close_at].text)
        if text ~= "" then
          inner:insert(pandoc.Str(text))
        end
      end
      result:insert(pandoc.RawInline("typst", "#highlight["))
      result:extend(inner)
      result:insert(pandoc.RawInline("typst", "]"))
      if rest ~= "" then
        result:insert(pandoc.Str(rest))
      end
      i = close_at + 1
      changed = true
    else
      result:insert(el)
      i = i + 1
    end
  end
  return changed and result or nil
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
  { Pandoc = title_from_heading },
  { Blocks = merge_lists },
  { Meta = Meta },
  { BulletList = task_table, OrderedList = date_lines, RawBlock = raw_block, Para = pagebreak_para, Image = image, Inlines = highlight },
  { Div = alert, BlockQuote = german_alert, Str = quotes },
}
