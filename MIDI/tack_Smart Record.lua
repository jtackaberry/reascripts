-- @description Smart Record
-- @about
--    Starts recording, unless already recording, in which case the take is discarded and
--    record starts over.
-- @author Jason Tackaberry (tack)
-- @version 1.0


-- If the MIDI editor is open and step input is enabled, first disable it
-- to avoid double-recording every event.
--
-- Magic value 32060 is the MIDI editor context
local step_input = reaper.GetToggleCommandStateEx(32060, 40481)
if step_input == 1 then
    window = reaper.MIDIEditor_GetActive()
    reaper.MIDIEditor_OnCommand(window, 40481)
end

-- If we're already recording, stop and undo (to discard the take) before
-- starting record again.

-- Transport: Record
local recording = reaper.GetToggleCommandStateEx(0, 1013)
if recording == 1 then
    -- Transport: Stop
    reaper.Main_OnCommandEx(1016, 0, 0)
    -- Edit: Undo
    reaper.Main_OnCommandEx(40029, 0, 0)
end
-- Transport: Record
reaper.Main_OnCommandEx(1013, 0, 0)
