{ pkgs ? import ./nix }:

let
  siteBuilder = pkgs.haskellPackages.callPackage ./builder { inherit (pkgs) lib; };
  sourceByRegex = name: src: regexes:
    builtins.path
      { filter =  (path: type:
          let
            relPath = pkgs.lib.removePrefix (toString src + "/") (toString path);
            accept = pkgs.lib.any (re: builtins.match re relPath != null) regexes;
          in pkgs.lib.traceSeq [ accept relPath ] accept);
          inherit name;
          path = src;
      };
in
  pkgs.stdenv.mkDerivation rec {
    name = "nmattia-com-builder";

    src = sourceByRegex "nmattia-com" ./.
        [ "^.*.pdf$"
          "^images$"
          "^images/.*$"
          "^templates$"
          "^templates/.*$"
          "^material$"
          "^material/.*$"
          "^css$"
          "^css/default.css$"
          "^css/font-awesome.min.css$"
          "^posts$"
          "^posts/.*$"
          "^[^R].*.md$" # allow all markdown files except README
        ];

    buildPhase = ''
      export LC_ALL=en_US.UTF-8
      export LANG=en_US.UTF-8
      export LANGUAGE=en_US.UTF-8
      cp ${pkgs.resume}/resume.pdf resume.pdf
      cp ${pkgs.resume}/resume.html resume.html

      mkdir -p icons
      unzip ${./favicon_package_v0.16.zip} -d icons

      # Create a file index for material/
      mkdir -p material
      pushd material
      tree -H '.' -L 1 \
        --noreport \
        --charset utf8 \
        -I index.html \
        -o index.html
      popd
      for dir in material/*/;
      do
        pushd $dir
        tree -H '.' -L 1 \
          --noreport \
          --charset utf8 \
          -I index.html \
          -o index.html
        popd
      done

      ${siteBuilder}/bin/site build
    '';

    installPhase = ''
      mkdir -p $out
      ${pkgs.rsync}/bin/rsync -rts _site/ $out
      touch $out/.nojekyll
    '';

    buildInputs = [ pkgs.tree pkgs.glibcLocales pkgs.unzip ];
  }
