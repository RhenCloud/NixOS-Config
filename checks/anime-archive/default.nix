{ python3, runCommand, ... }:
runCommand "anime-archive-test" { nativeBuildInputs = [ python3 ]; } ''
  python3 ${./test_archiver.py} ${../../modules/server/anime-archive/archiver.py} > $out
''
