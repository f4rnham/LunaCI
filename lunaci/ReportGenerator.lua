module("lunaci.ReportGenerator", package.seeall)

local log = require "lunaci.log"
local utils = require "lunaci.utils"
local config = require "lunaci.config"

local pl = require "pl.import_into"()
local plsort = pl.tablex.sort


local ReportGenerator = {}
ReportGenerator.__index = ReportGenerator
setmetatable(ReportGenerator, {
__call = function(self, cache)
    pl.utils.assert_arg(2, cache, "table")
    local self = setmetatable({}, ReportGenerator)

    self.reports = {}
    self.targets = {}
    self.tasks = {}

    self.cache = cache

    return self
end
})


function ReportGenerator:set_targets(targets)
    pl.utils.assert_arg(1, targets, "table")
    self.targets = targets
end


function ReportGenerator:add_task(task)
    pl.utils.assert_arg(1, task, "table")
    table.insert(self.tasks, task.name)
end


function ReportGenerator:add_report(package, report)
    pl.utils.assert_string(1, package)
    pl.utils.assert_arg(2, report, "table")
    self.reports[package] = report
end


function ReportGenerator:output_file(tpl, env, output_file)
    pl.utils.assert_arg(1, tpl, "string", pl.path.exists, "does not exist")
    pl.utils.assert_arg(2, env, "table")
    pl.utils.assert_string(3, output_file)

    tpl = pl.path.abspath(tpl)

    local tpl_content = pl.file.read(tpl)
    local default_functions = {
        e = utils.escape_html,
        urlsafe = utils.escape_urlsafe,
        pairs = pairs,
        sort = plsort,
        ucfirst = function(s) return (s:gsub("^%l", string.upper)) end,
        date = os.date,
    }

    local vars = pl.tablex.merge(env, default_functions, true)
    local pl_template = require "pl.template"

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

    local packages, count = self:get_packages_latest()
    local env = {
        stats = {
            packages = count,
            -- passing = 72,
            -- failing = 28,
        },
        targets = self.targets,
        tasks = self.tasks,
        packages = packages
    }
    return self:output_file(tpl_file, env, output_file)
end


function ReportGenerator:generate_package(name)
    pl.utils.assert_string(1, name)
    local safename = utils.escape_urlsafe(name)
    local tpl_file = config.templates.package_file
    local output_file = pl.path.join(config.templates.output_path, config.templates.output_package:format(safename))

    local env = {
        targets = self.targets,
        tasks = self.tasks,
        package_name = name,
        package_output = self:get_package_outputs(name),
    }
    utils.force_makepath(pl.path.dirname(output_file))
    return self:output_file(tpl_file, env, output_file)
end


function ReportGenerator:generate_package_version(name, version)
    pl.utils.assert_string(1, name)
    pl.utils.assert_string(2, version)
    local safename = utils.escape_urlsafe(name)
    local safeversion = utils.escape_urlsafe(version)
    local tpl_file = config.templates.version_file
    local output_file = pl.path.join(config.templates.output_path, config.templates.output_version:format(safename, safeversion))

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


function ReportGenerator:get_package_outputs(name)
    local cached = self.cache:get_report(name) or {}
    local new = self.reports[name]:get_output()
    local merged = pl.tablex.merge(cached, new, true)
    return plsort(merged, utils.sortVersions)
end


function ReportGenerator:get_packages_latest()
    local cached = self.cache:get_latest() or {}
    local new = {}

    for name, report in pairs(self.reports) do
        new[name] = report:get_latest()
    end
    local merged = pl.tablex.merge(cached, new, true)
    return plsort(merged), pl.tablex.size(merged)
end


return ReportGenerator
