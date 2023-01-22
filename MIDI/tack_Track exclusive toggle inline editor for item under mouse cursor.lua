-- @description Track-exclusive toggle inline MIDI editor for item under mouse cursor
-- @author Jason Tackaberry (tack)
-- @version 1.0
-- @provides [main=main] .
-- @about
--   *WARNING*: if you bind this script to the 'e' key to replace the REAPER-default
--   binding to "Open inline editor" (which is recommended), you must also *remove* the
--   'e' shortcut from the "Close inline editor" action in the "MIDI Inline Editor"
--   section in REAPER's Actions list.  Otherwise this script won't be invoked to toggle
--   the editor closed, which will break other funtionality.  By simply removing the
--   shortcut assigned in the MIDI Inline Editor section, it will pass through to the Main
--   section where this script lives.
--
--   This script toggles the inline MIDI editor under the mouse cursor, or the first
--   selected item if there is no item under the cursor.  The behavior is exclusive within
--   the track, which means that on any given track online one item will have the inline
--   editor open, but other tracks are allowed items with the inline editor.  This
--   behavior is geared toward workflows that use the inline editor for quick adjustments.
--
--   Track height is also adjusted as the inline editor is opened and closed.  When the
--   editor is first opened on a track, the track height is adjusted up.  Once the editor
--   is closed on the track, the track is restored to its previous height.
--
--   The first time you use this script and open the inline editor, the track height is
--   adjusted to a sensible default.  You can then adjust the track height to your desired
--   size and when the editor is closed, that height will be remembered for the next
--   inline editor open.  That height is global and applies to all other tracks and
--   projects.
--
--   When you run this script, the item under the mouse cursor is always selected.  The
--   item's track is also selected if the inline editor is being opened.  This logic is
--   optimized for Reaticulate where the available articulations are based on the selected
--   track.
--
--   To set the CC lanes for the inline editor, I highly recommend the script called
--   "js_Select CC lanes to show in MIDI item under mouse.lua" which is part of the
--   ReaTeam Scrips ReaPack, automatically available to all ReaPack users.
--
--   Unfortunately, REAPER syncs the visible lanes between the full MIDI editor and the
--   inline editor, but the lane heights are distinct between them, so double clicking on
--   a lane in the inline editor will collapse it, while ensuring it remains visible in
--   the full editor.

local STATE_KEY = 'P_EXT:tack_toggle_inline_editor_previous_track_height'
local CFG_KEY = 'tack_toggle_inline_editor_track_height'

-- Close the inline editor for the given item.  If no other items on the given track have
-- the inline editor open, then restore the track height to the given height.
--
-- When this function returns, the items whose inline editor was just closed are selected.
local function close(track, item, restore_height)
    -- Ensure the item under the mouse is selected
    if item then
        -- Item: Unselect (clear selection of) all items
        reaper.Main_OnCommandEx(40289, 0, 0)
        reaper.SetMediaItemSelected(item, true)
    end

    -- Item: Close item inline editors
    reaper.Main_OnCommandEx(41887, 0, 0)
    -- Scan all items on this track and restore track height if no item on the track has
    -- the inline editor open
    for itemidx = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, itemidx)
        local take = reaper.GetActiveTake(item)
        if reaper.BR_IsMidiOpenInInlineEditor(take) then
            -- Inline editor is open, abort.
            return
        end
    end
    -- Remember the track's current height for next time
    local cur_height = reaper.GetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE')
    reaper.SetExtState('tack', CFG_KEY, cur_height, true)
    reaper.ShowConsoleMsg(string.format('RESTORE HEIGHT: %s\n', cur_height))

    if restore_height and restore_height ~= '' then
        -- Previous recorded height is valid, so use that
        reaper.SetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE', restore_height)
    else
        -- No valid height given, fall back to height preset A
        -- Xenakios/SWS: Set selected tracks heights to B
        reaper.Main_OnCommandEx(reaper.NamedCommandLookup('_XENAKIOS_SELTRAXHEIGHTA'), 0, 0)
    end
    -- Clear track state
    reaper.GetSetMediaTrackInfo_String(track, STATE_KEY, '', true)
    reaper.TrackList_AdjustWindows(true)
end

-- Closes the inline editor on all items on the track.
--
-- When this function returns, the item selection is cleared.
local function close_all_on_track(track)
    -- Item: Unselect (clear selection of) all items
    reaper.Main_OnCommandEx(40289, 0, 0)
    for itemidx = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, itemidx)
        local take = reaper.GetActiveTake(item)
        if reaper.BR_IsMidiOpenInInlineEditor(take) then
            reaper.SetMediaItemSelected(item, true)
        end
    end
    -- Item: Close item inline editors
    reaper.Main_OnCommandEx(41887, 0, 0)
    -- Item: Unselect (clear selection of) all items
    reaper.Main_OnCommandEx(40289, 0, 0)
end

-- Opens the inline editor for the given item.  If adjust_height is true,
-- then the track's current height is recorded in track state and the track's
-- height is set to the Xenakios preset for track height B.
--
-- When this function returns, the given track and item are both selected.
local function open_item(track, item, adjust_height)
    -- Ensure other inline editors on this track are closed before we open a new one (exclusive mode)
    close_all_on_track(track)
    reaper.SetOnlyTrackSelected(track)
    reaper.SetMediaItemSelected(item, true)
    if adjust_height then
        local cur_height = reaper.GetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE')
        reaper.GetSetMediaTrackInfo_String(track, STATE_KEY, cur_height, true)
        reaper.ShowConsoleMsg(string.format('WRITE HEIGHT: %s\n', cur_height))

        local target_height = tonumber(reaper.GetExtState('tack', CFG_KEY)) or 150
        reaper.SetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE', target_height)
        -- Xenakios/SWS: Set selected tracks heights to B
        -- reaper.Main_OnCommandEx(reaper.NamedCommandLookup('_XENAKIOS_SELTRAXHEIGHTB'), 0, 0)
        -- Get the new height.  Adjust it up to 100px if needed, since smaller editors
        -- aren't terribly useful.
        -- height = reaper.GetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE')
        -- if height < 100 then
        --     height = reaper.SetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE', 100)
        -- end
    end
    -- Item: Open item inline editors
    reaper.Main_OnCommandEx(40847, 0, 0)
    reaper.TrackList_AdjustWindows(true)
end

local function main()
    -- Get the first selected item now, in case we need to use it as a fallback later
    local selected_item = reaper.GetSelectedMediaItem(0, 0)
    -- Get the item under the cursor
    local mouse_item, _ = reaper.BR_ItemAtMouseCursor()
    local item = mouse_item or selected_item
    if not item then
        -- Nothing selected under item, and no item was previously selected. We're done.
        return
    end
    local take = reaper.GetActiveTake(item)
    local track = reaper.GetMediaItemTake_Track(take)
    local has_height, height = reaper.GetSetMediaTrackInfo_String(track, STATE_KEY, '', false)
    if reaper.BR_IsMidiOpenInInlineEditor(take) then
        -- Inline editor is open on either the item under the mouse or the selected item,
        -- so close it.
        reaper.ShowConsoleMsg(string.format('CLOSE EDITOR\n'))
        close(track, item, height)
    else
        -- No inline editor open on the item under the mouse, so open it.  Unlike close,
        -- for open we don't fall back to the selected item, instead requiring there to
        -- be an item under the cursor.
        reaper.ShowConsoleMsg(string.format('OPEN EDITOR\n'))
        open_item(track, item, not has_height)
    end
end

reaper.defer(function()
    reaper.PreventUIRefresh(1)
    main()
    reaper.PreventUIRefresh(-1)
end)