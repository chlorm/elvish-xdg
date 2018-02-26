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

# This tests for xdg values in the following order.
# Environment variable -> user config -> system config -> fallback

# XXX: Because elvish doesn't support $E:$var we have to have individual
#      functions for each variable, if this changes in the future this
#      module could be simplified further.

fn get_xdg_val_fallback [x]{
  local:xdg = ''
  if (test -f $E:HOME/.config/user-dirs.dirs) {
    try {
      # Evaluates strings from configs that may contain POSIX shell variables.
      xdg = (sh -c 'echo '(awk '-F=' '/'$x'/ { print $2 }' $E:HOME'/.config/user-dirs.dirs') 2>/dev/null)
    } except {
      xdg = ''
    }
  }
  if (and ?(test -f /etc/xdg/user-dirs.defaults) (==s $xdg '')) {
    try {
      # Evaluates strings from configs that may contain POSIX shell variables.
      xdg = (sh -c 'echo '(awk '-F=' '/'$x'/ { print $2 }' '/etc/xdg/user-dirs.defaults') 2>/dev/null)
    } except {
      xdg = ''
    }
  }
  if (==s $xdg '') {
    if (==s $x 'XDG_CACHE_HOME') {
      xdg = $E:HOME'/.cache'
    } elif (==s $x 'XDG_CONFIG_HOME') {
      xdg = $E:HOME'/.config'
    } elif (==s $x 'XDG_DATA_HOME') {
      xdg = $E:HOME'/.local/share'
    } elif (==s $x 'XDG_DESKTOP_DIR') {
      xdg = $E:HOME'/Desktop'
    } elif (==s $x 'XDG_DOCUMENTS_DIR') {
      xdg = $E:HOME'/Documents'
    } elif (==s $x 'XDG_DOWNLOAD_DIR') {
      xdg = $E:HOME'/Downloads'
    } elif (==s $x 'XDG_MUSIC_DIR') {
      xdg = $E:HOME'/Music'
    } elif (==s $x 'XDG_PICTURES_DIR') {
      xdg = $E:HOME'/Pictures'
    } elif (==s $x 'XDG_PREFIX_HOME') {
      xdg = $E:HOME'/.local'
    } elif (==s $x 'XDG_PUBLICSHARE_DIR') {
      xdg = $E:HOME'/Public'
    } elif (==s $x 'XDG_RUNTIME_DIR') {
      xdg = $E:HOME'/.cache'
    } elif (==s $x 'XDG_TEMPLATES_DIR') {
      xdg = $E:HOME'/Templates'
    } elif (==s $x 'XDG_VIDEOS_DIR') {
      xdg = $E:HOME'/Videos'
    } else {
      fail 'Unknown XDG variable: '$x
    }
  }

  put $xdg
}

fn get_xdg_cache_home {
  if (==s $E:XDG_CACHE_HOME '') {
    E:XDG_CACHE_HOME = (get_xdg_val_fallback 'XDG_CACHE_HOME')
  }
}

fn get_xdg_config_home {
  if (==s $E:XDG_CONFIG_HOME '') {
    E:XDG_CONFIG_HOME = (get_xdg_val_fallback 'XDG_CONFIG_HOME')
  }
}

fn get_xdg_data_home {
  if (==s $E:XDG_DATA_HOME '') {
    E:XDG_DATA_HOME = (get_xdg_val_fallback 'XDG_DATA_HOME')
  }
}

fn get_xdg_desktop_dir {
  if (==s $E:XDG_DESKTOP_DIR '') {
    E:XDG_DESKTOP_DIR = (get_xdg_val_fallback 'XDG_DESKTOP_DIR')
  }
}

fn get_xdg_documents_dir {
  if (==s $E:XDG_DOCUMENTS_DIR '') {
    E:XDG_DOCUMENTS_DIR = (get_xdg_val_fallback 'XDG_DOCUMENTS_DIR')
  }
}

fn get_xdg_download_dir {
  if (==s $E:XDG_DOWNLOAD_DIR '') {
    E:XDG_DOWNLOAD_DIR = (get_xdg_val_fallback 'XDG_DOWNLOAD_DIR')
  }
}

fn get_xdg_music_dir {
  if (==s $E:XDG_MUSIC_DIR '') {
    E:XDG_MUSIC_DIR = (get_xdg_val_fallback 'XDG_MUSIC_DIR')
  }
}

fn get_xdg_pictures_dir {
  if (==s $E:XDG_PICTURES_DIR '') {
    E:XDG_PICTURES_DIR = (get_xdg_val_fallback 'XDG_PICTURES_DIR')
  }
}

fn get_xdg_prefix_home {
  if (==s $E:XDG_PREFIX_HOME '') {
    E:XDG_PREFIX_HOME = (get_xdg_val_fallback 'XDG_PREFIX_HOME')
  }
}

fn get_xdg_publicshare_dir {
  if (==s $E:XDG_PUBLICSHARE_DIR '') {
    put (get_xdg_val_fallback 'XDG_PUBLICSHARE_DIR')
  }
}

fn get_xdg_runtime_dir {
  if (==s $E:XDG_RUNTIME_DIR '') {
    E:XDG_RUNTIME_DIR = (get_xdg_val_fallback 'XDG_RUNTIME_DIR')
  }
}

fn get_xdg_templates_dir {
  if (==s $E:XDG_TEMPLATES_DIR '') {
    E:XDG_TEMPLATES_DIR = (get_xdg_val_fallback 'XDG_TEMPLATES_DIR')
  }
}

fn get_xdg_videos_dir {
  if (==s $E:XDG_VIDEOS_DIR '') {
    E:XDG_VIDEOS_DIR = (get_xdg_val_fallback 'XDG_VIDEOS_DIR')
  }
}

fn init {
  get_xdg_cache_home
  get_xdg_config_home
  get_xdg_data_home
  get_xdg_desktop_dir
  get_xdg_documents_dir
  get_xdg_download_dir
  get_xdg_music_dir
  get_xdg_pictures_dir
  get_xdg_prefix_home
  get_xdg_publicshare_dir
  get_xdg_runtime_dir
  get_xdg_templates_dir
  get_xdg_videos_dir
}

init
