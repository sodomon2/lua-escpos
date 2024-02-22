#!/usr/bin/lua5.4

--[[

  escpos.lua - LUA library for printing to ESC/POS-compatible thermal printers.

  Copyright (c) 2024, Díaz Devera Víctor <mastervitronic@gmail.com>
  Copyright (c) 2024, Díaz Urbaneja Víctor Diego Alejandro <sodomon2@gmail.com>

--]]


local escpos = {}

-- https://github.com/rrthomas/lrexlib/
local regex  = require("rex_pcre2")

local NUL   = "\x00"	 -- ASCII null control character
local LF    = "\x0a"	 -- ASCII linefeed control character
local ESC   = "\x1b"   -- ASCII escape control character
local FS    = "\x1c"	 -- ASCII form separator control character
local FF    = "\x0c"	 -- ASCII form feed control character
local GS    = "\x1d"	 -- ASCII group separator control character
local DLE   = "\x10"	 -- ASCII data link escape control character
local EOT   = "\x04"	 -- ASCII end of transmission control character

COLOR_1 = 0 -- Use the first color (usually black)
COLOR_2 = 1 -- Use the second color (usually red or blue)

escpos.width              = 32
escpos.BARCODE_TEXT_NONE  = 0
escpos.BARCODE_TEXT_ABOVE = 1
escpos.BARCODE_TEXT_BELOW = 2

escpos.JUSTIFY_LEFT       = 0
escpos.JUSTIFY_CENTER     = 1
escpos.JUSTIFY_RIGHT      = 2

escpos.MODE_FONT_A        = 0
escpos.MODE_FONT_B        = 1
escpos.MODE_EMPHASIZED    = 8
escpos.MODE_DOUBLE_HEIGHT = 16
escpos.MODE_DOUBLE_WIDTH  = 32
escpos.MODE_UNDERLINE     = 128

escpos.QR_ERR_CO_LEVEL_L  = 0
escpos.QR_ERR_CO_LEVEL_M  = 1
escpos.QR_ERR_CO_LEVEL_Q  = 2
escpos.QR_ERR_CO_LEVEL_H  = 3

escpos.QR_MODEL_1         = 1 -- Indicates QR model 1
escpos.QR_MODEL_2         = 2 -- Indicates QR model 2
escpos.QR_MICRO           = 3 -- Indicates QR model 3(micro)

local printer

-- Open the printer device
function escpos:connector(device)
  self.printer, err = io.open(device, "wb")
	if err then
		return false, err
	end
  return true
end

function escpos:write(str)
  self.printer:write(str)
end

-- Close Printer device
function escpos:close()
  self.printer:close()
end

-- Aligns two columns from 2 strings.
-- col1 = string left
-- col2 = string right
function escpos:two_columns(col1, col2)
  local args= {col1, col2}
  local result = ''

  for index,value in pairs(args) do
    result = (index == 1) and value or table.concat({
      result, value
    }, '-')
  end
  local s_r = #result
  local s_i = (escpos.width-s_r)+1

  result = string.gsub(result, '-', string.rep(" ", s_i))
  return result, #result
end

-- Aligns three columns from 3 strings.
-- col1 = string left
-- col2 = string center
-- col2 = string right
function escpos:three_columns(col1, col2, col3)
  -- Calcular longitud total de los strings sin espacios
  local total_length = string.len(col1) + string.len(col2) + string.len(col3)
  -- Calcular espacio disponible para rellenar
  local padding_length = escpos.width - total_length
  -- Calcular espacio a la izquierda del segundo string
  local left_padding = math.floor(padding_length / 2)
  -- Calcular espacio a la derecha del segundo string
  local right_padding = padding_length - left_padding
  -- Generar string centrado
  local centered_string = col1 .. string.rep(" ", left_padding) .. col2 .. string.rep(" ", right_padding) .. col3
  return centered_string
end

-- Generate two characters for a number
local function intLowHigh(input, length)
  outp = ""
  for i = 0, length, 1 do
    if i >= length then
      break
    end
    outp = table.concat({
      outp, string.char(math.floor(input % 256))
    }, '')
    input = math.floor(input / 256)
  end
  return outp
end

local function wrapperSend2dCodeData(fn, cn, data, m)
    local data, m = data, m or ''
    header = intLowHigh(string.len(data) + string.len(m) + 2, 2)
    escpos.printer:write(GS .. "(k" .. header .. cn .. fn .. m .. data)
end

-- Defines the space between lines.
-- height = integer
function escpos:set_line_spacing(height)
  if height == nil then
    self.printer:write(ESC .. "2");
  end
  escpos:write(ESC .. "3" .. string.char(height));
end

function escpos:setPrintLeftMargin(margin)
  escpos:write(GS .. 'L' .. intLowHigh(margin, 2));
end

function escpos:setPrintWidth(width)
  escpos:write(GS .. 'W' .. intLowHigh(self.width, 2));
end

