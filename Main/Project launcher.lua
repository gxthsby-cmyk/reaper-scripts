-- @description Project launcher
-- @author Jack Di Lante
-- @version 1.0
-- @about
--   Quick project opener: lists every .rpp under the Reaper Projects folder,
--   most recently changed first. Type to filter (all words must match the
--   project name or folder), Up/Down to pick, Enter to open, Ctrl+Enter to
--   open in a new tab, Esc to close. Requires ReaImGui. Linux/macOS (uses find).
-- @provides [main] .

local ROOT = os.getenv("HOME") .. "/Nextcloud/Music/01 Reaper/Reaper Projects"
local MAX_SHOWN = 200

package.path = reaper.ImGui_GetBuiltinPath() .. "/?.lua"
local ImGui = require "imgui" "0.10"

-- All projects, newest first: { name, folder, path, lower-case search text }
local function scan()
  local list = {}
  local cmd = string.format("find %q -type f \\( -iname '*.rpp' \\) -not -path '*/Backups/*' -not -name '.*' -printf '%%T@\\t%%p\\n' 2>/dev/null | sort -rn", ROOT)
  local p = io.popen(cmd)
  if not p then return list end
  for line in p:lines() do
    local path = line:match("^[^\t]+\t(.+)$")
    if path then
      local rel = path:sub(#ROOT + 2)
      local folder, name = rel:match("^(.*)/([^/]+)%.[Rr][Pp][Pp]$")
      if not name then folder, name = "", rel:gsub("%.[Rr][Pp][Pp]$", "") end
      list[#list + 1] = { name = name, folder = folder, path = path, search = (rel):lower() }
    end
  end
  p:close()
  return list
end

local projects = scan()
local ctx = ImGui.CreateContext("Project launcher")
local query, selected, last_query = "", 1, nil
local filtered = {}
local first_frame = true

local function refilter()
  filtered = {}
  local words = {}
  for w in query:lower():gmatch("%S+") do words[#words + 1] = w end
  for _, p in ipairs(projects) do
    local ok = true
    for _, w in ipairs(words) do
      if not p.search:find(w, 1, true) then ok = false break end
    end
    if ok then
      filtered[#filtered + 1] = p
      if #filtered >= MAX_SHOWN then break end
    end
  end
  selected = 1
end

local function open(p, new_tab)
  if new_tab then reaper.Main_OnCommand(40859, 0) end -- New project tab
  reaper.Main_openProject(p.path)
end

local function loop()
  if query ~= last_query then refilter(); last_query = query end
  if first_frame then ImGui.SetNextWindowSize(ctx, 640, 480, ImGui.Cond_FirstUseEver) end
  local visible, open_win = ImGui.Begin(ctx, "Open project", true)
  local chosen, new_tab
  if visible then
    if first_frame or ImGui.IsWindowAppearing(ctx) then ImGui.SetKeyboardFocusHere(ctx) end
    ImGui.SetNextItemWidth(ctx, -1)
    local _, q = ImGui.InputTextWithHint(ctx, "##search", "Search projects…", query)
    query = q

    local n = #filtered
    if ImGui.IsKeyPressed(ctx, ImGui.Key_DownArrow) then selected = math.min(n, selected + 1) end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_UpArrow) then selected = math.max(1, selected - 1) end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_Enter) or ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter) then
      chosen = filtered[selected]
      new_tab = ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl)
    end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then open_win = false end

    if ImGui.BeginChild(ctx, "list", 0, 0) then
      for i, p in ipairs(filtered) do
        local label = p.name .. "##" .. i
        if ImGui.Selectable(ctx, label, i == selected, ImGui.SelectableFlags_AllowDoubleClick) then
          selected = i
          if ImGui.IsMouseDoubleClicked(ctx, ImGui.MouseButton_Left) then chosen = p end
        end
        if p.folder ~= "" then
          ImGui.SameLine(ctx)
          ImGui.TextDisabled(ctx, p.folder)
        end
        if i == selected and (ImGui.IsKeyPressed(ctx, ImGui.Key_DownArrow) or ImGui.IsKeyPressed(ctx, ImGui.Key_UpArrow)) then
          ImGui.SetScrollHereY(ctx, 0.5)
        end
      end
      if n == 0 then ImGui.TextDisabled(ctx, "No matching projects") end
      ImGui.EndChild(ctx)
    end
    ImGui.End(ctx)
  end
  first_frame = false
  if chosen then open(chosen, new_tab) return end
  if open_win then reaper.defer(loop) end
end

reaper.defer(loop)
