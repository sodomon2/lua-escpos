# lua-escpos

lua library for printing to ESC/POS-compatible thermal printers based on https://github.com/mike42/escpos-php

# Usage

```lua
local escpos = require("escpos")

escpos:connector("/dev/usb/lp0") -- or devices connector

escpos:text("Hello World!! from lua")
escpos:feed(2)
```

# Dependencies

- [lua-regex](https://github.com/rrthomas/lrexlib/)
