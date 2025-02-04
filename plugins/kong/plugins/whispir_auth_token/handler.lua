local http = require "ssl.https"
local ltn12 = require "ltn12"
local cjson = require "cjson.safe"

local BasePlugin = require "kong.plugins.base_plugin"

local TokenAuthHandler = BasePlugin:extend()

TokenAuthHandler.PRIORITY = 1000

local KEY_PREFIX = "whispir_auth_token"
local EXPIRES_ERR = "token expires"
local BAD_REQUEST = "400"

--- Get JWT from headers
-- @param request    ngx request object
-- @return token     JWT
-- @return err
local function extract_token(request)
  local auth_header = request.get_headers()["authorization"]
  if auth_header then
    local iterator, ierr = ngx.re.gmatch(auth_header, "\\s*[Bb]earer\\s+(.+)")
    if not iterator then
      return nil, ierr
    end
    
    local m, err = iterator()
    if err then
      return nil, err
    end
    
    if m and #m > 0 then
      return m[1]
    end
  end
end

--- Query auth server to validate token
-- @param token    Token to be validated
-- @param conf     Plugin configuration
-- @return info    Information associated with token
-- @return err
local function query_and_validate_token(token, conf)
  ngx.log(ngx.DEBUG, "get token info from: ", conf.auth_server_url)
  local response_body = {}
  local res, code, response_headers = http.request{
    url = conf.auth_server_url.."?token="..token,
    method = "GET",
    sink = ltn12.sink.table(response_body),
  }
  
  if type(response_body) ~= "table" then
    return nil, "Unexpected response"
  end
  local resp = table.concat(response_body)
  ngx.log(ngx.DEBUG, "response body: ", resp)
  
  if code ~= 200 then
    return nil, BAD_REQUEST
  end
  
  local decoded, err = cjson.decode(resp)
  if err then
    ngx.log(ngx.ERR, "failed to decode response body: ", err)
    return nil, err
  end
  
  if not decoded.exp then
    return nil, decoded.error or resp
  end

  if tonumber(decoded.exp) <= 0 then
    return nil, EXPIRES_ERR
  end

  decoded.expires_at = tonumber(decoded.exp)
  return decoded
end

function TokenAuthHandler:new()
  TokenAuthHandler.super.new(self, "whispir-token-auth")
end

function TokenAuthHandler:access(conf)
  TokenAuthHandler.super.access(self)
  
  local token, err = extract_token(ngx.req)
  if err then
    ngx.log(ngx.ERR, "failed to extract token: ", err)
    return kong.response.exit(HTTP_INTERNAL_SERVER_ERROR, {
        message = "failed to extract token"
      })
  end
  ngx.log(ngx.DEBUG, "extracted token: ", token)
  
  local ttype = type(token)
  if ttype ~= "string" then
    if ttype == "nil" then
      return kong.response.exit(401, "Missing token")
    end
    if ttype == "table" then
      return kong.response.exit(401, "Multiple tokens")
    end
      return kong.response.exit(401, "Unrecognized token")
  end
  
  local info
  info, err = query_and_validate_token(token, conf)
  
  if err then
    ngx.log(ngx.ERR, "failed to validate token: ", err)
    if EXPIRES_ERR == err then
      return kong.response.exit(401, EXPIRES_ERR)
    end
    if BAD_REQUEST == err then
      return kong.response.exit(401, "Unrecognized token")
    end
      return kong.response.exit(HTTP_INTERNAL_SERVER_ERROR, {
        message = "Unrecognized token"
      })
  end
  
  if info.expires_at < os.time() then
    return responses.send(401, EXPIRES_ERR)
  end
  ngx.log(ngx.DEBUG, "token will expire in ", info.expires_at - os.time(), " seconds")

end

return TokenAuthHandler
