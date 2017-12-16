--[[
 * ReaScript Name: MIDI Functions
 * Description: Various MIDI functions for other MIDI scripts. Not to be invoked directly.
 * Author: Jason Tackaberry (tack)
 * Licence: Public Domain
 * Extensions: None
 * Version: 1.1
 * Provides: [nomain] .
--]]

-- Stuffs the given program change message and inserts it into the current MIDI editor
-- (if one is open) if step input is enabled, either replacing any selected program change
-- events, or inserting a new one at the cursor.
function inject_program_change(source_channel, msb, lsb, program)
    if program > 0 then
        local channel = math.max(0, source_channel - 1)
        local hwnd = reaper.MIDIEditor_GetActive()
        if hwnd then
            -- If the MIDI editor is open, use its current note channel for the Program Change event
            -- if the input source channel is -1.
            if source_channel == 0 then
                channel = reaper.MIDIEditor_GetSetting_int(hwnd, "default_note_chan")
            end
            -- Magic value 32060 is the MIDI editor context
            local step_input = reaper.GetToggleCommandStateEx(32060, 40481)
            if step_input == 1 then
                -- Step recording is enabled in the editor, so inject the PC event at
                -- the current cursor position.
                reaper.PreventUIRefresh(1)
                reaper.Undo_BeginBlock2(0)
                local take = reaper.MIDIEditor_GetTake(hwnd)
                -- Replace any existing selected events (if those events are program changes)
                -- otherwise insert a new event at the cursor position.
                if not replace_selected_events_with_program_change(take, channel, msb, lsb, program) then
                    local cursor = reaper.GetCursorPosition()
                    local ppq = reaper.MIDI_GetPPQPosFromProjTime(take, cursor)
                    insert_program_change(take, false, ppq, channel, msb, lsb, program)
                end
                reaper.Undo_EndBlock2(0, "MIDI editor: insert program change (" .. program .. ")", -1)
                reaper.PreventUIRefresh(-1)
            end
        end
        reaper.StuffMIDIMessage(0, 0xb0 + channel, 0, msb)
        reaper.StuffMIDIMessage(0, 0xb0 + channel, 0x20, lsb)
        reaper.StuffMIDIMessage(0, 0xc0 + channel, program, 0)
    end
end


-- Inserts a Program Change event in the given Take.
function insert_program_change(take, selected, ppq, channel, bank_msb, bank_lsb, program)
    reaper.MIDI_InsertCC(take, selected, false, ppq, 0xb0, channel, 0, bank_msb)
    reaper.MIDI_InsertCC(take, selected, false, ppq, 0xb0, channel, 32, bank_lsb)
    reaper.MIDI_InsertCC(take, selected, false, ppq, 0xc0, channel, program, 0)
    local item = reaper.GetMediaItemTake_Item(take)
    reaper.UpdateItemInProject(item)
end

-- Replaces all selected events in the given Take with a Program Change event
function replace_selected_events_with_program_change(take, channel, bank_msb, bank_lsb, val)
    local evtidx = reaper.MIDI_EnumSelEvts(take, 0)
    local replace = {}
    while evtidx > -1 do
        local rv, selected, muted, ppq, msg = reaper.MIDI_GetEvt(take, evtidx, true, true, 1, "")
        local command = string.byte(msg, 1) & 0xf0
        local value = string.byte(msg, 2)
        -- Replace either CC 0 (command == 176) and value 0/32, which is a bank select, or
        -- a program change (command == 192).
        if (command == 0xb0 and (value == 0 or value == 0x20)) or command == 0xc0 then
            replace[#replace+1] = {evtidx, ppq}
        end
        evtidx = reaper.MIDI_EnumSelEvts(take, evtidx + 1)
    end
    if #replace > 0 then
        for _, events in ipairs(replace) do
            local evtidx, ppq = table.unpack(events)
            reaper.MIDI_DeleteEvt(take, evtidx)
            insert_program_change(take, true, ppq, channel, bank_msb, bank_lsb, val)
        end
        return true
    else
        return false
    end
    return #replace > 0
end
