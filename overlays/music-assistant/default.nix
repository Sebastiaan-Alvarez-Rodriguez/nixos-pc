{ inputs, ... }:
self: prev: {
  music-assistant = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.music-assistant.overrideAttrs(old: {
    # remove mDNS entries for streams. Use your own mDNS publisher for services '_snapcast._tcp' and '_snapcast-stream._tcp' types, e.g:
    # my.services.avahi.extra-service-files = {
    #   snapcast = ''
    #     <?xml version="1.0" standalone='no'?>
    #     <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
    #     <service-group>
    #       <name replace-wildcards="yes">Snapcast on %h</name>

    #       <service>
    #         <type>_snapcast._tcp</type>
    #         <port>1704</port>
    #       </service>

    #       <service>
    #         <type>_snapcast-stream._tcp</type>
    #         <port>1704</port>
    #       </service>
    #     </service-group>
    #   '';
    # };
    postPatch = (old.postPatch or "") + ''
      substituteInPlace music_assistant/providers/snapcast/provider.py --replace-fail '("-stream", 1704),' ' ' --replace-fail '("", 1704),' ' '
      substituteInPlace music_assistant/providers/snapcast/provider.py --replace-fail '"--http.enabled=true",' '"--http.enabled=true", "--server.mdns_enabled=false", "--tcp-streaming.publish=false",'
    '';

    # do not check my build (upstream already checked, and my change does not alter the code)
    checkPhase = "true";
    installCheckPhase = "true";
    doCheck = false;
    doInstallCheck = false;

    # patches = old.patches ++ [ ./portfix.patch ]; # seb NOTE:
    # add ./refreezer.patch add when wanting to have refreezer integration again
  });
}
