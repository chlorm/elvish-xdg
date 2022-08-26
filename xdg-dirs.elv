# Copyright (c) 2018-2022, Cody Opel <cwopel@chlorm.net>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


use github.com/chlorm/elvish-stl/env
use github.com/chlorm/elvish-stl/exec
use github.com/chlorm/elvish-stl/io
use github.com/chlorm/elvish-stl/list
use github.com/chlorm/elvish-stl/os
use github.com/chlorm/elvish-stl/path
use github.com/chlorm/elvish-stl/platform
use github.com/chlorm/elvish-stl/re
use github.com/chlorm/elvish-stl/str
use github.com/chlorm/elvish-tmpfs/tmpfs


var HOME = (path:home)
var XDG-CACHE-HOME = 'XDG_CACHE_HOME'
var XDG-CONFIG-HOME = 'XDG_CONFIG_HOME'
var XDG-DESKTOP-DIR = 'XDG_DESKTOP_DIR'
var XDG-DOCUMENTS-DIR = 'XDG_DOCUMENTS_DIR'
var XDG-DOWNLOAD-DIR = 'XDG_DOWNLOAD_DIR'
var XDG-MUSIC-DIR = 'XDG_MUSIC_DIR'
var XDG-PICTURES-DIR = 'XDG_PICTURES_DIR'
var XDG-PUBLICSHARE-DIR = 'XDG_PUBLICSHARE_DIR'
var XDG-RUNTIME-DIR = 'XDG_RUNTIME_DIR'
var XDG-TEMPLATES-DIR = 'XDG_TEMPLATES_DIR'
var XDG-VIDEOS-DIR = 'XDG_VIDEOS_DIR'
# NOTE: Some of these are not officially part of the basedir spec but are
#       useful so they are included here.
var XDG-PREFIX-HOME = 'XDG_PREFIX_HOME'
var XDG-BIN-HOME = 'XDG_BIN_HOME'
var XDG-DATA-HOME = 'XDG_DATA_HOME'
var XDG-LIB-HOME = 'XDG_LIB_HOME'
var XDG-STATE-HOME = 'XDG_STATE_HOME'
# System search path
var XDG-CONFIG-DIRS = 'XDG_CONFIG_DIRS'

var XDG-VARS = [
    $XDG-CACHE-HOME
    $XDG-CONFIG-HOME
    $XDG-DESKTOP-DIR
    $XDG-DOCUMENTS-DIR
    $XDG-DOWNLOAD-DIR
    $XDG-MUSIC-DIR
    $XDG-PICTURES-DIR
    $XDG-PUBLICSHARE-DIR
    $XDG-RUNTIME-DIR
    $XDG-TEMPLATES-DIR
    $XDG-VIDEOS-DIR
    $XDG-PREFIX-HOME
    $XDG-BIN-HOME
    $XDG-DATA-HOME
    $XDG-LIB-HOME
    $XDG-STATE-HOME
]

fn -fallback-cache-home {
    if $platform:is-windows {
        env:get 'TEMP'
        return
    }
    if $platform:is-darwin {
        path:join $HOME 'Library' 'Caches'
        return
    }

    path:join $HOME '.cache'
}

fn -fallback-config-home {
    if $platform:is-windows {
        env:get 'APPDATA'
        return
    }
    if $platform:is-darwin {
        path:join $HOME 'Library' 'Preferences'
        return
    }

    path:join $HOME '.config'
}

fn -fallback-desktop-dir {
    path:join $HOME 'Desktop'
}

fn -fallback-documents-dir {
    path:join $HOME 'Documents'
}

fn -fallback-download-dir {
    path:join $HOME 'Downloads'
}

fn -fallback-music-dir {
    path:join $HOME 'Music'
}

fn -fallback-pictures-dir {
    path:join $HOME 'Pictures'
}

fn -fallback-publicshare-dir {
    path:join $HOME 'Public'
}

fn -fallback-runtime-dir {
    put $nil
}

