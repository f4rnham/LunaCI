module("lunaci.ReportGenerator", package.seeall)

local config = require "lunaci.config"
local log = require "lunaci.log"

local pl = require "pl.import_into"()


local ReportGenerator = {}
ReportGenerator.__index = ReportGenerator

setmetatable(ReportGenerator, {
    __call = function (class, ...)
        return class.new(...)
    end,
})


function ReportGenerator.new()
    return setmetatable({}, ReportGenerator)
end


return ReportGenerator
