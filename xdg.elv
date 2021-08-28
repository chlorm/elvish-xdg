# Copyright (c) 2018-2020, Cody Opel <cwopel@chlorm.net>
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


use platform
use re
use github.com/chlorm/elvish-stl/io
use github.com/chlorm/elvish-stl/os
use github.com/chlorm/elvish-stl/path
use github.com/chlorm/elvish-stl/regex
use github.com/chlorm/elvish-stl/wrap
use github.com/chlorm/elvish-user-tmpfs/tmpfs


var XDG-CACHE-HOME = 'XDG_CACHE_HOME'
var XDG-CONFIG-HOME = 'XDG_CONFIG_HOME'
var XDG-DESKTOP-DIR = 'XDG_DESKTOP_DIR'
var XDG-DOCUMENTS-DIR = 'XDG_DOCUMENTS_DIR'
var XDG-DOWNLOAD-DIR = 'XDG_DOWNLOAD_DIR'
var XDG-MUSIC-DIR = 'XDG_MUSIC_DIR'
var XDG-PICTURES-DIR = 'XDG_PICTURES_DIR'
var XDG-PREFIX-HOME = 'XDG_PREFIX_HOME'
var XDG-PUBLICSHARE-DIR = 'XDG_PUBLICSHARE_DIR'
var XDG-RUNTIME-DIR = 'XDG_RUNTIME_DIR'
var XDG-TEMPLATES-DIR = 'XDG_TEMPLATES_DIR'
var XDG-VIDEOS-DIR = 'XDG_VIDEOS_DIR'
var XDG-BIN-HOME = 'XDG_BIN_HOME'
var XDG-LIB-HOME = 'XDG_LIB_HOME'
var XDG-DATA-HOME = 'XDG_DATA_HOME'

var HOME = (path:home)
# NOTE: some of these are not officially part of the basedir spec but are
#       useful so they are included here.
var XDG-VARS = [&]
set XDG-VARS[$XDG-CACHE-HOME] = (path:join $HOME '.cache')
set XDG-VARS[$XDG-CONFIG-HOME] = (path:join $HOME '.config')
set XDG-VARS[$XDG-DESKTOP-DIR] = (path:join $HOME 'Desktop')
set XDG-VARS[$XDG-DOCUMENTS-DIR] = (path:join $HOME 'Documents')
set XDG-VARS[$XDG-DOWNLOAD-DIR] = (path:join $HOME 'Downloads')
set XDG-VARS[$XDG-MUSIC-DIR] = (path:join $HOME 'Music')
set XDG-VARS[$XDG-PICTURES-DIR] = (path:join $HOME 'Pictures')
set XDG-VARS[$XDG-PUBLICSHARE-DIR] = (path:join $HOME 'Public')
set XDG-VARS[$XDG-RUNTIME-DIR] = $nil
# FIXME: Templates is some kind of hidden symlink on Windows
set XDG-VARS[$XDG-TEMPLATES-DIR] = (path:join $HOME 'Templates')
set XDG-VARS[$XDG-VIDEOS-DIR] = (path:join $HOME 'Videos')
set XDG-VARS[$XDG-PREFIX-HOME] = (path:join $HOME '.local')
# FIXME: XDG_PREFIX_HOME should be evaluated
set XDG-VARS[$XDG-BIN-HOME] = (path:join $XDG-VARS[$XDG-PREFIX-HOME] 'bin')
set XDG-VARS[$XDG-LIB-HOME] = (path:join $XDG-VARS[$XDG-PREFIX-HOME] 'lib')
set XDG-VARS[$XDG-DATA-HOME] = (path:join $XDG-VARS[$XDG-PREFIX-HOME] 'share')

if $platform:is-windows {
    # HOME is not set on Windows.
    set XDG-VARS['HOME'] = $HOME
    set XDG-VARS[$XDG-CACHE-HOME] = (get-env 'TEMP')
    set XDG-VARS[$XDG-CONFIG-HOME] = (get-env 'APPDATA')
    set XDG-VARS[$XDG-DATA-HOME] = (get-env 'LOCALAPPDATA')
} elif (==s $platform:os 'darwin') {
    set XDG-VARS[$XDG-CACHE-HOME] = (path:join $HOME 'Library' 'Caches')
    set XDG-VARS[$XDG-CONFIG-HOME] = (path:join $HOME 'Library' 'Preferences')
    set XDG-VARS[$XDG-DATA-HOME] = (path:join $HOME 'Library' 'Application Support')
}

# Evaluates strings from configs that may contain POSIX shell variables.
fn -get-dir-from-config [config var]{
    var m = $nil
    for i [ (io:cat $config) ] {
        if (re:match '^'$var'.*' $i) {
            set m = (regex:find $var'=(.*)' $i)
        }
    }
    if (eq $m $nil) {
        fail 'no match in config'
    }
    wrap:cmd-out 'sh' '-c' '. '$config' && eval echo '$m
}

# Accepts an XDG environment variable (e.g. XDG_CACHE_HOME).
# This tests for xdg values in the following order.
# Environment variable -> user config -> system config -> fallback
fn get-dir [xdgVar]{
    try {
        get-env $xdgVar
    } except _ {
        # Never setup XDG_RUNTIME_DIR from configs if the OS fails to
        # provide it.
        if (==s $xdgVar $XDG-RUNTIME-DIR) {
            try {
                if $platform:is-windows {
                    # Windows has no equivalent of tmpfs/ramfs.
                    fail
                }
                # This will automatically create the directory and set
                # permissions.
                tmpfs:get-user-tmpfs
            } except _ {
                put $XDG-VARS[$XDG-CACHE-HOME]
            }
            return
        }
        try {
            # Always try XDG_CONFIG_HOME when loading user config.
            var configDir = $XDG-VARS[$XDG-CACHE-HOME]
            try {
                set configDir = (get-env $XDG-CONFIG-HOME)
            } except _ {
                # Ignore
            }
            -get-dir-from-config (path:join $configDir 'user-dirs.dirs') $xdgVar
        } except _ {
            try {
                -get-dir-from-config ^
                    $E:ROOT'/etc/xdg/user-dirs.defaults' $xdgVar
            } except _ {
                put $XDG-VARS[$xdgVar]
            }
        }
    }
}

fn populate-env-vars {
    for i [ (keys $XDG-VARS) ] {
        try {
            var _ = (!=s (get-env $i) '')
        } except _ {
            set-env $i (get-dir $i)
        }
    }
}
