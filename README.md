# elvish-xdg

###### An [Elvish](https://elv.sh) module to return XDG directories.

```elvish
epm:install github.com/chlorm/elvish-xdg
use github.com/chlorm/elvish-xdg/xdg-dirs

xdg-dirs:get 'XDG_CONFIG_HOME'
# or
xdg-dirs:get $xdg-dirs:XDG-CONFIG-HOME
# or
xdg-dirs:config-home

xdg:populate-env
```
