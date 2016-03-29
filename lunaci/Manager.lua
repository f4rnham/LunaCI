module("lunaci.Manager", package.seeall)

local log = require "lunaci.log"
local utils = require "lunaci.utils"
local Worker = require "lunaci.Worker"

local pl = require "pl.import_into"()


local Manager = {}
Manager.__index = Manager
setmetatable(Manager, {
__call = function(self, manifest, targets, generator)
    local self = setmetatable({}, Manager)

    self.manifest = manifest
    self.targets = targets or {}
    self.tasks = {}
    self.generator = generator
    generator:set_targets(targets)

    return self
end
})


function Manager:add_task(name, func)
    local task = {name = name, call = func}
    table.insert(self.tasks, task)
    self.generator:add_task(task)
end


function Manager:get_packages()
    return pl.tablex.sort(self.manifest.packages)
end


function Manager:process_packages()
    -- Prepare report output dir
    self.generator:prepare_output_dir()

    for name, versions in self:get_packages() do
        log:info("Processing package '%s'", name)
        local worker = Worker(name, versions, self.manifest)
        worker:run(self.targets, self.tasks)

        -- Generate package reports
        self.generator:add_report(name, worker:get_report())
        self.generator:generate_package(name)
        for version in pl.tablex.sort(versions, utils.sortVersions) do
            self.generator:generate_package_version(name, version)
        end
    end

    -- Generate dashboard report
    self.generator:generate_dashboard()
end


return Manager
