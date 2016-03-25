module("lunaci.log", package.seeall)

local config = require "lunaci.config"

local logging = require "logging"
require "logging.file"
require "logging.console"

local logger

if(config.logging.output == 'console') then
    logger = logging.console("%level %message\n")
else
    logger = logging.file(config.logging.file, config.logging.date_format)
end

if(config.logging.level ~= logging.DEBUG) then
    logger:setLevel(config.logging.level)
end

return logger
