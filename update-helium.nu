#!/usr/bin/env nix-shell
#! nix-shell -i nu -p nushell

def get-helium-latest [] {
    let repo = "imputnet/helium-linux"
    let release = http get $"https://api.github.com/repos/($repo)/releases/latest"
    let version = $release.tag_name

    print $"Found latest version: ($version)"

    let platforms = [
        { system: "x86_64-linux",  repo: "helium-linux", file: $"helium-($version)-x86_64_linux.tar.xz" }
        { system: "aarch64-linux", repo: "helium-linux", file: $"helium-($version)-arm64_linux.tar.xz" }
        { system: "x86_64-darwin", repo: "helium-macos", file: $"helium_($version)_x86_64-macos.dmg" }
        { system: "aarch64-darwin", repo: "helium-macos", file: $"helium_($version)_arm64-macos.dmg" }
    ]

    let results = $platforms | each {|it|
        let url = $"https://github.com/imputnet/($it.repo)/releases/download/($version)/($it.file)"

        print $"Fetching ($it.system)."
        {
            system: $it.system
            url: $url
            sha256: (nix-prefetch-url $url | str trim)
        }
    }

    let linuxHashes = {
        "x86_64-linux": ($results | where system == "x86_64-linux" | get sha256.0),
        "aarch64-linux": ($results | where system == "aarch64-linux" | get sha256.0),
    }

    let darwinHashes = {
        "x86_64-darwin": ($results | where system == "x86_64-darwin" | get sha256.0),
        "aarch64-darwin": ($results | where system == "aarch64-darwin" | get sha256.0),
    }

    {
        version: $version,
        linuxHashes: $linuxHashes,
        darwinHashes: $darwinHashes
    }
}

let versionData = get-helium-latest

print $versionData | table --expand

$versionData | to json | save helium-versions.json --force

print "Saved to helium-versions.json"
