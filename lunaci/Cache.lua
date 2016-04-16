module("lunaci.Cache", package.seeall)

local log = require "lunaci.log"
local utils = require "lunaci.utils"
local config = require "lunaci.config"

local pl = require "pl.import_into"()


local Cache = {}
Cache.__index = Cache
setmetatable(Cache, {
__call = function(self)
    local self = setmetatable({}, Cache)

    self.manifest = nil
    self.targets = {}
    self.tasks = {}
    self.reports = {}
    self.latest = {}
    self.specs = {}

    return self
end
})


-- Load cache from files.
function Cache:load()
    -- Load manifest cache
    if pl.path.exists(config.cache.manifest) then
        self.manifest = pl.pretty.read(pl.file.read(config.cache.manifest)) or nil
    end

    -- Load reports cache
    if pl.path.exists(config.cache.reports) then
        local out = pl.pretty.read(pl.file.read(config.cache.reports)) or {}
        if out.targets then
            self.targets = out.targets
        end
        if out.tasks then
            self.tasks = out.tasks
        end
        if out.reports then
            self.reports = out.reports
        end
        if out.latest then
            self.latest = out.latest
        end
        if out.specs then
            self.specs = out.specs
        end
    end
end


-- Save cache to file
function Cache:persist()
    -- Create cache directory if doesn't exist
    if not pl.path.exists(config.cache.path) then
        local ok, err = pl.dir.makepath(config.cache.path)
        if not ok then
            error("Could not create cache directory: " .. err)
        end
    end

    pl.file.write(config.cache.manifest, pl.pretty.write(self.manifest, ''))

    local reports = {
        targets = self.targets or {},
        tasks = self.tasks or {},
        reports = self.reports or {},
        latest = self.latest or {},
        specs = self.specs or {},
    }
    pl.file.write(config.cache.reports, pl.pretty.write(reports, '  '))
end


function Cache:set_manifest(manifest)
    self.manifest = manifest
end


-- TODO
function Cache:set_targets(targets)
    -- noop at this point
end


-- TODO
function Cache:add_task(task)
    -- noop at this point
end


-- Add a table of reports to cache
function Cache:add_reports(reports)
    for name, report in pairs(reports) do
        self:add_report(name, report)
    end
end


-- Add report output to cache
function Cache:add_report(name, report)
    -- Add latest package version string
    local latest, ver = report:get_latest()
    if ver and (not self.latest[name] or utils.sortVersions(ver, self.latest[name])) then
        self.latest[name] = ver

        -- Add latest spec
        self.specs[name] = latest.package.spec
    end

    local output = pl.tablex.deepcopy(report:get_output())

    -- Remove full task outputs, leave only summaries
    for _, out in pairs(output) do
        out.package = nil
        for _, target in pairs(out.targets) do
            for _, task in pairs(target.tasks) do
                task.output = nil
            end
        end
    end
    if not self.reports[name] then
        self.reports[name] = output
    else
        for ver, out in pairs(output) do
            self.reports[name][ver] = out
        end
    end
end


function Cache:get_report(name)
    return self.reports[name]
end


function Cache:get_spec(name)
    return self.specs[name]
end


function Cache:get_version(name, ver)
    return self.reports[name] and self.reports[name][ver] or nil
end


-- Get latest versions reports
function Cache:get_latest()
    local reports = {}
    for name, report in pairs(self.reports) do
        local latest = self.latest[name]
        reports[name] = self.reports[name][latest]
    end

    return reports
end


return Cache
