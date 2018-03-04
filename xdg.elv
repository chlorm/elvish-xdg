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
  } except {
    try {
      # Evaluates strings from configs that may contain POSIX shell variables.
      put (sh -c 'echo '(awk '-F=' '/'$xdgvar'/ { print $2 }' $E:HOME'/.config/user-dirs.dirs') 2>/dev/null)
    } except {
      try {
        # Evaluates strings from configs that may contain POSIX shell variables.
        put (sh -c 'echo '(awk '-F=' '/'$xdgvar'/ { print $2 }' '/etc/xdg/user-dirs.defaults') 2>/dev/null)
      } except {
        if (==s $xdgvar 'XDG_CACHE_HOME') {
          put $E:HOME'/.cache'
        } elif (==s $xdgvar 'XDG_CONFIG_HOME') {
          put $E:HOME'/.config'
        } elif (==s $xdgvar 'XDG_DATA_HOME') {
          put $E:HOME'/.local/share'
        } elif (==s $xdgvar 'XDG_DESKTOP_DIR') {
          put $E:HOME'/Desktop'
        } elif (==s $xdgvar 'XDG_DOCUMENTS_DIR') {
          put $E:HOME'/Documents'
        } elif (==s $xdgvar 'XDG_DOWNLOAD_DIR') {
          put $E:HOME'/Downloads'
        } elif (==s $xdgvar 'XDG_MUSIC_DIR') {
          put $E:HOME'/Music'
        } elif (==s $xdgvar 'XDG_PICTURES_DIR') {
          put $E:HOME'/Pictures'
        } elif (==s $xdgvar 'XDG_PREFIX_HOME') {
          put $E:HOME'/.local'
        } elif (==s $xdgvar 'XDG_PUBLICSHARE_DIR') {
          put $E:HOME'/Public'
        } elif (==s $xdgvar 'XDG_RUNTIME_DIR') {
          put $E:HOME'/.cache'
        } elif (==s $xdgvar 'XDG_TEMPLATES_DIR') {
          put $E:HOME'/Templates'
        } elif (==s $xdgvar 'XDG_VIDEOS_DIR') {
          put $E:HOME'/Videos'
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
    } except {
      set-env $i (get-xdg-dir $i)
    }
  }
}
