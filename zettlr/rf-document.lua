-- Pandoc Lua filter for the Zettlr export profile "rf-doc".
--
-- Pandoc is only the messenger: the note is handed to rf-document
-- (https://github.com/jcmx9/real-fast-document), which builds the PDF.
-- Pandoc then ends with rf-document's exit code before writing anything
-- itself, so the PDF engine named in the profile is never used.
--
-- Zettlr runs Pandoc in the note's folder. With unsaved changes it passes a
-- temporary copy of the note, so RFD_BASE_DIR tells rf-document where
-- relative paths (images, logo) start. RFD_NO_OPEN keeps rf-document from
-- opening the PDF; Zettlr handles that.

-- Written by the installer; empty or unreplaced means: search the usual places
local CONFIGURED = "@RFD@"

local INSTALL_HINT = "https://github.com/jcmx9/real-fast-document#installation"

local windows = package.config:sub(1, 1) == "\\"

local function exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

local function candidates()
  local list = {}
  local function add(path)
    if path and path ~= "" then
      table.insert(list, path)
    end
  end
  if not CONFIGURED:match("^@") then
    add(CONFIGURED)
  end
  add(os.getenv("RF_DOCUMENT"))
  local name = windows and "rf-document.cmd" or "rf-document"
  if windows then
    local local_app_data = os.getenv("LOCALAPPDATA")
    if local_app_data then
      add(local_app_data .. "\\Microsoft\\WindowsApps\\" .. name)
    end
  else
    -- GUI apps such as Zettlr often start without the user's shell PATH
    local home = os.getenv("HOME")
    if home then
      add(home .. "/.local/bin/" .. name)
    end
    add("/opt/homebrew/bin/" .. name)
    add("/usr/local/bin/" .. name)
  end
  local separator = windows and ";" or ":"
  for dir in (os.getenv("PATH") or ""):gmatch("[^" .. separator .. "]+") do
    add(dir .. (windows and "\\" or "/") .. name)
  end
  return list
end

local function find_rf_document()
  for _, path in ipairs(candidates()) do
    if exists(path) then
      return path
    end
  end
end

local function absolute(path)
  if windows then
    if path:match("^%a:[\\/]") or path:match("^[\\/][\\/]") then
      return path
    end
  elseif path:sub(1, 1) == "/" then
    return path
  end
  return pandoc.path.join({ pandoc.system.get_working_directory(), path })
end

local function command(rf_document, input, output, base)
  if windows then
    -- cmd.exe: the line does not start with a quote, so /c keeps all quotes
    return string.format(
      'set "RFD_NO_OPEN=1" && set "RFD_BASE_DIR=%s" && call "%s" "%s" "%s"',
      base, rf_document, input, output
    )
  end
  local function quote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
  end
  return "RFD_NO_OPEN=1 RFD_BASE_DIR=" .. quote(base) .. " "
    .. quote(rf_document) .. " " .. quote(input) .. " " .. quote(output)
end

local function fail(message)
  io.stderr:write(message .. "\n")
  os.exit(1)
end

function Pandoc()
  local input = PANDOC_STATE.input_files[1]
  local output = PANDOC_STATE.output_file
  if not input or input == "-" or not output then
    fail("rf-doc: Zettlr hat keine Notiz oder kein Ziel übergeben.")
  end
  local rf_document = find_rf_document()
  if not rf_document then
    fail("rf-doc: rf-document wurde nicht gefunden. Installation: " .. INSTALL_HINT)
  end
  local ok, _, code = os.execute(command(
    rf_document,
    absolute(input),
    absolute(output),
    pandoc.system.get_working_directory()
  ))
  os.exit(ok and 0 or (code or 1))
end
