# Tack's miscellaneous scripts for [REAPER](http://reaper.fm/)

## Installation

1. Install [ReaPack](http://reapack.com/)
2. In Reaper, select Extensions / ReaPack / Manage Repositories from the menu, click the Import
   button, click the Import button at the bottom of the window that pops up, and paste
   `https://raw.githubusercontent.com/jtackaberry/reascripts/master/index.xml`
3. Double click "Tack Scripts" and in the popup, click the "Install/update Tack Scripts" button and
   select "Install All"

Alternatively, you can always download the scripts directly from this repository.


## Usage

### MIDI CC Sync

**WARNING:** this script has been deprecated in favor of
[Reaticulate](https://reaticulate.com) which, apart from managing articulations, also
implements bidirectional CC syncing in a much more user-friendly way than this older CC
sync script.

<details>
<summary>Expand usage details</summary>
This script (and its companion JSFX) allows syncing CC values to a control surface when a track is
selected.

[![YouTube video](https://i.ytimg.com/vi/ZO6eQt6L1KI/hqdefault.jpg)](https://www.youtube.com/watch?v=ZO6eQt6L1KI)

It works by installing a "CC Sync" JSFX onto each track whose CCs you want to sync, and running the
Lua script "Sync MIDI CCs on Track Select" which will stay running in the background.  This script
needs to be run on startup, which you can do using SWS's "Set global startup action" function.
Then, when you select a track that is monitoring for MIDI, it will set that track to (exclusively)
output to a MIDI output device of your choice (i.e. your control surface).  The CC Sync JSFX
coordinates with the background Lua script so that when a track is selected, it outputs all CC
values on all channels that it's observed, which ultimately get sent to the MIDI hardware output
that was automatically added to the track.


Usage:

1. In Preferences / Audio / MIDI Devices, choose which output should receive the CCs and enable it
   for output.
2. Update the alias of this MIDI device to include the exact suffix "Track Output" which is a signal
   to the background Lua script to add this device as a MIDI hardware output on the selected track.
3. On each MIDI track whose CCs you want to sync, add the "CC Sync" FX at the top of the FX chain.


The MIDI bus option in the FX controls which MIDI bus the CC sync events will be emitted on.  With
MIDI bus 0, the CC events sent to the control surface are standard CCs on the MIDI channel they were
observed.

With this configuration, you must ensure the events leaving the CC Sync FX make it through to the
bottom of the FX chain.  The easiest way to do this is to have Reaper merge MIDI output for each
subsequent FX with the MIDI output bus.  (In the FX window, right click on the I/O routing button
and select MIDI Output / Merges with MIDI bus from the menu.)

A *much* more flexible approach is to have the CC Sync JSFX send events on a different, dedicated
MIDI bus.  This side-steps the output issue above, but it means that you can't output directly
to a control surface, because the MIDI events that are sent to the hardware output look like this:

```
F0 FF 52 50 62 0F B0 01 30 F7
```

Above, 0F is the MIDI bus (0x0F is 15, which is bus 16 as counts start at 0), and B0 01 30 is the
normal CC event that would have been sent if the MIDI bus were set to 1 (value 0).

One way to handle this is to use software like Bome's [MIDI Translator
Pro](https://www.bome.com/products/miditranslator/) to act as a gateway between Reaper and the
control surface, translating the SysEx events in the above format from Reaper to a standard CC event
that's output to the control surface.  Doing this allows other tricks, as BMT can make decisions
about which events to translate and forward, which can be used, for example, to change the MIDI
channel context of the control surface.


One last feature of the CC Sync script is that if it receives a MIDI note-off event on channel 16
for note 127 with release velocity 0x42 (decimal 66), it will output all current CC values as if the
track had just been selected.  One use-case for this function is when switching the control surface
to a different MIDI channel (whether natively or through translation software like BMT), sending
this note-off event will cause the control surface to resync to the values on the new MIDI channel.
</details>