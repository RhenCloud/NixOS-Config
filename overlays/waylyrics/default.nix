{ }: _final: prev: {
  waylyrics = prev.waylyrics.overrideAttrs (old: {
    version = "0.4.0";
    src = prev.fetchFromGitHub {
      owner = "waylyrics";
      repo = "waylyrics";
      rev = "v0.4.0";
      hash = "sha256:08b2ciwdzn939vi6lyhgl80y1n04d6fgs9p219zdj18rwlkmwb1j";
    };
    cargoHash = "sha256-FaTm6pqDEdvHcJ5AJxZcDDYUzZovLzM++8JPC/QtfX0=";
  });
}
