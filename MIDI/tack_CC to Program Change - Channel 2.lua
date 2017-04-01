--[[
 * ReaScript Name: CC to Program Change - Channel 2
 * Description: Converts CC value (based on action binding) to Program Change (bank 32) on channel 2.
                If MIDI editor is open and step input enabled, will insert Program Change event at cursor.
                Best used for articulation switching.
 * Author: Jason Tackaberry (tack)
 * Licence: Public Domain
 * Extensions: None
 * Version: 1.0
--]]

-- Setup package path to allow importing other scripts
sep = package.config:sub(1, 1)
script = debug.getinfo(1, 'S').source:sub(2, -5)
package.path = package.path .. ";" .. script:match("(.*" .. sep .. ")") .. ".." .. sep .. "?.lua"
require "MIDI.tack_Functions"

_, _, _, _, _, _, val = reaper.get_action_context()
inject_program_change(2, 32, 0, val)
