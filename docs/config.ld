-- Config file for ldoc
project = "lua-escpos"
description = "Lua library for ESC/POS-compatible thermal printers"
dir = "docs" -- for compatibility with github pages

format='discount'
-- backtick_references=false
file={
    '../escpos.lua'
}
readme='../README.md'
style='!pale'
kind_names={topic='Manual',script='Programs'}
examples = {
    '../example/connector.lua',
    '../example/example.lua',
    '../example/qr_code.lua'
}
