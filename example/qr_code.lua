-- Port of https://github.com/mike42/escpos-php/blob/development/example/qr-code.php
local escpos  = require("escpos")
local testStr = "Testing 123"

escpos:connector_type("linux") -- type linux or network
device:connector("/dev/usb/lp0")

function title(str)
  escpos:selectPrintMode(escpos.MODE_DOUBLE_HEIGHT | escpos.MODE_DOUBLE_WIDTH)
  escpos:text(str)
  escpos:feed(1)
  escpos:selectPrintMode(escpos.MODE_FONT_A)
end

-- Most simple example
escpos:setJustification(escpos.JUSTIFY_LEFT)
title("QR code demo")
escpos:print_qrcode(testStr)
escpos:set_text_size(1,1)
escpos:text("Most simple example")
escpos:feed(1)

-- Demo that alignment is the same as text
escpos:setJustification(escpos.JUSTIFY_CENTER)
escpos:print_qrcode(testStr)
escpos:text("Same example, centred")
escpos:setJustification(escpos.JUSTIFY_LEFT)
escpos:feed(1)

-- Demo of numeric data being packed more densly
title("Data encoding")
test = {
    ["Numeric"] = "0123456789012345678901234567890123456789",
    ["Alphanumeric"] = "abcdefghijklmnopqrstuvwxyzabcdefghijklmn",
    ["Binary"] = string.rep("\0", 40)
}

for types, data in pairs(test) do
  escpos:print_qrcode(data)
  escpos:text(types)
  escpos:feed(1)
end

-- Demo of error correction
title("Error correction")
err_co = {
  ["L"]  = escpos.QR_ERR_CO_LEVEL_L,
  ["M"]  = escpos.QR_ERR_CO_LEVEL_M,
  ["Q"]  = escpos.QR_ERR_CO_LEVEL_Q,
  ["H"]  = escpos.QR_ERR_CO_LEVEL_H
}

for name, ec in pairs(err_co) do
  escpos:print_qrcode(testStr, ec)
  escpos:text("Error correction " .. name)
  escpos:feed(2)
end

-- Change size
title("Pixel size")
sizes  = {
  [1]  = "(minimum)",
  [2]  = "",
  [3]  = "(default)",
  [4]  = "",
  [5]  = "",
  [10] = "",
  [16] = "(maximum)"
}

for size, name in pairs(sizes) do
  escpos:print_qrcode(testStr, escpos.QR_ERR_CO_LEVEL_L, size)
  escpos:text("Pixel size " .. size .. name)
  escpos:feed(2)
end

-- Change model
title("QR model")
models = {
  ["QR Model 1"] = escpos.QR_MODEL_1,
  ["QR Model 2 (default)"] = escpos.QR_MODEL_2,
  ["Micro QR code\n(not supported on all printers)"] = escpos.QR_MICRO
}

for name, model in pairs(models) do
  escpos:print_qrcode(testStr, escpos.QR_ERR_CO_LEVEL_L, 3, model)
  escpos:text(name)
  escpos:feed(2)
end
device:close()