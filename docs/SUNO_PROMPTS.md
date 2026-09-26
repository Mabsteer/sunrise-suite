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
- The rooms follow Céline's life backwards (docs/STORY.md): the kitchen is her last years, the front garden her childhood. A little more "old-fashioned" the further you go is a nice touch.

## Tracks

| File name | Where it plays | Style (paste into Suno) | Exclude |
|---|---|---|---|
| `menu_theme` | Title screen | cozy lo-fi acoustic, soft felt piano, warm nylon guitar, gentle ocean waves in the background, sunrise mood, calm and hopeful, warm tape saturation, 72 bpm, instrumental | vocals, heavy drums, electric guitar |
| `hub_penthouse` | The sunroom (decorating) and the scrapbook | breezy bossa nova, nylon guitar, vibraphone, soft brushed drums, upright bass, seaside house on a sunny morning, relaxed and cheerful, 90 bpm, instrumental | vocals, synth lead, distortion |
| `level_kitchen` | The kitchen (Mamie's last years) | gentle playful jazz trio, muted piano, pizzicato strings, light brushes, morning coffee before dawn, tender and a little bittersweet, 78 bpm, instrumental | vocals, loud drums, brass |
| `level_hall` | The hall (the summers with Juliette) | warm summer ambient, ukulele and soft glockenspiel, gentle hand percussion, childhood beach holidays, nostalgic and playful, 84 bpm, instrumental | vocals, electric guitar, EDM |
| `level_bedroom` | The bedroom (Henri) | slow waltz on a music box and soft piano, warm strings, 1990s lamplight, tender love, calm, 3/4 time, 66 bpm, instrumental | vocals, drums, dark |
| `level_lounge` | The living room (Margot, the family years) | minimal ambient, soft Rhodes electric piano, warm pads, 1970s Sunday morning records, gentle and curious, 70 bpm, instrumental | vocals, drums, bass drops |
| `level_garden` | The garden (the first years, the wedding) | light pastoral folk, acoustic guitar, flute, birdsong, 1960s garden wedding at dawn, joyful and soft, 82 bpm, instrumental | vocals, heavy drums, synth |
| `level_shed` | The shed (the girl at the flower stall) | vintage French café accordion and upright bass, soft brushes, 1950s flower market, charming and shy, 88 bpm, instrumental | vocals, electric guitar, loud drums |
| `level_front_garden` | The front garden (her childhood, the ending) | simple innocent piano melody growing into warm strings and harp, children's morning by the sea, sunrise, hopeful and moving, 72 bpm, instrumental | vocals, drums, epic trailer |
| `daily_sunrise` | Daily Sunrise challenge | uplifting ambient, shimmering guitar harmonics, soft marimba, warm synth pads, golden hour sunrise over the sea, hopeful, 76 bpm, instrumental | vocals, heavy drums, EDM |
| `sunrise_stinger` | Plays once when a room's door opens (trim to 5–8 s) | short gentle triumphant swell, warm strings, harp glissando, glockenspiel sparkle, sunrise reveal, cinematic but soft, instrumental | vocals, drums, epic trailer |
| `ambience_ocean` *(optional)* | Quiet layer under every level | ambient soundscape, gentle ocean waves on a beach at dawn, soft wind, distant seagulls, no melody, no music | vocals, instruments, drums, melody |

If Suno keeps adding music to `ambience_ocean`, a CC0 ocean recording from freesound.org works too. Add its link and license to `CREDITS.md`.

## Licensing
On Suno's **free plan**, songs are for **non-commercial use only**. If you might ever sell or monetize the game, make the tracks while subscribed to **Pro or Premier**, which give you commercial rights to songs made during the subscription. Check Suno's current terms before release.
