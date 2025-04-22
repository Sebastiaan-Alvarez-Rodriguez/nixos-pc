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


### Configure movie/music *arr service

#### Movies
1. Setup username/password.
2. Go to `Settings > Media management`.
  1. Unhide the advanced settings (cog icon left top).
  2. Allow `rename movies`.
  3. Set `colon replacement` to `replace with space dash space`.
  4. Use standard movie format:
  ```
  {Movie CleanTitle} {(Release Year)} [tmdbid-{TmdbId}] - {Edition Tags }{[Custom Formats]}{[Quality Full]}{[MediaInfo 3D]}{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[Mediainfo VideoCodec]}{-Release Group}
  ```
  5. Use movie folder format:
  ```
  {Movie CleanTitle} ({Release Year}) [tmdbid-{TmdbId}]
  ```
  6. Set `Use Hardlinks instead of Copy`.
  7. Set `import extra files`.
  8. Set `import extra files` (entry below 8) to `srt`.
  9. Set `unmonitor deleted movies`.
  10. All the way down, add `/data/media/movies` as a root folder.

#### Music
1. Setup username/password.
2. Go to `Settings > Media management`.
  1. Unhide the advanced settings (cog icon left top).
  2. Set `Use Hardlinks instead of Copy`.
  3. All the way at the top, add `/data/media/music` as a root folder.


### Prowlarr
1. Setup username/password
2. go to `Settings > Download Clients` (and click `show advanced` to see all options)
  1. Select `Transmission`
  2. Keep host as-is (`localhost`) and set the port. Don't use SSL for localhost.
  3. Enter transmission username/password.
  4. Hit `test`. A green check should appear quickly (seconds). Then hit `save`.
3. go to `Settings > General`
  1. Disable `Send Anonymous Usage Data`
  2. Ensure the `Backups > Folder` field reads `Backups`.
  3. Set `Backups > Retention` to the same value as the interval, so only 1 backup exists at any time.
4. go to `Indexers`
  1. Click `Add Indexer`, pick any supported indexer, and provide requested information. Hit `test` first and wait for the green check. Then hit `save`.
5. go to `Settings > Apps`
  1. Add an app, e.g. `Lidarr` for music.
  2. Fix the server url if needed.
  3. Add the API key from `Lidarr`, as found in `Settings > General`


### Configure Jellyfin
1. Setup username/password.
2. Go to `Dashboard > libraries > add media library`.
3. Click the round `+` button right of the `Folders` section, and add the movies folder `/data/media/movies`.
4. Set preferred download language = English.


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
