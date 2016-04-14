module("lunaci.Manager", package.seeall)

local log = require "lunaci.log"
local utils = require "lunaci.utils"
local config = require "lunaci.config"
local Worker = require "lunaci.Worker"

local Package = require "rocksolver.Package"
local const = require "rocksolver.constraints"

local pl = require "pl.import_into"()

local plsort = pl.tablex.sort


local Manager = {}
Manager.__index = Manager
setmetatable(Manager, {
__call = function(self, targets, generator, cache)
    pl.utils.assert_arg(2, targets, "table")
    pl.utils.assert_arg(3, generator, "table")
    pl.utils.assert_arg(4, cache, "table")
    local self = setmetatable({}, Manager)

    self.targets = targets or {}
    self.tasks = {}
    self.generator = generator
    generator:set_targets(targets)

    self.cache = cache

    return self
end
})


-- Fetch manifest from git manifest repo
function Manager:fetch_manifest()
    log:info("Fetching manifest")

    if pl.path.exists(pl.path.join(config.manifest.path, ".git", "config")) then
        local ok, err = utils.git_pull(config.manifest.path, 'origin', 'master')
        if not ok then
            return nil, "Pull on manifest repository failed: " .. err
        end
        if pl.path.exists(config.manifest.file) then
            return pl.pretty.read(pl.file.read(config.manifest.file))
        else
            return nil, "Manifest file '" .. config.manifest.file .. "' not found."
        end
    end

    local ok, err = utils.git_clone(config.manifest.repo, config.manifest.path)
    if not ok then return nil, err end

    if not pl.path.exists(config.manifest.file) then
        return nil, "Manifest file '" .. config.manifest.file .. "' not found."
    end

    return pl.pretty.read(pl.file.read(config.manifest.file))
end


-- Returns manifest, fetching it if not yet loaded.
function Manager:get_manifest()
    if self.manifest then
        return self.manifest
    end
    self.manifest, err = self:fetch_manifest()
    if not self.manifest then
        error("Could not fetch current manifest: " .. err)
    end
    return self.manifest
end


-- Add a new task definition to LunaCI.
-- Task should be a function/callable taking three arguments:
-- Package instance, target definition and the current manifest.
function Manager:add_task(name, func)
    pl.utils.assert_string(1, name)
    pl.utils.assert_arg(2, func, "function")

    local task = {name = name, call = func}
    table.insert(self.tasks, task)
    self.generator:add_task(task)
end


-- Get all packages sorted alphabetically. Returns an interator.
function Manager:get_packages()
    return plsort(self.manifest.packages)
end


-- Check if a package in a given version has some new/updated dependencies
-- since the last cached manifest.
function Manager:has_new_dependencies(name, ver)
    pkg = Package(name, ver, self.manifest.packages[name][ver])
    local deps = pkg:dependencies(config.platform)
    for _, dep in pairs(deps) do
        local dep_name, dep_const = const.split(dep)
        local new_dep_vers = self:get_changed_versions(dep_name) or {}
        for new_ver in pairs(new_dep_vers) do
            if not dep_const or const.constraint_satisified(new_ver, dep_const) then
                return true
            end
        end
    end
    return false
end


-- Cache for new/updated versions of packages
local changed_version_cache = {}
setmetatable(changed_version_cache, {
    __mode = "kv"
})


-- Returns a list of new or updated versions for a given package
-- since the last cached manifest. A package version is considered updated,
-- if any of its dependencies have been updated.
-- Results of this function are cached for increased performance.
function Manager:get_changed_versions(name)
    if changed_version_cache[name] then
        return changed_version_cache[name]
    end
    if not self.cache.manifest then
        return self.manifest.packages[name]
    end
    local current = self.manifest.packages[name] or {}
    local cached = self.cache.manifest.packages[name] or {}

    -- New versions of package
    local new_versions = pl.tablex.difference(current, cached) or {}

    -- Check for new versions of relevant dependencies
    for ver, spec in plsort(current, utils.sortVersions) do
        if self:has_new_dependencies(name, ver) and not new_versions[ver] then
            new_versions[ver] = spec
        end
    end
    changed_version_cache[name] = new_versions
    return new_versions
end


-- Process all the packages in the manifest - run all tasks on all targets
-- and generate reports and dashobards.
function Manager:process_packages()
    --TODO move elsewhere
    self:get_manifest()
    self.cache:load_cache()
    self.generator:prepare_output_dir()

    local cached = {}

    for name in self:get_packages() do
        log:info("Processing package '%s'", name)
        local new_versions = self:get_changed_versions(name)
        if new_versions then
            for v in plsort(new_versions, utils.sortVersions) do
                log:debug("New version: %s", v)
            end
            local worker = Worker(name, new_versions, self.manifest)
            worker:run(self.targets, self.tasks)

            -- Generate package reports
            self.generator:add_report(name, worker:get_report())
            for version in plsort(new_versions, utils.sortVersions) do
                self.generator:generate_package_version(name, version)
            end
            self.generator:generate_package(name)

            cached[name] = worker:get_report()
        end
    end

    -- Generate dashboard report
    self.generator:generate_dashboard()


    -- TODO move elsewhere
    for name, report in pairs(cached) do
        self.cache:add_report(name, report)
    end
    self.cache:set_manifest(self.manifest)

    self.cache:persist_cache()
end


return Manager
