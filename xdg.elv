# Copyright (c) 2018, Cody Opel <codyopel@gmail.com>
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

# Accepts an XDG environment variable (e.g. XDG_CACHE_HOME).
# This tests for xdg values in the following order.
# Environment variable -> user config -> system config -> fallback
fn get-xdg-dir [xdgvar]{
  try {
    put (get-env $xdgvar)
  } except _ {
    local:home = (get-env HOME)
    try {
      # Evaluates strings from configs that may contain POSIX shell variables.
      put (sh -c 'echo '(awk '-F=' '/'$xdgvar'/ { print $2 }' $home'/.config/user-dirs.dirs') 2>/dev/null)
    } except _ {
      try {
        # Evaluates strings from configs that may contain POSIX shell variables.
        put (sh -c 'echo '(awk '-F=' '/'$xdgvar'/ { print $2 }' '/etc/xdg/user-dirs.defaults') 2>/dev/null)
      } except _ {
        if (==s $xdgvar 'XDG_CACHE_HOME') {
          put $home'/.cache'
        } elif (==s $xdgvar 'XDG_CONFIG_HOME') {
          put $home'/.config'
        } elif (==s $xdgvar 'XDG_DATA_HOME') {
          put $home'/.local/share'
        } elif (==s $xdgvar 'XDG_DESKTOP_DIR') {
          put $home'/Desktop'
        } elif (==s $xdgvar 'XDG_DOCUMENTS_DIR') {
          put $home'/Documents'
        } elif (==s $xdgvar 'XDG_DOWNLOAD_DIR') {
          put $home'/Downloads'
        } elif (==s $xdgvar 'XDG_MUSIC_DIR') {
          put $home'/Music'
        } elif (==s $xdgvar 'XDG_PICTURES_DIR') {
          put $home'/Pictures'
        } elif (==s $xdgvar 'XDG_PREFIX_HOME') {
          put $home'/.local'
        } elif (==s $xdgvar 'XDG_PUBLICSHARE_DIR') {
          put $home'/Public'
        } elif (==s $xdgvar 'XDG_RUNTIME_DIR') {
          put $home'/.cache'
        } elif (==s $xdgvar 'XDG_TEMPLATES_DIR') {
          put $home'/Templates'
        } elif (==s $xdgvar 'XDG_VIDEOS_DIR') {
          put $home'/Videos'
        } else {
          fail 'Unknown XDG variable: '$xdgvar
        }
      }
    }
  }
}

fn populate-xdg-env-vars {
  local:xdg-dirs = [
    'XDG_CACHE_HOME'
    'XDG_CONFIG_HOME'
    'XDG_DATA_HOME'
    'XDG_DESKTOP_DIR'
    'XDG_DOCUMENTS_DIR'
    'XDG_DOWNLOAD_DIR'
    'XDG_MUSIC_DIR'
    'XDG_PICTURES_DIR'
    'XDG_PREFIX_HOME'
    'XDG_PUBLICSHARE_DIR'
    'XDG_RUNTIME_DIR'
    'XDG_TEMPLATES_DIR'
    'XDG_VIDEOS_DIR'
  ]

  for local:i $xdg-dirs {
    try {
      if (!=s (get-env $i) '') {
        continue
      } else {
        fail
      }
    } except _ {
      set-env $i (get-xdg-dir $i)
    }
  }
}
