package = "lua-escpos"
version = "scm-0"

source = {
  url = "git://github.com/sodomon2/lua-escpos"
}

description = {
  summary = "LUA library for printing to ESC/POS-compatible thermal printers",
  detailed = [[
    Lua library for printing to ESC/POS-compatible thermal printers based on https://github.com/mike42/escpos-php
  ]],
  license = "MIT",
  homepage = "https://github.com/sodomon2/lua-escpos"
}

dependencies = {
  "lua >= 5.1",
  "lrexlib-pcre2",
  "luasocket",
}

build = {
  type = "builtin",
  modules = {
    escpos = "escpos.lua",
    ["connectors/linux"] = "connectors/linux.lua",
    ["connectors/network"] = "connectors/network.lua",
  },
  copy_directories = { "docs" },
}