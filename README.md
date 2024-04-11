# lua-escpos

lua library for printing to ESC/POS-compatible thermal printers based on https://github.com/mike42/escpos-php

# Usage

```lua
local escpos = require("escpos")

escpos:connector_type(type) -- linux or network
device:connector(device_connector)

escpos:text("Hello World!! from lua")
escpos:feed(1)
device:close()
```

## Install

Install with luarocks:

```
$ luarocks install lua-escpos
```

## Documentation
See the online documentation of [lua-escpos](https://sodomon.gitlab.io/lua-escpos)

To generate the documentation locally:

```
$ ldoc -c docs/config.ld -d ../public/ -a .
```
the documentation will be generated in public/.


## Dependencies

- [lua-regex](https://github.com/rrthomas/lrexlib/) For the barcode support.
- [luasocket](https://lunarmodules.github.io/luasocket/) For the network connector.