-- Defines the type of print mode.
-- Modes:
--  MODE_FONT_A
--  MODE_FONT_B
--  MODE_EMPHASIZED
--  MODE_DOUBLE_HEIGHT
--  MODE_DOUBLE_WIDTH
--  MODE_UNDERLINE
function escpos:selectPrintMode(mode)
	escpos:write(ESC .. "!" .. string.char(mode))
end

-- Defines the color to use (only if the printer supports color).
-- Colors:
--  COLOR_1
--  COLOR_2
function escpos:set_color(color)
  escpos:write(ESC .. "r" .. string.char(color))
end

-- Define the text size.
-- width  = integer
-- height = integer
function escpos:set_text_size(widthMultiplier, heightMultiplier)
  local c = math.pow(2, 4) * (widthMultiplier - 1) + (heightMultiplier - 1)
  escpos:write(ESC .. "!" .. string.char(c))
end

-- Defines the height of the barcode.
-- height = integer
function escpos:setBarcodeHeight(height)
  escpos:write(GS .. "h" .. string.char(height))
end

-- Defines the width of the barcode.
-- width = integer
function escpos:setBarcodeWidth(width)
  escpos:write(GS .. "w" .. string.char(width))
end

-- Defines the position of the barcode content.
-- BARCODE_TEXT_NONE = 0 does not show the text
-- BARCODE_TEXT_ABOVE = 1 shows text at the top of the page
-- BARCODE_TEXT_BELOW = 2 displays text at the bottom
function escpos:setBarcodeTextPosition(position)
  escpos:write(GS .. "H" .. string.char(position))
end

-- Creation of the barcode.
-- id_code = code type.
-- types of barcodes:
--    1: upca
--    2: upce
--    3: jan13
--    3: jan8
--    4: code39
--    5: ift
--    6: codabar
--    7: code93
--    8: code128
-- str = content of the barcode.

function escpos:barcode(_type, str)
  local validate = {
    ['upca']   =function (str)
      return (regex.match("^[0-9]{11,12}$/", str)) , 65
    end,
    ['upce']   =function (str)
      return (regex.match("^([0-9]{6,8}|[0-9]{11,12})$", str)), 66
    end,
    ['jan13']  =function (str)
      return regex.match("^[0-9]{12,13}$/", str), 67
    end,
    ['jan8']   =function (str)
      return regex.match("^[0-9]{7,8}$/"), 68
    end,
    ['code39'] =function (str)
      return str, 69
    end,
    ['itf']    =function (str)
      return regex.match(str, "^([0-9]{2})+$/"), 70
    end,
    ['codabar']=function (str)
      return str, 71
    end,
    ['code93'] =function (str)
      return regex.match(str, "^[\\x00-\\x7F]+$/"), 72
    end,
    ['code128']=function (str)
      return regex.match(str, "^[A-Z][\\x00-\\x7F]+$"), 73
    end
  }
  -- @TODO: Add validation to receive if BarcodeB is supported by the device
  -- io.stdout:write(GS .. "k" .. string.char(code - 65) .. srt .. NUL)
  local result, code = validate[_type](str)
  if result == str then
    escpos:write(('%sk%c%c%s'):format(
      GS, code, (str):len(), str
    ))
  else
    print("Error with barcode type please select valid type")
  end

end

-- Defines whether Emphasis will be activated.
-- on = true(activate) or false(deactivate)
function escpos:setEmphasis(on)
  local r = (on==true) and string.char(1) or string.char(0)
  escpos:write(ESC .. "E".. r)
end

-- Define the type of justification to use.
-- Types of justification:
--  JUSTIFY_LEFT       = 0
--  JUSTIFY_CENTER     = 1
--  JUSTIFY_RIGHT      = 2
function escpos:setJustification(justification)
  escpos:write(ESC .. "a" .. string.char(justification))
end

-- Define what type of font to use.
-- Type of fonts:
--  FONT_A = 0
--  FONT_B = 1
--  FONT_C = 2
function escpos:setFont(font)
  escpos:write(ESC .. "M" .. string.char(font))
end

-- Send a feed.
function escpos:feed(nl)
  escpos:write(ESC .. "d" .. string.char(nl))
end

-- Send a text with line break.
function escpos:text(text)
  escpos:write(text .. "\n")
end

-- Print the given data as a QR code on the printer.
-- content = the content of the code
-- err_co  = QR error-correction level to use
-- size    = Pixel size to use. must be from 1 to 16 (default 3).
-- model   = Define the QR code model to use.
function escpos:print_qrcode(content, err_co, size, model)
  local err_co = err_co or escpos.QR_ERR_CO_LEVEL_L
  local size   = size or 3
  local model  = model or escpos.QR_MODEL_2

  cn = '1'
  wrapperSend2dCodeData(string.char(65), cn, string.char(48 + model) .. string.char(0))
  wrapperSend2dCodeData(string.char(67), cn, string.char(size))
  wrapperSend2dCodeData(string.char(69), cn, string.char(48 + err_co))
  wrapperSend2dCodeData(string.char(80), cn, content, '0')
  wrapperSend2dCodeData(string.char(81), cn, '', '0')
end


return escpos
