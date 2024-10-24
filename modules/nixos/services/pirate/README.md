# The *arr stack
A media streaming setup for these demands:
1. Plays media with a nice UI
2. (optional) Downloads media with the same UI
3. Downloads whatever
4. Properly tags and places media
5. Self-hosted
6. (as-much-as-possible) open source

Do note this setup downloads movies.

## Downloading media
Prowlarr is a media download manager for lidarr, radarr, sonarr, whisparr.
Prowlarr is an indexer to download media from torrent sites, nzb sites etc.
These other *arr applications are media management tools: They download metadata for media, tag the media.

## Using downloaded media
Called 'streaming'. This requires media server software.
Examples: Plex/plexamp, emby, Navidrome, Jellyfin...

Currently jellyfin is supported for video and audio.

Note: FinAmp has a download-for-offline functionality.


## Configuration
After installing with nixOS...

### Configure Jellyfin
1. Setup username/password.
2. Go to the dashboard > libraries > add media library.
3. Click the round `+` button right of the `Folders` section, and add the movies folder `/data/media/movies`.
4. Set preferred download language = English.


### Configure movie/music *arr service

#### Movies
1. Setup username/password.
2. Go to settings > media management.
3. Unhide the advanced settings (cog icon left top).
4. Allow `rename movies`.
5. Set `colon replacement` to `replace with space dash space`.
5. Use standard movie format:
```
{Movie CleanTitle} {(Release Year)} [tmdbid-{TmdbId}] - {Edition Tags }{[Custom Formats]}{[Quality Full]}{[MediaInfo 3D]}{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[Mediainfo VideoCodec]}{-Release Group}`
```
6. Use movie folder format:
```
{Movie CleanTitle} ({Release Year}) [tmdbid-{TmdbId}]
```
7. Set `Use Hardlinks instead of Copy`.
8. Set `import extra files`.
9. Set `import extra files` (entry below 8) to `srt`.
10. Set `unmonitor deleted movies`.
11. All the way down, add `/data/media/movies` as a root folder.


### Configure prowlarr
Add 2 indexers.

## WIP
### Prowlarr - cloudflare circumvention
Some torrent sites are behind cloudflare...
Use flaresolverr: https://trash-guides.info/Prowlarr/prowlarr-setup-flaresolverr/
Install flaresolverr on nixos: https://github.com/NixOS/nixpkgs/issues/294789


### v2a:
stremio
- streaming without downloading
- only works well woth debrid service?
- open source?
- can it download for offline watching / listening?

Stremio vs downloadings:
https://www.reddit.com/r/selfhosted/comments/10x6gog/comment/j7r3vl9/

### v2 b:
advanced arr stack: https://www.reddit.com/r/PleX/comments/1arzr1y/the_ultimate_plex_software_stack_arrs_and_more/

## Sources
1. guide navidrome audio: https://noted.lol/the-perfect-self-hosted-music-server/
2. guide jellyfin video/music: https://www.fuzzygrim.com/posts/media-server
3. guide config *arr services with jellyfin: https://trash-guides.info/ (especially look at the how-to-setup-for > Native)
2. Prowlarr's place: https://www.reddit.com/r/prowlarr/comments/x2lfz6/i_must_be_dumb_how_is_prowlarr_used_in/
3. discussion about streaming server software: https://www.reddit.com/r/Lidarr/comments/q5bhhl/what_clients_do_you_use_to_actually_listen_to/
4. discussion about open-source streaming: https://www.reddit.com/r/selfhosted/comments/6dk6xa/open_source_plex_alternatives_other_than_emby/
5. a guy's nixos config: https://github.com/ambroisie/nix-config/
6. plex is not true selfhosted: https://www.reddit.com/r/selfhosted/comments/p5jkzt/is_it_possible_to_fully_self_host_plex/
