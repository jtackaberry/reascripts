-- @noindex
-- Setup package path to allow importing other scripts
sep = package.config:sub(1, 1)
script = debug.getinfo(1, 'S').source:sub(2, -5)
package.path = package.path .. ";" .. script:match("(.*" .. sep .. ")") .. ".." .. sep .. "?.lua"
require "MIDI.tack_Functions"

_, _, _, _, _, _, val = reaper.get_action_context()
inject_program_change(3, 32, 0, val)
