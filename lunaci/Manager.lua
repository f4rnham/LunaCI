module("lunaci.Manager", package.seeall)

local log = require "lunaci.log"
local utils = require "lunaci.utils"
local config = require "lunaci.config"
local Worker = require "lunaci.Worker"

local pl = require "pl.import_into"()


local Manager = {}
Manager.__index = Manager
setmetatable(Manager, {
__call = function(self, targets, generator)
    pl.utils.assert_arg(2, targets, "table")
    pl.utils.assert_arg(3, generator, "table")
    local self = setmetatable({}, Manager)

    self.targets = targets or {}
    self.tasks = {}
    self.generator = generator
    generator:set_targets(targets)

    return self
end
})


function Manager:fetch_manifest()
    log:info("Fetching manifest")

    if pl.path.exists(config.manifest.file) then
        return pl.pretty.read(pl.file.read(config.manifest.file))
    end

    local ok, err = utils.git_clone(config.manifest.repo, config.manifest.path)
    if not ok then return nil, err end

    if not pl.path.exists(config.manifest.file) then
        return nil, "Manifest file '" .. config.manifest.file .. "' not found."
    end

    return pl.pretty.read(pl.file.read(config.manifest.file))
end


function Manager:get_manifest()
    if self.manifest then
        return self.manifest
    end
    self.manifest = self:fetch_manifest()
    return self.manifest
end


function Manager:get_last_manifest()
    if self.last_manifest then
        return self.last_manifest
    end
    if pl.path.exists(config.manifest.last_file) then
        self.last_manifest = pl.pretty.read(pl.file.read(config.manifest.last_file))
        return self.last_manifest
    end
    return nil
end


function Manager:add_task(name, func)
    pl.utils.assert_string(1, name)
    pl.utils.assert_arg(2, func, "function")

    local task = {name = name, call = func}
    table.insert(self.tasks, task)
    self.generator:add_task(task)
end


function Manager:get_packages()
    return pl.tablex.sort(self.manifest.packages)
end


-- TODO instead of all, return only new versions.
function Manager:package_changed(name)
    if not self.last_manifest then
        return self.manifest.packages[name]
    end
    local current = self.manifest.packages[name]
    local last = self.last_manifest.packages[name]

    if pl.tablex.deepcompare(current, last) then
        return nil
    end
    return current
end


function Manager:process_packages()
    --TODO move elsewhere
    self:get_manifest()
    self:get_last_manifest()

    -- Prepare report output dir
    self.generator:prepare_output_dir()

    for name in self:get_packages() do
        log:info("Processing package '%s'", name)
        local versions = self:package_changed(name)
        if not versions then
            log:debug("No changes in package '%s'", name)
        else
            local worker = Worker(name, versions, self.manifest)
            log:debug("New versions for package '%s':", name)
            for v in pairs(versions) do
                log:debug("- %s", v)
            end
            worker:run(self.targets, self.tasks)

            -- Generate package reports
            self.generator:add_report(name, worker:get_report())
            for version in pl.tablex.sort(versions, utils.sortVersions) do
                self.generator:generate_package_version(name, version)
            end
            self.generator:generate_package(name)
        end
    end

    -- Generate dashboard report
    self.generator:generate_dashboard()


    -- TODO move elsewhere
    pl.file.write(pl.path.abspath(config.manifest.last_file), pl.pretty.write(self.manifest))
end


return Manager
