# Music for Sunrise Suite (made with Suno)

The game looks for music files in `assets/audio/music/`. If a track is missing, the game just stays quiet there, so you can add tracks one at a time.

## How to make a track
1. In Suno, choose **Custom** mode and turn **Instrumental** on. Leave the lyrics empty.
2. Paste the **Style** text from the table below. If your Suno version has an **Exclude styles** field, paste the exclude text there.
3. Generate a few versions and pick the one that sounds most like a calm sunrise.
4. Download it as **MP3** (or WAV on a paid plan).
5. Rename it to the **exact file name** in the table and put it in `assets/audio/music/`. `.mp3`, `.ogg` and `.wav` all work.
6. Commit and push (or tell Claude "I added music"). The auto-build picks it up.

Tips:
- Suno songs often have a big intro and an ending. The game crossfades the end of a track back into its start, so it doesn't need to loop perfectly. A version without a hard ending sounds best.
- Suno masters are loud. The game's Music volume starts lower than the sound effects, and players can change it in Settings.
- For the short **stinger**, generate normally, then trim the best 5–8 seconds (the Suno editor or Audacity both work).

## Tracks

| File name | Where it plays | Style (paste into Suno) | Exclude |
|---|---|---|---|
| `menu_theme` | Title screen | cozy lo-fi acoustic, soft felt piano, warm nylon guitar, gentle ocean waves in the background, sunrise mood, calm and hopeful, warm tape saturation, 72 bpm, instrumental | vocals, heavy drums, electric guitar |
| `hub_penthouse` | Grandma's penthouse / decorating | breezy bossa nova lounge, nylon guitar, vibraphone, soft brushed drums, upright bass, beachside penthouse morning, relaxed and cheerful, 90 bpm, instrumental | vocals, synth lead, distortion |
| `level_lounge` | Sunrise Lounge levels | minimal ambient, soft Rhodes electric piano, warm pads, distant ocean, curious and gentle, sparse background music for puzzle solving, 70 bpm, instrumental | vocals, drums, bass drops |
| `level_kitchen` | Kitchen & Bar levels | gentle playful jazz trio, muted piano, pizzicato strings, light brushes, morning coffee vibe, curious and low energy, 80 bpm, instrumental | vocals, loud drums, brass |
| `level_study` | Grandma's Study levels | calm contemplative ambient, music box and celesta, soft cello, warm analog pads, nostalgic travel memories, gentle mystery, 65 bpm, instrumental | vocals, drums, dark horror |
| `daily_sunrise` | Daily Sunrise challenge | uplifting ambient, shimmering guitar harmonics, soft marimba, warm synth pads, golden hour sunrise over the sea, hopeful, 76 bpm, instrumental | vocals, heavy drums, EDM |
| `sunrise_stinger` | Plays once when the balcony door opens (trim to 5–8 s) | short gentle triumphant swell, warm strings, harp glissando, glockenspiel sparkle, sunrise reveal, cinematic but soft, instrumental | vocals, drums, epic trailer |
| `ambience_ocean` *(optional)* | Quiet layer under every level | ambient soundscape, gentle ocean waves on a beach at dawn, soft wind, distant seagulls, no melody, no music | vocals, instruments, drums, melody |

If Suno keeps adding music to `ambience_ocean`, a CC0 ocean recording from freesound.org works too. Add its link and license to `CREDITS.md`.

## Licensing
On Suno's **free plan**, songs are for **non-commercial use only**. If you might ever sell or monetize the game, make the tracks while subscribed to **Pro or Premier**, which give you commercial rights to songs made during the subscription. Check Suno's current terms before release.
