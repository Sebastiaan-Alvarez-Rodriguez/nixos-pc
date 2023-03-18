{githubUsername}: {
  "github.com" = {
    user = githubUsername;
    identityFile = "~/.ssh/github.rsa";
    identitiesOnly = true;
  };
  "cobra" = {
    hostname = "2a05:1500:702:3:1c00:54ff:fe00:143c";
    user = "sebastiaan";
    identityFile = "~/.ssh/cobra_sebastiaan.rsa";
    identitiesOnly = true;
  };
  "blackberry-local" = {
    hostname = "192.168.178.213";
    user = "rdn";
    port = 18357;
    identityFile = "~/.ssh/blackberry.rsa";
    identitiesOnly = true;
  };
  "blackberry" = {
    hostname = "home.alvarez-rodriguez.nl";
    user = "rdn";
    port = 18357;
    identityFile = "~/.ssh/blackberry.rsa";
    identitiesOnly = true;
  };
}