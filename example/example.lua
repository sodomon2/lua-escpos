local escpos = require("escpos")


math.randomseed(os.time())
local date = os.date("%d/%m/%Y")
local hour = os.date("%H:%M")

local items = {
  {'TOR235',15,'UND'},
  {'TOR236',15,'UND'},
  {'TOR237',15,'UND'},
  {'TOR238',15,'UND'},
  {'TOR239',15,'UND'},
  {'TOR240',1,'BOX'}
}

local total = 0
escpos.width = 30
local line_one = string.rep("=", escpos.width)
local line_two = string.rep("-", escpos.width)

escpos:connector("/dev/usb/lp0")

escpos:setJustification(escpos.JUSTIFY_CENTER)
escpos:feed(1)
escpos:text("TITLE")
escpos:text("NUMBER")
escpos:text("TEST")
escpos:text("POSTAL CODE")
escpos:text(line_one)
escpos:setJustification(escpos.JUSTIFY_LEFT)
escpos:text(escpos:two_columns("DATE: " .. date, "HOUR: " .. hour))
escpos:text(escpos:two_columns("CODE:", math.random(100000, 900000)))
escpos:text(escpos:two_columns("CLIENT:", 'John Doe'))
escpos:feed(1)
escpos:setJustification(escpos.JUSTIFY_CENTER)
escpos:text(line_two)
escpos:text("PRODUCTS")
escpos:text(line_two)
escpos:feed(1)
escpos:setJustification(escpos.JUSTIFY_LEFT)
escpos:text(escpos:three_columns("ARTICLE ", "AMOUNT", " UNIT"))
escpos:text(escpos:three_columns("-------- ", "--------", " ------"))
for idx, value in ipairs(items) do
  escpos:text(escpos:three_columns(value[1], value[2], value[3]))
  total = total + tonumber(value[2])
end
escpos:feed(1)
escpos:text(line_two)
escpos:setEmphasis(true)
escpos:text(escpos:two_columns("TOTAL UNITS: ", total))
escpos:feed(1)
escpos:setEmphasis(false)
escpos:text(line_two)
escpos:text("FOOTER EXAMPLE")
escpos:text(line_one)
escpos:feed(1)
escpos:setJustification(escpos.JUSTIFY_CENTER)
escpos:setBarcodeHeight(40)
escpos:setBarcodeWidth(2)
escpos:setBarcodeTextPosition(escpos.BARCODE_TEXT_NONE)
escpos:barcode("code128", "Approved")
escpos:feed(3)
escpos:close()