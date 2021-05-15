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
use github.com/chlorm/elvish-user-tmpfs/tmpfs


var HOME = (path:home)
# NOTE: some of these are not officially part of the basedir spec but are
#       useful so they are included here.
var XDG-VARS = [
    &XDG_CACHE_HOME=(path:join $HOME '.cache')
    &XDG_CONFIG_HOME=(path:join $HOME '.config')
    &XDG_DESKTOP_DIR=(path:join $HOME 'Desktop')
    &XDG_DOCUMENTS_DIR=(path:join $HOME 'Documents')
    &XDG_DOWNLOAD_DIR=(path:join $HOME 'Downloads')
    &XDG_MUSIC_DIR=(path:join $HOME 'Music')
    &XDG_PICTURES_DIR=(path:join $HOME 'Pictures')
    &XDG_PREFIX_HOME=(path:join $HOME '.local')
    &XDG_PUBLICSHARE_DIR=(path:join $HOME 'Public')
    &XDG_RUNTIME_DIR=$nil
    &XDG_TEMPLATES_DIR=(path:join $HOME 'Templates')
    &XDG_VIDEOS_DIR=(path:join $HOME 'Videos')
]
# FIXME: XDG_PREFIX_HOME should be evaluated
set XDG-VARS['XDG_BIN_HOME'] = (path:join $XDG-VARS['XDG_PREFIX_HOME'] 'bin')
set XDG-VARS['XDG_LIB_HOME'] = (path:join $XDG-VARS['XDG_PREFIX_HOME'] 'lib')
set XDG-VARS['XDG_DATA_HOME'] = (path:join $XDG-VARS['XDG_PREFIX_HOME'] 'share')

if $platform:is-windows {
    # HOME is not set on Windows.
    set XDG-VARS['HOME'] = $HOME
    set XDG-VARS['XDG_CACHE_HOME'] = (get-env 'TEMP')
    set XDG-VARS['XDG_CONFIG_HOME'] = (get-env 'APPDATA')
    set XDG-VARS['XDG_DATA_HOME'] = (get-env 'LOCALAPPDATA')
} elif (==s $platform:os 'darwin') {
    set XDG-VARS['XDG_CACHE_HOME'] = (path:join $HOME 'Library' 'Caches')
    set XDG-VARS['XDG_CONFIG_HOME'] = (path:join $HOME 'Library' 'Preferences')
    set XDG-VARS['XDG_DATA_HOME'] = (path:join $HOME 'Library' 'Application Support')
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
    put (e:sh '-c' '. '$config' && eval echo '$m)
}

# Accepts an XDG environment variable (e.g. XDG_CACHE_HOME).
# This tests for xdg values in the following order.
# Environment variable -> user config -> system config -> fallback
fn get-dir [xdgVar]{
    try {
        put (get-env $xdgVar)
    } except _ {
        # Never setup XDG_RUNTIME_DIR from configs if the OS fails to
        # provide it.
        if (==s $xdgVar 'XDG_RUNTIME_DIR') {
            try {
                if $platform:is-windows {
                    # Windows has no equivalent of tmpfs/ramfs.
                    fail
                }
                # This will automatically create the directory and set
                # permissions.
                put (tmpfs:get-user-tmpfs)
            } except _ {
                put $XDG-VARS['XDG_CACHE_HOME']
            }
            return
        }
        try {
            # Always try XDG_CONFIG_HOME when loading user config.
            var configDir = $XDG-VARS['XDG_CONFIG_HOME']
            try {
                set configDir = (get-env 'XDG_CONFIG_HOME')
            } except _ {
                # Ignore
            }
            put (-get-dir-from-config $configDir'/user-dirs.dirs' $xdgVar)
        } except _ {
            try {
                put (-get-dir-from-config ^
                         $E:ROOT'/etc/xdg/user-dirs.defaults' $xdgVar)
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
