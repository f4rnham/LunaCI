module("lunaci.Worker", package.seeall)

local log = require "lunaci.log"
local utils = require "lunaci.utils"
local config = require "lunaci.config"
local PackageReport = require "lunaci.PackageReport"

local Package = require "rocksolver.Package"

local pl = require "pl.import_into"()


local Worker = {}
Worker.__index = Worker
setmetatable(Worker, {
__call = function(self, name, versions, manifest)
    pl.utils.assert_string(1, name)
    pl.utils.assert_arg(2, versions, "table")
    pl.utils.assert_arg(3, manifest, "table")
    local self = setmetatable({}, Worker)

    self.package_name = name
    self.package_versions = versions
    self.manifest = manifest
    self.report = PackageReport(name)

    return self
end
})


-- Run the worker on all the given targets and tasks.
function Worker:run(targets, tasks)
    pl.utils.assert_arg(1, targets, "table")
    pl.utils.assert_arg(2, tasks, "table")

    for version, spec in pl.tablex.sort(self.package_versions, utils.sortVersions) do
        local package = self:get_package(self.package_name, version, spec)

        for _, target in pairs(targets) do
            self:run_target(package, target, tasks)
        end
    end
end


-- Run tasks for the package on a given targets.
function Worker:run_target(package, target, tasks)
    pl.utils.assert_arg(1, package, "table")
    pl.utils.assert_arg(2, target, "table")
    pl.utils.assert_arg(3, tasks, "table")

    local continue = true
    for _, task in pairs(tasks) do
        if not continue then
            self.report:add_output(package, target, task, config.STATUS_NA, "Task chain ended.")
        else
            local ok, success, output, cont = pcall(task.call, package, target, self.manifest)

            if ok then
                -- Task run without runtime errors
                self.report:add_output(package, target, task, success, output)

                -- Task finished unsuccessfully - task chain should end
                if not cont then
                    continue = false
                end
            else
                -- Runtime error while running the task
                local msg = "Error running task: " .. success -- success contains lua error message
                log:error(msg)
                self.report:add_output(package, target, task, config.STATUS_INT, msg)
            end
        end
    end
end


-- Ge the PackageReport with the output from the runs.
function Worker:get_report()
    return self.report
end


-- TODO use LuaDist2 for this when ready
function Worker:get_package(name, version, spec)
    local path = pl.path
    local package_dir = path.join(config.tmp_dir, name, version)
    local repo = string.format(self.manifest.repo_path, name)

    -- Fetch from git - clone with depth 1 and selected tag only
    if not path.exists(path.join(package_dir, ".git", "config")) then
        utils.force_makepath(package_dir)
        utils.dir_exec(package_dir, string.format("git clone -b '%s' --depth=1 '%s' ./", version, repo))

    end

    -- Get rockspec file
    local rockspec_path = path.join(package_dir, name .. "-" .. version .. ".rockspec")
    if not path.exists(rockspec_path) then
        log:error("Could not find rockspec for " .. name .. "-" .. version .. " at " .. rockspec_path)

        return Package(name, version, spec)
    end


    -- Load rockspec from file
    local contents = pl.file.read(rockspec_path)
    local lines = pl.stringx.splitlines(contents)

    -- Remove possible hashbangs
    if lines[1]:match("^#!.*") then
        table.remove(lines, 1)
    end

    -- Load rockspec file as table
    local rockspec = pl.pretty.load(pl.stringx.join("\n", lines), nil, false)

    return Package.from_rockspec(rockspec)
end


return Worker
