# Copyright (c) 2018-2019, Cody Opel <codyopel@gmail.com>
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

local:home = (get-env HOME)
local:xdg-vars = [
  &XDG_CACHE_HOME=$home'/.cache'
  &XDG_CONFIG_HOME=$home'/.config'
  &XDG_DATA_HOME=$home'/.local/share'
  &XDG_DESKTOP_DIR=$home'/Desktop'
  &XDG_DOCUMENTS_DIR=$home'/Documents'
  &XDG_DOWNLOAD_DIR=$home'/Downloads'
  &XDG_MUSIC_DIR=$home'/Music'
  &XDG_PICTURES_DIR=$home'/Pictures'
  &XDG_PREFIX_HOME=$home'/.local'
  &XDG_PUBLICSHARE_DIR=$home'/Public'
  &XDG_RUNTIME_DIR=$home'/.cache'
  &XDG_TEMPLATES_DIR=$home'/Templates'
  &XDG_VIDEOS_DIR=$home'/Videos'
]

# Accepts an XDG environment variable (e.g. XDG_CACHE_HOME).
# This tests for xdg values in the following order.
# Environment variable -> user config -> system config -> fallback
fn get-dir [xdg-var]{
  try {
    put (get-env $xdg-var)
  } except _ {
    try {
      # Evaluates strings from configs that may contain POSIX shell variables.
      put (sh -c 'echo '(awk '-F=' '/'$xdg-var'/ { print $2 }' $home'/.config/user-dirs.dirs') 2>/dev/null)
    } except _ {
      try {
        # Evaluates strings from configs that may contain POSIX shell variables.
        put (sh -c 'echo '(awk '-F=' '/'$xdg-var'/ { print $2 }' '/etc/xdg/user-dirs.defaults') 2>/dev/null)
      } except _ {
        put $xdg-vars[$xdg-var]
      }
    }
  }
}
# DEPRECATED
fn get-xdg-dir [xdg-var]{
  get-dir $xdg-var
}

fn populate-env-vars {
  for local:i [(keys $xdg-vars)] {
    try {
      _ = (!=s (get-env $i) ''i)
    } except _ {
      set-env $i (get-dir $i)
    }
  }
}
# DEPRECATED
fn populate-xdg-env-vars {
  populate-env-vars
}
