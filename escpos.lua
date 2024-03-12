#!/usr/bin/lua5.4

--[[--
 LUA library for printing to ESC/POS-compatible thermal printers.
 @module escpos
 @author Sodomon <sodomon2@gmail.com>, Máster Vitronic <mastervitronic@gmail.com>
 @license MIT
 @copyright 2024
]]

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

escpos.COLOR_1            = 0   -- Use the first color (usually black)
escpos.COLOR_2            = 1   -- Use the second color (usually red or blue)

escpos.width              = 32  -- Width of paper (default 32, ticket)
escpos.BARCODE_TEXT_NONE  = 0   -- does not show the barcode text
escpos.BARCODE_TEXT_ABOVE = 1   -- shows barcode text at the top of the page
escpos.BARCODE_TEXT_BELOW = 2   -- displays barcode text at the bottom

escpos.JUSTIFY_LEFT       = 0   -- Justify content to left (default)
escpos.JUSTIFY_CENTER     = 1   -- Justify content to center
escpos.JUSTIFY_RIGHT      = 2   -- Justify content to right

escpos.MODE_FONT_A        = 0   -- Use Font A
escpos.MODE_FONT_B        = 1   -- Use Font B
escpos.MODE_EMPHASIZED    = 8   -- Use text emphasis
escpos.MODE_DOUBLE_HEIGHT = 16  -- Use double height text
escpos.MODE_DOUBLE_WIDTH  = 32  -- Use double width text
escpos.MODE_UNDERLINE     = 128 -- User Underline text

escpos.QR_ERR_CO_LEVEL_L  = 0   -- QR Code error code level L
escpos.QR_ERR_CO_LEVEL_M  = 1   -- QR Code error code level M
escpos.QR_ERR_CO_LEVEL_Q  = 2   -- QR Code error code level Q
escpos.QR_ERR_CO_LEVEL_H  = 3   -- QR Code error code level H

escpos.QR_MODEL_1         = 1   -- Indicates QR model 1
escpos.QR_MODEL_2         = 2   -- Indicates QR model 2
escpos.QR_MICRO           = 3   -- Indicates QR model 3(micro)

escpos.CUT_FULL           = 65  -- Complete paper cut
escpos.CUT_PARTIAL        = 66  -- Partial paper cut

--- Define the connector for devices
-- @param types linux or network
-- @usage escpos:connector_type("linux")
function escpos:connector_type(types)
  if types == "linux" then
    device = require("connectors.linux")
  elseif types == "network" then
    device = require("connectors.network")
  end
end

--- Aligns two columns from 2 strings.
-- @param col1 string
-- @param col2 string
-- @usage escpos:two_columns("TITLE", "SUBTITLE")
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

--- Aligns three columns from 3 strings.
-- @param col1 string
-- @param col2 string
-- @param col3 string
-- @usage escpos:three_columns("TITLE", "SUBTITLE", "COMMENT")
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
  device:write(GS .. "(k" .. header .. cn .. fn .. m .. data)
end

--- Defines the space between lines.
-- @int height integer
-- @usage escpos:set_line_spacing(4)
function escpos:set_line_spacing(height)
  if height == nil then
    device:write(ESC .. "2");
  end
  device:write(ESC .. "3" .. string.char(height));
end

function escpos:setPrintLeftMargin(margin)
  device:write(GS .. 'L' .. intLowHigh(margin, 2));
end

function escpos:setPrintWidth(width)
  device:write(GS .. 'W' .. intLowHigh(self.width, 2));
end

--[[--
  Defines the type of print mode.
  @param mode modes available for use:
    escpos.MODE_FONT_A
    escpos.MODE_FONT_B
    escpos.MODE_EMPHASIZED
    escpos.MODE_DOUBLE_HEIGHT
    escpos.MODE_DOUBLE_WIDTH
    escpos.MODE_UNDERLINE

  @usage escpos:selectPrintMode(escpos.MODE_UNDERLINE)
]]
function escpos:selectPrintMode(mode)
  device:write(ESC .. "!" .. string.char(mode))
end

--[[--
  Defines the color to use (only if the printer supports color).
  @param color Valid colors:
    escpos.COLOR_1
    escpos.COLOR_2

  @usage escpos:set_color(escpos.COLOR_2)
]]
function escpos:set_color(color)
  device:write(ESC .. "r" .. string.char(color))
