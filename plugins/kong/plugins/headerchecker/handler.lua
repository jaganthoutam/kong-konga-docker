local BasePlugin = require "kong.plugins.base_plugin"
-- local responses = require "kong.tools.responses"
local responses = kong.response
local HeaderCheckerHandler = BasePlugin:extend()
local kong = kong

HeaderCheckerHandler.PRIORITY = 1000
HeaderCheckerHandler.VERSION = "0.1.0"

function HeaderCheckerHandler:new()
  HeaderCheckerHandler.super.new(self, "header-checker")
end

local function starts_with(str, start)
  return str:sub(1, #start) == start
end

function HeaderCheckerHandler:access(conf)
  HeaderCheckerHandler.super.access(self)
  local req_headers = kong.request.get_headers()
  local req_header_to_check = req_headers[conf.header_to_check]
  local allowed = false
  for i = 1, table.maxn(conf.allowed_header_values) do
    if starts_with(req_header_to_check, conf.allowed_header_values[i]) then
      allowed = true
    end
  end
  if not allowed then
    kong.log.err("Missing required configuration for accessing this route")
    return kong.response.exit(403, "Forbidden")
  end
end

return HeaderCheckerHandler
