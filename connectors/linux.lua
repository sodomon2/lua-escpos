local escpos = {}

-- Open the printer device
function escpos:connector(device)
  self.printer, err = io.open(device, "wb")
  if err then
    return false, err
  end
  return true
end

-- Write to Printer device
function escpos:write(str)
  self.printer:write(str)
end

-- Close Printer device
function escpos:close()
  self.printer:close()
end

return escpos