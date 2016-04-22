module("lunaci.Manager", package.seeall)

local log = require "lunaci.log"
local utils = require "lunaci.utils"
local config = require "lunaci.config"
local Worker = require "lunaci.Worker"

local Package = require "rocksolver.Package"
local const = require "rocksolver.constraints"

local pl = require "pl.import_into"()

local plsort = pl.tablex.sort


-- Cache for new/updated versions of packages
local changed_version_cache = {}
setmetatable(changed_version_cache, {
    __mode = "kv"
})


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


function Manager:run()
    -- Pull fresh manifest from git
    self:get_manifest()

    -- Initialise output repository
    self:init_repository()
    self.generator:prepare_output_dir()

    -- Load cache
    self.cache:load()

    -- Run the tasks and generate reports
    local reports = self:process_packages()

    -- Update cache
    self.cache:add_reports(reports)
    self.cache:set_manifest(self.manifest)
    self.cache:persist()

    -- Publish reports to git
    self:publish_reports(reports)
end


-- Process all the packages in the manifest - run all tasks on all targets
-- and generate reports and dashboards.
function Manager:process_packages()
    local reports = {}

    local i = 0
    for name in self:get_packages() do
        local new_versions = self:get_changed_versions(name)
        if next(new_versions) ~= nil then
            local vers = {}
            log:info("Processing package '%s'", name)
            for v, a in plsort(new_versions, utils.sortVersions) do
                log:debug("New version: %s", v)
                vers[v] = a
                break
            end
            local worker = Worker(name, vers, self.manifest)
            worker:run(self.targets, self.tasks)

            -- Generate package reports
            self.generator:add_report(name, worker:get_report())
            for version in plsort(vers, utils.sortVersions) do
                self.generator:generate_package_version(name, version)
            end
            -- Generate package summary report
            self.generator:generate_package(name)

            reports[name] = worker:get_report()
        end

        i = i + 1
        if i > 20 then
            break
        end
    end

    -- Generate dashboard report
    self.generator:generate_dashboard()

    return reports
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


function Manager:init_repository()
    local path = pl.path
    local cf = config.output
    local repo = cf.repo
    utils.force_makepath(repo)

    -- Init git repository if not ready yet
    if not path.exists(path.join(repo, ".git", "config")) then
        local ok, code, out, err = utils.dir_exec(repo, "git init -q")
        if not ok then error("Could not init repository: " .. err) end

        utils.dir_exec(repo, "git config --local user.name '" .. cf.git_user_name .. "'")
        utils.dir_exec(repo, "git config --local user.email '" .. cf.git_user_mail .. "'")

        local ok, code, out, err = utils.dir_exec(repo, "git remote add '" .. cf.remote_name .. "' '" .. cf.remote .. "'")
        if not ok then error("Could not add remote: " .. err) end

        utils.dir_exec(repo, "git checkout -b '" .. cf.branch .. "'")
    end
end


function Manager:publish_reports(reports)
    -- Skip if no changes.
    if next(reports) == nil then
        return
    end

    -- Prepare commit message
    local commit_msg = pl.stringio.create()
    commit_msg:write("Update reports.\n\nNew/updated packages:\n")
    for name, report in plsort(reports) do
        for version in plsort(report.outputs, utils.sortVersions) do
            commit_msg:write(changed_packages, name .. " " .. version .. "\n")
        end
    end

    local commit_msg_file = pl.path.tmpname()
    print("Temporary file", commit_msg_file)
    pl.file.write(commit_msg_file, commit_msg:value())

    local cf = config.output
    local repo = cf.repo
    utils.dir_exec(repo, "git add -A")
    utils.dir_exec(repo, "git commit -F '" .. commit_msg_file .. "'")

    pl.file.delete(commit_msg_file)

    local ok, code, out, err = utils.dir_exec(repo, "git push '" .. cf.remote_name .. "' '" .. cf.branch .. "'")
    if not ok then
        error("Could not push to remote: " .. err)
    end
end


return Manager