end

--- Define the text size.
-- @int widthMultiplier
-- @int heightMultiplier
-- @usage escpos:set_text_size(3, 3)
function escpos:set_text_size(widthMultiplier, heightMultiplier)
  local c = math.pow(2, 4) * (widthMultiplier - 1) + (heightMultiplier - 1)
  device:write(ESC .. "!" .. string.char(c))
end

--- Defines the height of the barcode.
-- @int height
-- @usage escpos:setBarcodeHeight(4)
function escpos:setBarcodeHeight(height)
  device:write(GS .. "h" .. string.char(height))
end

--- Defines the width of the barcode.
-- @int width
-- @usage escpos:setBarcodeWidth(7)
function escpos:setBarcodeWidth(width)
  device:write(GS .. "w" .. string.char(width))
end

--[[--
  Defines the position of the barcode content.
  @param position avaliable position:
    escpos.BARCODE_TEXT_NONE (does not show the text)
    escpos.BARCODE_TEXT_ABOVE (shows text at the top of the page)
    escpos.BARCODE_TEXT_BELOW (displays text at the bottom)

  @usage escpos:setBarcodeTextPosition(escpos.BARCODE_TEXT_BELOW)
]]
function escpos:setBarcodeTextPosition(position)
  device:write(GS .. "H" .. string.char(position))
end

--[[--
  Creation of the barcode.
  @param _type types of barcodes: upca, upce, jan13, jan8, code39, itf, codabar,
  code93, code128
  @string str content of the barcode

  @usage escpos:barcode("code128", "HELLO WORLD!")
]]
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
    device:write(('%sk%c%c%s'):format(
      GS, code, (str):len(), str
    ))
  else
    print("Error with barcode type please select valid type")
  end

end

--- Defines whether Emphasis will be activated.
-- @bool on true(activate) or false(deactivate)
-- @usage escpos:setEmphasis(true)
function escpos:setEmphasis(on)
  local r = (on==true) and string.char(1) or string.char(0)
  device:write(ESC .. "E".. r)
end

--[[--
  Define the type of justification to use.
  @param justification Types of justification:
    escpos.JUSTIFY_LEFT
    escpos.JUSTIFY_CENTER
    escpos.JUSTIFY_RIGHT
  @usage escpos:setJustification(escpos.JUSTIFY_CENTER)
]]
function escpos:setJustification(justification)
  device:write(ESC .. "a" .. string.char(justification))
end

--[[--
  Define what type of font to use.
  @param font Type of fonts:
    escpos.FONT_A (escpos.MODE_FONT_A)
    escpos.FONT_B (escpos.MODE_FONT_B)
  @usage escpos:setFont(escpos.MODE_FONT_A)
]]
function escpos:setFont(font)
  device:write(ESC .. "M" .. string.char(font))
end

--- Send a feed.
-- @int nl
-- @usage escpos:feed(2)
function escpos:feed(nl)
  device:write(ESC .. "d" .. string.char(nl))
end

--- Send a text with line break.
-- @string text
-- @usage escpos:text("HELLO WOLRD!!")
function escpos:text(text)
  device:write(text .. "\n")
end



--[[--
  Print the given data as a QR code on the printer.
  @string content the content of the code
  @param err_co QR error-correction level to use:
    escpos.QR_ERR_CO_LEVEL_L
    escpos.QR_ERR_CO_LEVEL_M
    escpos.QR_ERR_CO_LEVEL_Q
    escpos.QR_ERR_CO_LEVEL_H
  @int size Pixel size to use. must be from 1 to 16 (default 3).
  @param model Define the QR code model to use.
    escpos.QR_MODEL_1
    escpos.QR_MODEL_2
    escpos.QR_MICRO
  @usage escpos:print_qrcode("QR TESTING", escpos.QR_ERR_CO_LEVEL_M, 4, escpos.QR_MODEL_2)
]]
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

--[[--
  Cut the paper.
  @param mode cut modes:
    escpos.CUT_FULL (default)
    escpos.CUT_PARTIAL
  @int lines integer
]]
function escpos:cut(mode, lines)
  local mode = mode or escpos.CUT_FULL
  local lines = lines or 3
  device:write(GS .. "V" .. string.char(mode) .. string.char(lines));
end

return escpos
