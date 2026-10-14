-- @description Smart Duplicate Items
-- @author Jack Di Lante
-- @version 1.0
-- @provides [main] .

-- Smart Duplicate Items (FL-style, time selection + selection intersect logic)

local function ItemIntersectsTimeSel(item, start_time, end_time)
  local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  return item_end > start_time and item_start < end_time
end

local function DuplicateItemsAtTime(items, paste_time, anchor_time)
  local new_items = {}
  for _, item in ipairs(items) do
    local track = reaper.GetMediaItemTrack(item)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local take = reaper.GetActiveTake(item)

    local rel_offset = pos - anchor_time
    local new_item = reaper.AddMediaItemToTrack(track)
    reaper.SetMediaItemInfo_Value(new_item, "D_POSITION", paste_time + rel_offset)
    reaper.SetMediaItemInfo_Value(new_item, "D_LENGTH", len)

    if take then
      local src = reaper.GetMediaItemTake_Source(take)
      local new_take = reaper.AddTakeToMediaItem(new_item)
      reaper.SetMediaItemTake_Source(new_take, src)
      reaper.SetMediaItemInfo_Value(new_item, "I_CURTAKE", 0)
    end

    table.insert(new_items, new_item)
  end
  return new_items
end

---------------- MAIN ----------------

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local time_sel_exists = (start_time ~= end_time)

local items_to_duplicate = {}
local anchor_time = nil
local paste_time = nil
local new_time_sel_start = nil
local new_time_sel_end = nil

if time_sel_exists then
  -- Only consider items that are BOTH selected AND intersect the time selection
  local sel_count = reaper.CountSelectedMediaItems(0)
  for i = 0, sel_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if ItemIntersectsTimeSel(item, start_time, end_time) then
      table.insert(items_to_duplicate, item)
    end
  end

  if #items_to_duplicate > 0 then
    anchor_time = start_time
    paste_time = end_time
    new_time_sel_start = paste_time
    new_time_sel_end = paste_time + (end_time - start_time)
  end

else
  -- No time selection: use selected items only
  local sel_count = reaper.CountSelectedMediaItems(0)
  for i = 0, sel_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    table.insert(items_to_duplicate, item)
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_end = pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    if not anchor_time or pos < anchor_time then anchor_time = pos end
    if not paste_time or item_end > paste_time then paste_time = item_end end
  end
end

-- Deselect all first
reaper.Main_OnCommand(40289, 0)

-- Perform duplication
if #items_to_duplicate > 0 then
  local new_items = DuplicateItemsAtTime(items_to_duplicate, paste_time, anchor_time)

  -- Select only the new items
  for _, item in ipairs(new_items) do
    reaper.SetMediaItemSelected(item, true)
  end

  -- Update time selection if it was active
  if time_sel_exists then
    reaper.GetSet_LoopTimeRange(true, false, new_time_sel_start, new_time_sel_end, false)
  end
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Smart Duplicate Items (FL-style refined)", -1)

