# Syncthing

Quick lessons learnt.

## Removing data on the host server
Removing any folder with content probably becomes an error on the host.
The web-GUI will tell, and `journalctl -xeu syncthing` as well.
If the clients still have the data, just remove the missing folders from the `data-dir`, and delete them in the web ui.

Then, simply
```bash
sudo systemctl restart syncthing-init syncthing
```

And all is fine again.
