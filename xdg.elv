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


use re
use github.com/chlorm/elvish-stl/io
use github.com/chlorm/elvish-stl/os
use github.com/chlorm/elvish-stl/path
use github.com/chlorm/elvish-stl/regex
use github.com/chlorm/elvish-user-tmpfs/tmpfs


local:home = (get-env HOME)
# NOTE: some of these are not officially part of the basedir spec but are
#       useful so they are included here.
local:xdg-vars = [
  &XDG_CACHE_HOME=(path:join $home '.cache')
  &XDG_CONFIG_HOME=(path:join $home '.config')
  &XDG_DESKTOP_DIR=(path:join $home 'Desktop')
  &XDG_DOCUMENTS_DIR=(path:join $home 'Documents')
  &XDG_DOWNLOAD_DIR=(path:join $home 'Downloads')
  &XDG_MUSIC_DIR=(path:join $home 'Music')
  &XDG_PICTURES_DIR=(path:join $home 'Pictures')
  &XDG_PREFIX_HOME=(path:join $home '.local')
  &XDG_PUBLICSHARE_DIR=(path:join $home 'Public')
  &XDG_RUNTIME_DIR=$nil
  &XDG_TEMPLATES_DIR=(path:join $home 'Templates')
  &XDG_VIDEOS_DIR=(path:join $home 'Videos')
]
# FIXME: XDG_PREFIX_HOME should be evaluated
xdg-vars[XDG_BIN_HOME]=(path:join $xdg-vars[XDG_PREFIX_HOME] 'bin')
xdg-vars[XDG_LIB_HOME]=(path:join $xdg-vars[XDG_PREFIX_HOME] 'lib')
xdg-vars[XDG_DATA_HOME]=(path:join $xdg-vars[XDG_PREFIX_HOME] 'share')


# Evaluates strings from configs that may contain POSIX shell variables.
fn -get-dir-from-config [config var]{
  local:m = ''
  for local:i [(io:cat $config)] {
    if (re:match '^'$var'.*' $i) {
      m = (regex:find $var'=(.*)' $i)
    }
  }
  if (==s '' $m) {
    fail 'no match in config'
  }
  put (sh -c '. '$config' && eval echo '$m)
}

# Accepts an XDG environment variable (e.g. XDG_CACHE_HOME).
# This tests for xdg values in the following order.
# Environment variable -> user config -> system config -> fallback
fn get-dir [xdg-var]{
  try {
    put (get-env $xdg-var)
  } except _ {
    # Never setup XDG_RUNTIME_DIR from configs if the OS fails to provide it.
    if (==s 'XDG_RUNTIME_DIR' $xdg-var) {
      try {
        # This will automatically create the directory and set permissions.
        put (tmpfs:get-user-tmpfs)
      } except _ {
        put $xdg-vars[XDG_CACHE_HOME]
      }
      return
    }
    try {

      # Always try XDG_CONFIG_HOME when loading user config.
      local:configdir = $xdg-vars['XDG_CONFIG_HOME']
      try {
        configdir = (get-env 'XDG_CONFIG_HOME')
      } except _ {
        # Ignore
      }
      put (-get-dir-from-config $configdir'/user-dirs.dirs' $xdg-var)
    } except _ {
      try {
        put (-get-dir-from-config $E:ROOT'/etc/xdg/user-dirs.defaults' $xdg-var)
      } except _ {
        put $xdg-vars[$xdg-var]
      }
    }
  }
}

fn populate-env-vars {
  for local:i [ (keys $xdg-vars) ] {
    try {
      _ = (!=s (get-env $i) ''i)
    } except _ {
      set-env $i (get-dir $i)
    }
  }
}
