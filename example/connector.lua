local escpos = require("escpos")

-- Open the connector device
escpos:connector_type("linux") -- type linux or network
device:connector("/dev/usb/lp0")

-- Set text to center and print message
escpos:setJustification(escpos.JUSTIFY_CENTER)
escpos:text("Hello World!! from lua")
escpos:feed(1)

-- Close the connector device
device:close()