fn -fallback-templates-dir {
    # FIXME: Templates is some kind of hidden symlink on Windows
    path:join $HOME 'Templates'
}

fn -fallback-videos-dir {
    path:join $HOME 'Videos'
}

fn -fallback-prefix-home {
    path:join $HOME '.local'
}

fn -fallback-bin-home {|&parent=(-fallback-prefix-home)|
    path:join $parent 'bin'
}

fn -fallback-data-home {|&parent=(-fallback-prefix-home)|
    path:join $parent 'share'
}

fn -fallback-lib-home {|&parent=(-fallback-prefix-home)|
    path:join $parent 'lib'
}

fn -fallback-state-home {|&parent=(-fallback-prefix-home)|
    if $platform:is-windows {
        env:get 'LOCALAPPDATA'
        return
    }
    if $platform:is-darwin {
        path:join $HOME 'Library' 'Application Support'
        return
    }

    path:join $parent 'state'
}

var -FALLBACK_FUNCS = [&]
set -FALLBACK_FUNCS[$XDG-CACHE-HOME] = $-fallback-cache-home~
set -FALLBACK_FUNCS[$XDG-CONFIG-HOME] = $-fallback-config-home~
set -FALLBACK_FUNCS[$XDG-DESKTOP-DIR] = $-fallback-desktop-dir~
set -FALLBACK_FUNCS[$XDG-DOCUMENTS-DIR] = $-fallback-documents-dir~
set -FALLBACK_FUNCS[$XDG-DOWNLOAD-DIR] = $-fallback-download-dir~
set -FALLBACK_FUNCS[$XDG-MUSIC-DIR] = $-fallback-music-dir~
set -FALLBACK_FUNCS[$XDG-PICTURES-DIR] = $-fallback-pictures-dir~
set -FALLBACK_FUNCS[$XDG-PUBLICSHARE-DIR] = $-fallback-publicshare-dir~
set -FALLBACK_FUNCS[$XDG-RUNTIME-DIR] = $-fallback-runtime-dir~
set -FALLBACK_FUNCS[$XDG-TEMPLATES-DIR] = $-fallback-templates-dir~
set -FALLBACK_FUNCS[$XDG-VIDEOS-DIR] = $-fallback-videos-dir~
set -FALLBACK_FUNCS[$XDG-PREFIX-HOME] = $-fallback-prefix-home~
set -FALLBACK_FUNCS[$XDG-BIN-HOME] = $-fallback-bin-home~
set -FALLBACK_FUNCS[$XDG-DATA-HOME] = $-fallback-data-home~
set -FALLBACK_FUNCS[$XDG-LIB-HOME] = $-fallback-lib-home~
set -FALLBACK_FUNCS[$XDG-STATE-HOME] = $-fallback-state-home~

# This is to avoid generating all paths when the module is invoked.
fn -fallback {|xdgVar &parent=$nil|
    try {
        if (eq $parent $nil) {
            $-FALLBACK_FUNCS[$xdgVar]
            return
        }

        $-FALLBACK_FUNCS[$xdgVar] &parent=$parent
    } catch e {
        var err = 'Invalid var: '$xdgVar"\n\n"(to-string $e)
        fail $err
    }
}

fn -get-dir-from-config {|config var|
    var configVarPath = $nil
    for i [ (io:cat $config) ] {
        if (re:match '^'$var'.*' $i) {
            set configVarPath = (re:find $var'=(.*)' $i)
        }

        # System configs allow specifying vars with out XDG_ _DIR
        if (str:has-suffix $var '_DIR') {
            var varNoPrefixSuffix = (re:find '^XDG_([A-Z]+)_DIR$' $var)
            if (re:match '^'$varNoPrefixSuffix'.*' $i) {
                set configVarPath = (re:find $varNoPrefixSuffix'r=(.*)' $i)
            }
        }
    }
    if (eq $configVarPath $nil) {
        fail
    }
    put $configVarPath
}

