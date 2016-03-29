module("lunaci.ReportGenerator", package.seeall)

local log = require "lunaci.log"
local utils = require "lunaci.utils"
local config = require "lunaci.config"

local pl = require "pl.import_into"()
local pl_template = require "pl.template"



local ReportGenerator = {}
ReportGenerator.__index = ReportGenerator
setmetatable(ReportGenerator, {
__call = function(self)
    local self = setmetatable({}, ReportGenerator)

    self.reports = {}
    self.targets = {}
    self.tasks = {}

    return self
end
})


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
    tpl = pl.path.abspath(tpl)
    pl.utils.assert_arg(1, tpl, "string", pl.path.exists, "does not exist")

    local tpl_content = pl.file.read(tpl)
    local default_functions = {
        pairs = pairs,
        sort = pl.tablex.sort,
        sort_version = function(i) return pl.tablex.sort(i, utils.sortVersions) end,
        result2class = function(s) return (s and 'success' or (s == nil and 'warning' or 'danger')) end,
        result2msg = function(s) return (s and 'OK' or (s == nil and 'N/A' or 'Fail')) end,
        ucfirst = function(s) return (s:gsub("^%l", string.upper)) end,
        date = os.date,
    }

    local vars = pl.tablex.merge(env, default_functions, true)

    local tpl_output, err = pl_template.substitute(tpl_content, vars)

    if err then
        log:error(err)
        return nil, err
    end

    return pl.file.write(pl.path.abspath(output_file), tpl_output)
end


function ReportGenerator:generate_dashboard()
    local tpl_file = config.templates.dashboard_file
    local output_file = pl.path.join(config.templates.output_path, config.templates.output_dashboard)

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
    local output_file = pl.path.join(config.templates.output_path, config.templates.output_package:format(name))

    local env = {
        targets = self.targets,
        tasks = self.tasks,
        package = self.reports[name],
    }
    utils.force_makepath(pl.path.dirname(output_file))
    return self:output_file(tpl_file, env, output_file)
end


function ReportGenerator:generate_package_version(name, version)
    local tpl_file = config.templates.version_file
    local output_file = pl.path.join(config.templates.output_path, config.templates.output_version:format(name, version))

    local env = {
        targets = self.targets,
        tasks = self.tasks,
        package = self.reports[name]:get_version(version),
    }
    utils.force_makepath(pl.path.dirname(output_file))
    return self:output_file(tpl_file, env, output_file)
end


function ReportGenerator:prepare_output_dir()
    -- Make directory structure to output path
    utils.force_makepath(config.templates.output_path)

    -- Copy assets
    local asset_out = pl.path.join(config.templates.output_path, pl.path.basename(config.templates.asset_path))
    utils.force_makepath(asset_out)

    local root = pl.path.abspath(config.templates.asset_path)
    for _, file in pairs(pl.dir.getfiles(root)) do
        local ok = pl.dir.copyfile(file, pl.path.join(asset_out, pl.path.basename(file)))
        if not ok then
            log:warn("Failed to copy asset file '%s'.", file)
        end
    end

    return true
end



return ReportGenerator
