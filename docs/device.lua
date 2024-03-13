--[[--
 Devices connectors
 @classmod device
 @author Sodomon <sodomon2@gmail.com>
]]

local device = {}

--- Open the printer device
-- @string device load module (if linux) or load ip (if network)
-- @usage device:connector("/dev/usb/lp0") or device:connector("192.168.100.91")
-- @todo Currently there are only two connectors supported, linux connectors and network connectors.
function device:connector(device)
end

--- Write to Printer device.
-- This method is specifically used by escpos to write directly to the printer.
-- @string str string to write to the printer
function device:write(str)
end

--- Close Printer device
-- @usage device:close()
function device:close()
end

return device