fn get-config-user {|var|
    # Always try XDG_CONFIG_HOME when loading user config.
    var configDir = (-fallback $XDG-CACHE-HOME)
    try {
        set configDir = (env:get $XDG-CONFIG-HOME)
    } catch _ { }
    var configVarPath = $nil
    var config = (path:join $configDir 'user-dirs.dirs')
    set configVarPath = (-get-dir-from-config $config $var)
    if (eq $configVarPath $nil) {
        fail
    }
    # Evaluates strings from configs that may contain POSIX shell variables.
    put (exec:cmd-out 'sh' '-c' '. '$config' && eval echo '$configVarPath)
}

fn get-config-system {|var|
    var configVarPath = $nil
    try {
        var t = (env:get $XDG-CONFIG-DIRS)
        var v = $nil
        for i [ (str:split $env:DELIMITER $t) ] {
            # FIXME: According to the spec it should be subdir/conf
            try {
                set v = (-get-dir-from-config (path:join $i 'user-dirs.defaults') $var)
                if (not (eq $v $nil)) {
                    set configVarPath = $v
                    break
                }
            } catch _ { }
        }
        fail
    } catch _ {
        set configVarPath = (
            -get-dir-from-config $E:ROOT'/etc/xdg/user-dirs.defaults' $var
        )
    }
    # Paths in system configs are relative to a user home directory.
    put (path:join (path:home) $configVarPath)
}

# Accepts an XDG environment variable (e.g. XDG_CACHE_HOME).
# This tests for xdg values in the following order.
# Environment variable -> user config -> system config(s) -> fallback
fn get {|xdgVar|
    var xdgPrefixChild = [
        $XDG-BIN-HOME
        $XDG-DATA-HOME
        $XDG-LIB-HOME
        $XDG-STATE-HOME
    ]
    try {
        env:get $xdgVar
    } catch _ {
        # Never setup XDG_RUNTIME_DIR from configs if the OS fails to
        # provide it.
        if (==s $xdgVar $XDG-RUNTIME-DIR) {
            try {
                # This will automatically create the directory and set
                # permissions.
                tmpfs:get-user
            } catch _ {
                -fallback $XDG-CACHE-HOME
            }
            return
        }
        try {
            get-config-user $xdgVar
        } catch _ {
            try {
                get-config-system $xdgVar
            } catch _ {
                if (list:has $xdgPrefixChild $xdgVar) {
                    -fallback &parent=(get $XDG-PREFIX-HOME) $xdgVar
                } else {
                    -fallback $xdgVar
                }
            }
        }
    }
}

fn cache-home {
    get $XDG-CACHE-HOME
}

fn config-home {
    get $XDG-CONFIG-HOME
}

fn desktop-dir {
    get $XDG-DESKTOP-DIR
}

fn download-dir {
    get $XDG-DOWNLOAD-DIR
}

fn music-dir {
    get $XDG-MUSIC-DIR
}

fn pictures-dir {
    get $XDG-PICTURES-DIR
}

fn publicshare-dir {
    get $XDG-PUBLICSHARE-DIR
}

fn runtime-dir {
    get $XDG-RUNTIME-DIR
}

fn templates-dir {
    get $XDG-TEMPLATES-DIR
}

fn videos-dir {
    get $XDG-VIDEOS-DIR
}

fn prefix-home {
    get $XDG-PREFIX-HOME
}

fn bin-home {
    get $XDG-BIN-HOME
}

fn data-home {
    get $XDG-DATA-HOME
}

fn lib-home {
    get $XDG-PREFIX-HOME
}

fn state-home {
    get $XDG-STATE-HOME
}

fn populate-env {
    if $platform:is-windows {
        # HOME is not set on Windows.
       env:set 'HOME' (path:home)
    }
    for i $XDG-VARS {
        try {
            var _ = (!=s (env:get $i) '')
        } catch _ {
            env:set $i (get $i)
        }
    }
}
