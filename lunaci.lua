module("lunaci", package.seeall)

local log = require "lunaci.log"
local utils = require "lunaci.utils"
local config = require "lunaci.config"
local Manager = require "lunaci.Manager"
local ReportGenerator = require "lunaci.ReportGenerator"

local pl = require "pl.import_into"()



local generator = ReportGenerator()
local manager = Manager(config.ci_targets, generator)


manager:add_task("Depends", require "lunaci.tasks.dependencies")
manager:add_task("Build", require "lunaci.tasks.build")
manager:add_task("Require", require "lunaci.tasks.require")



manager:process_packages()
