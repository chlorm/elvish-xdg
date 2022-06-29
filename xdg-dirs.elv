# Copyright (c) 2018-2021, Cody Opel <cwopel@chlorm.net>
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


use re
use github.com/chlorm/elvish-stl/exec
use github.com/chlorm/elvish-stl/io
use github.com/chlorm/elvish-stl/os
use github.com/chlorm/elvish-stl/path
use github.com/chlorm/elvish-stl/platform
use github.com/chlorm/elvish-stl/regex
use github.com/chlorm/elvish-tmpfs/tmpfs


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

# Evaluates strings from configs that may contain POSIX shell variables.
fn -get-dir-from-config {|config var|
    var m = $nil
    for i [ (io:cat $config) ] {
        if (re:match '^'$var'.*' $i) {
            set m = (regex:find $var'=(.*)' $i)
        }
    }
    if (eq $m $nil) {
        fail 'no match in config'
    }
    exec:cmd-out 'sh' '-c' '. '$config' && eval echo '$m
}

# This is to avoid generating all paths when the module is invoked.
fn -fallback {|xdgVar &parent=$nil|
    var darwin = 'darwin'
    var HOME = (path:home)

    if (==s $XDG-CACHE-HOME $xdgVar) {
        if $platform:is-windows {
            get-env 'TEMP'
        } elif $platform:is-darwin {
            path:join $HOME 'Library' 'Caches'
        } else {
            path:join $HOME '.cache'
        }
    } elif (==s $XDG-CONFIG-HOME $xdgVar) {
        if $platform:is-windows {
            get-env 'APPDATA'
        } elif $platform:is-darwin {
            path:join $HOME 'Library' 'Preferences'
        } else {
            path:join $HOME '.config'
        }
    } elif (==s $XDG-DESKTOP-DIR $xdgVar) {
        path:join $HOME 'Desktop'
    } elif (==s $XDG-DOCUMENTS-DIR $xdgVar) {
        path:join $HOME 'Documents'
    } elif (==s $XDG-DOWNLOAD-DIR $xdgVar) {
        path:join $HOME 'Downloads'
    } elif (==s $XDG-MUSIC-DIR $xdgVar) {
        path:join $HOME 'Music'
    } elif (==s $XDG-PICTURES-DIR $xdgVar) {
        path:join $HOME 'Pictures'
    } elif (==s $XDG-PUBLICSHARE-DIR $xdgVar) {
        path:join $HOME 'Public'
    } elif (==s $XDG-RUNTIME-DIR $xdgVar) {
        put $nil
    } elif (==s $XDG-TEMPLATES-DIR $xdgVar) {
        # FIXME: Templates is some kind of hidden symlink on Windows
        path:join $HOME 'Templates'
    } elif (==s $XDG-VIDEOS-DIR $xdgVar) {
        path:join $HOME 'Videos'
    } elif (==s $XDG-PREFIX-HOME $xdgVar) {
        path:join $HOME '.local'
    } elif (==s $XDG-BIN-HOME $xdgVar) {
        path:join $parent 'bin'
    } elif (==s $XDG-DATA-HOME $xdgVar) {
        path:join $parent 'share'
    } elif (==s $XDG-LIB-HOME $xdgVar) {
        path:join $parent 'lib'
    } elif (==s $XDG-STATE-HOME $xdgVar) {
        if $platform:is-windows {
            get-env 'LOCALAPPDATA'
        } elif $platform:is-darwin {
            path:join $HOME 'Library' 'Application Support'
        } else {
            path:join $parent 'state'
        }
    } else {
        fail 'Invalid var: '$xdgVar
    }
}

fn get-var {|var|
    get-env $var
}

fn get-config-user {|var|
    # Always try XDG_CONFIG_HOME when loading user config.
    var configDir = (-fallback $XDG-CACHE-HOME)
    try {
        set configDir = (get-var $XDG-CONFIG-HOME)
    } catch _ {
        # Ignore
    }
    -get-dir-from-config (path:join $configDir 'user-dirs.dirs') $var
}

fn get-config-system {|var|
    # FIXME: try XDG_CONFIG_DIRS here
    -get-dir-from-config ^
        $E:ROOT'/etc/xdg/user-dirs.defaults' $var
}

# Accepts an XDG environment variable (e.g. XDG_CACHE_HOME).
# This tests for xdg values in the following order.
# Environment variable -> user config -> system config -> fallback
fn get {|xdgVar|
    var xdgPrefixChild = [
        $XDG-BIN-HOME
        $XDG-DATA-HOME
        $XDG-LIB-HOME
        $XDG-STATE-HOME
    ]
    try {
        get-var $xdgVar
    } catch _ {
        # Never setup XDG_RUNTIME_DIR from configs if the OS fails to
        # provide it.
        if (==s $xdgVar $XDG-RUNTIME-DIR) {
            try {
                # This will automatically create the directory and set
                # permissions.
                tmpfs:get-user
            } catch _ {
                put (-fallback $XDG-CACHE-HOME)
            }
            return
        }
        try {
            get-config-user $xdgVar
        } catch _ {
            try {
                get-config-system $xdgVar
            } catch _ {
                if (has-value $xdgPrefixChild $xdgVar) {
                    put (-fallback &parent=(get $XDG-PREFIX-HOME) $xdgVar)
                } else {
                    put (-fallback $xdgVar)
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
        set-env 'HOME' (path:home)
    }
    for i $XDG-VARS {
        try {
            var _ = (!=s (get-env $i) '')
        } catch _ {
            set-env $i (get $i)
        }
    }
}
