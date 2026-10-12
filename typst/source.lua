-- Pandoc Lua filter for the Source Typst template.
--
-- 1. Alerts (> [!NOTE] … with the "alerts" extension) become calls to the
--    template's alert() function, so they keep their kind and color.
-- 2. Typographic quotes are passed to Typst verbatim. Pandoc would turn
--    “ ” into a plain " and Typst would then guess the wrong German quote.

local ALERT_TITLES = {
  de = {
    note = "Hinweis",
    tip = "Tipp",
    important = "Wichtig",
    warning = "Warnung",
    caution = "Achtung",
  },
}

local lang = "de"

function Meta(meta)
  if meta.lang then
    lang = pandoc.utils.stringify(meta.lang):sub(1, 2)
  end
end

local function alert_kind(div)
  for _, class in ipairs(div.classes) do
    if ALERT_TITLES.de[class] then
      return class
    end
  end
end

local function alert(div)
  local kind = alert_kind(div)
  if not kind then
    return nil
  end
  local body = div.content
  local title = kind:sub(1, 1):upper() .. kind:sub(2)
  local first = body[1]
  if first and first.t == "Div" and first.classes:includes("title") then
    title = pandoc.utils.stringify(first)
    body = { table.unpack(body, 2) }
  end
  if ALERT_TITLES[lang] then
    title = ALERT_TITLES[lang][kind]
  end
  local blocks = { pandoc.RawBlock("typst", string.format('#alert("%s", "%s")[', kind, title)) }
  for _, block in ipairs(body) do
    table.insert(blocks, block)
  end
  table.insert(blocks, pandoc.RawBlock("typst", "]"))
  return blocks
end

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
  { Div = alert, Str = quotes },
}
