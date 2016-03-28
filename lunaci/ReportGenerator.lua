module("lunaci.ReportGenerator", package.seeall)

local config = require "lunaci.config"
local log = require "lunaci.log"
local PackageReport = require "lunaci.PackageReport"

local pl = require "pl.import_into"()
local template = require "pl.template"

local const = require "rocksolver.constraints"


local ReportGenerator = {}
ReportGenerator.__index = ReportGenerator

setmetatable(ReportGenerator, {
    __call = function (class, ...)
        return class.new(...)
    end,
})


function ReportGenerator.new()
    local self = setmetatable({}, ReportGenerator)

    self.reports = {}
    self.targets = {}
    self.tasks = {}

    return self
end


function ReportGenerator:set_targets(targets)
    self.targets = targets
end


function ReportGenerator:add_task(task)
    table.insert(self.tasks, task.name)
end


function ReportGenerator:add_report(package, report)
    self.reports[package] = report
end


function ReportGenerator:output_file(tpl, env, output_file)
    -- TODO add checks: tpl exists, output_dir exists
    local tpl_content = pl.file.read(pl.path.abspath(tpl))
    local default_functions = {
        pairs = pairs,
        sort = pl.tablex.sort,
        sort_version = function(i) return pl.tablex.sort(i, const.compareVersions) end,
        result2class = function(s) return (s and 'success' or (s == nil and 'warning' or 'danger')) end,
        result2msg = function(s) return (s and 'OK' or (s == nil and 'N/A' or 'Fail')) end,
        ucfirst = function(s) return (s:gsub("^%l", string.upper)) end,
        date = os.date,
    }

    local vars = pl.tablex.merge(env, default_functions, true)

    local tpl_output, err = template.substitute(tpl_content, vars)

    if err then
        log:error(err)
        return nil, err
    end

    return pl.file.write(pl.path.abspath(output_file), tpl_output)
end


function ReportGenerator:generate_dashboard()
    local tpl_file = config.templates.dashboard_file
    local output_file = pl.path.join(config.templates.output_path, config.templates.output_dashboard_file)

    local env = {
        stats = {
            packages = pl.tablex.size(self.reports),
            -- passing = 72,
            -- failing = 28,
        },
        targets = self.targets,
        tasks = self.tasks,
        packages = self.reports
    }
    return self:output_file(tpl_file, env, output_file)
end


function ReportGenerator:generate_package(name)
    local tpl_file = config.templates.package_file
    local output_file = pl.path.join(config.templates.output_path, config.templates.output_package_file:format(name))

    local env = {
        targets = self.targets,
        tasks = self.tasks,
        package = self.reports[name],
    }
    pl.dir.makepath(pl.path.dirname(output_file))
    return self:output_file(tpl_file, env, output_file)
end


function ReportGenerator:generate_package_version(name, version)
    local tpl_file = config.templates.version_file
    local output_file = pl.path.join(config.templates.output_path, config.templates.output_version_file:format(name, version))

    local env = {
        targets = self.targets,
        tasks = self.tasks,
        package = self.reports[name]:get_version(version),
    }
    pl.dir.makepath(pl.path.dirname(output_file))
    return self:output_file(tpl_file, env, output_file)
end



return ReportGenerator
