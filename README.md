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


## Dependencies

- [lua-regex](https://github.com/rrthomas/lrexlib/)
