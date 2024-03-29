-- @description Sync MIDI CCs on Track Select
-- @author Jason Tackaberry (tack)
-- @version 1.0
-- @metapackage
-- @provides
--     [main] tack_Sync MIDI CCs on Track Select.lua
--     [jsfx] ../JSFX/tack_MIDI CC Sync.jsfx
-- @about
--     *DEPRECATED*: These scripts are obsolete and deprecated in favor of Reaticulate
--     which, apart from providing a solution for articulation management, includes more
--     robust and user-friendly support for syncing CCs to a control surface. which is a
--     much more capable solution for articulation management.
--
--     Original usage instructions follow.
--
--     1. In Preferences / Audio / MIDI Devices, choose which MIDI
--     output should receive the CCs and enable it for output, and
--     also update the device's name to be suffixed with "Track
--     Output".  For example: "Bome MIDI Translator 1 - Track
--     Output".  The "Track Output" string is used by the script
--     to identify the MIDI output device.
--
--     2. Install the companion "MIDI CC Tracker" JSFX on each track
--     whose last-seen CCs should be synced upon track select.  If
--     Bus 0 is used (default), all MIDI-consuming VSTs must be
--     configured to output MIDI CCs, or Reaper configured to
--     merge the VST's output with the MIDI bus, otherwise the
--     MIDI hardware send won't receive the MIDI CCs.  Or, a
--     non-zero MIDI bus can be used, but then the receiving
--     MIDI output device will need to support SysEx messages
--     like F0 FF 52 50 62 0F B0 01 30 F7, where 0F is the
--     MIDI bus (15), and B0 01 30 is the CC (channel 1, CC 1,
--     value 30 in this example).  For example, BOME MIDI
--     Translator could be used to process these events and pass
--     them along to a control surface.  (This is what I do.)
--
--     It is also possible to trigger a flush of last-seen CCs by
--     sending to the JSFX a note off MIDI message for key 127 with
--     release velocity 0x42 (8f 7f 42).  Use-case: switching MIDI
--     channels from a control surface to trigger an update of the
--     faders.