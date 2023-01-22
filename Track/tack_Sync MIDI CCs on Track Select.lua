-- @noindex

HARDWARE_TARGET_SUBSTRING = "Track Output"

-- The last track that had the MIDI hw output enabled
last_track = nil

function sync(track, fx)
    -- Get current automation mode of the track and reset to trim before we
    -- mess around with parameters.
    local global_automode = reaper.GetGlobalAutomationOverride()
    local track_automode  = reaper.GetMediaTrackInfo_Value(track, "I_AUTOMODE")
    local ltrack_automode = nil

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    -- Remember last touched FX (see below) and clear automation modes.
    local lr, ltrack, lfx, lparam = reaper.GetLastTouchedFX()
    if lr then
        ltrack = reaper.GetTrack(0, ltrack - 1)
        ltrack_automode  = reaper.GetMediaTrackInfo_Value(ltrack, "I_AUTOMODE")
        reaper.SetMediaTrackInfo_Value(ltrack, "I_AUTOMODE", 0)
    else
        ltrack = nil
    end

    reaper.SetMediaTrackInfo_Value(track, "I_AUTOMODE", 0)
    reaper.SetGlobalAutomationOverride(0)
    -- Update the serial parameter on the CC Sync JSFX to force a
    -- CC sync.
    local r, _, _ = reaper.TrackFX_GetParam(track, fx, 1)
    reaper.TrackFX_SetParam(track, fx, 1, 1 - r)

    if ltrack then
        -- By setting the JSFX parameter above, we just replaced the last touched
        -- FX.  There doesn't seem to be any way to restore it other than to rewrite
        -- the current value back to the last touched FX.
        local r, _, _ = reaper.TrackFX_GetParam(ltrack, lfx, lparam)
        reaper.TrackFX_SetParam(ltrack, lfx, lparam, r)
    end
    -- Due to what must be a bug in Reaper, we need to restore the track automation modes
    -- _after_ ending the undo block, otherwise the parameters adjusted above end up
    -- getting automatically armed.
    reaper.Undo_EndBlock("Sync track CCs to MIDI out", 2)

    -- For some reason, restoring track automation modes doesn't end up cluttering
    -- undo history even though we are outside of an undo block (probably another
    -- Reaper bug?).
    reaper.SetMediaTrackInfo_Value(track, "I_AUTOMODE", track_automode)
    if ltrack then
        reaper.SetMediaTrackInfo_Value(ltrack, "I_AUTOMODE", ltrack_automode)
    end
    reaper.SetGlobalAutomationOverride(global_automode)
    reaper.PreventUIRefresh(0)
end


function clear_midi_output_all_tracks()
    for idx = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, idx)
        local fx = reaper.TrackFX_GetByName(track, "MIDI CC Tracker", false)
        if fx >= 0 then
            reaper.SetMediaTrackInfo_Value(track, "I_MIDIHWOUT", -1)
        end
    end
end

function set_track_midi_ouptut(track, enabled, fx)
    local input = reaper.GetMediaTrackInfo_Value(track, "I_RECINPUT")
    if input <= 0 and input & 4096 == 0 then
        return
    end
    if enabled == false then
        reaper.SetMediaTrackInfo_Value(track, "I_MIDIHWOUT", -1)
    else
        local fx = reaper.TrackFX_GetByName(track, "CC Sync", false)
        -- Only enable if new track has the CC tracker JSFX
        if fx >= 0 then
            -- Find the MIDI output number based on a substring search of the name.
            target = -1
            for output = 0, reaper.GetNumMIDIOutputs() - 1 do
                retval, name = reaper.GetMIDIOutputName(output, "")
                if retval and name:find(HARDWARE_TARGET_SUBSTRING) then
                    target = output
                end
            end
            if target > 0 then
                reaper.SetMediaTrackInfo_Value(track, "I_MIDIHWOUT", target << 5)
                function go()
                    sync(track, fx)
                end
                reaper.defer(go)
            else
            end
            return true
        end
    end
    return false
end

function main()
    local last_touched = reaper.GetLastTouchedTrack()
    if last_touched then
        if reaper.IsTrackSelected(last_touched) and last_touched ~= last_track then
            if last_track then
                set_track_midi_ouptut(last_track, false)
                last_track = nil
            end
            if set_track_midi_ouptut(last_touched, true) then
                last_track = last_touched
            end
        end
    end
    reaper.defer(main)
end

clear_midi_output_all_tracks()
main()
