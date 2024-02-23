local escpos = {}

-- https://lunarmodules.github.io/luasocket/
local socket = require("socket")

-- Open the printer device
function escpos:connector(address)
  self.printer, err = socket.connect(address, 9100)
  if err then
    return false, err
  end
  return true
end

-- Write to Printer device
function escpos:write(message)
  self.printer:send(message)
end

-- Close Printer device
function escpos:close()
  self.printer:close()
end

return escpos