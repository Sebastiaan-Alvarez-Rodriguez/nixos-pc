# VPN
Setup possible:
- `headscale`: VPN control plane
- `headplane`: web-ui for `headscale`, found at `<address>/admin`
- `tailscale-server`: tailscale client for servers - will request `exit-node` functionality
- `tailscale-client`: TODO implement - tailscale client for nixos clients.
- other clients: Install the official tailscale client/app.

## Config
Enable headscale (with webui headplane), and tailscale server on the server:
```nix
{
  headscale = {
    enable = true;
    webui = {
      enable = true;
      cookie-secret-file = config.age.secrets."helium/headscale/cookie".path;
      apikey-file = config.age.secrets."helium/headscale/apikey".path;
    };
  };
  tailscale-server = {
    enable = true;
    auth-file = config.age.secrets."helium/tailscale/helium".path;
  };
}
```

### cookie secret file
Just generate secure random 32-char string, store as a nixos secret (see the [secrets readme](./secrets.md)).

### headscale api key
The `headscale.webui.apikey-file` can be generated using:
```bash
sudo headscale apikeys create --expiration 100y
```
This expiration is recommended, to ensure nixos can rebuild this part of the config without resorting to errors due to expired tokens.
- Store this key as a nixos secret (see the [secrets readme](./secrets.md)).
- Store this apikey ALSO in your favorite password manager. Headplane will ask for it to authenticate.

### tailscale auth key
The `tailscale-server.auth-file` can be generated using:
```bash
sudo headscale preauthkeys create --reusable --expiration 100y --tags tag:exit
```
(or use headplane > machines > add device > generate pre-auth key)
This:
- generates a preauthkey that the tailscaled.service will use to authenticate to headscale
- key has a tag tag:exit, to make this a 'tagged node/machine' rather than a user-owned node/machine.
- we do not use '--user <id>' to make this key (and the tailscale server logging in with it) a tag-owned device, rather than a user-owned device.
- This expiration bit ensures the key will stay reusable, useful for when rebuilding nixos from scratch someday in the future.

## Client Setup
A client device is called a `node` or `machine`.
There are 2 sorts of `nodes`:
- `nodes` that belong to a user.
  Phones, laptops, other end-user devices belong here.
- `nodes` that have tags and do not belong to a user.
  Server devices belong here.

### add a user
Create a user with `sudo headscale users create <name>`
(or use headplane > users > add user)

### add a client device
1. install the app/client service for the device
2. There are 3 possibilities:
    1. generate machine key on client, use `headscale` server commandline.
       1. set an alternative auth server > set to [https://vpn.h.mijn.place](https://vpn.h.mijn.place) (a browser window will open)
          > note: on android 'get started' (browser window to default tailscale control plane opens) > go back to app. Then settings > accounts > three '...' > user an alternative server
       2. `headscale` webpage will tell you to execute `sudo headscale nodes register --key <key> --user <user>` (key is a temporary secret)
       3. Execute above command on the server. Fill in the `<username>` you created before.
    2. generate machine key on client, use `headplane` webui.
       1. set an alternative auth server > set to [https://vpn.h.mijn.place](https://vpn.h.mijn.place) (a browser window will open)
       2. `headscale` webpage will tell you to execute `sudo headscale nodes register --key <key> --user <user>` (key is a temporary secret)
       3. Copy the temporary key
       4. go to [vpnc.h.mijn.place/admin](vpnc.h.mijn.place/admin) > machines > add device > register machine key
       5. paste the temporary key (yes, even though it does not start with `hskey-authreq-`, it is fine)
       6. Pick the user that will own the machine and confirm
       7. The device is now registered - without needing commandline access to the `headscale` server.
    3. generate preauth key on `headplane`, use it for tailscale client:
       1. should be possible, don't know how to use preauth key at android-like clients yet.

#### Rename client device
You can rename the client, e.g. if it is automatically named 'invalid-abcdefgh'.
1. go to `headplane` > machines at [vpnc.h.mijn.place/admin](vpnc.h.mijn.place/admin)
2. find the device in the list > three `...` > edit machine name
