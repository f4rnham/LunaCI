module("lunaci", package.seeall)

local log = require "lunaci.log"
local utils = require "lunaci.utils"
local config = require "lunaci.config"
local Manager = require "lunaci.Manager"
local ReportGenerator = require "lunaci.ReportGenerator"

local pl = require "pl.import_into"()


function fetch_manifest()
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



--local manifest, err = fetch_manifest()
local manifest = pl.pretty.read(pl.file.read(config.manifest.file))
if not manifest then
    error(err)
end

local generator = ReportGenerator()
local manager = Manager(manifest, config.ci_targets, generator)


local task_check_deps = require "lunaci.tasks.dependencies"
manager:add_task("Depends", task_check_deps)
--manager:add_task("Build", function(pkg) return config.STATUS_NA, "Building.", true end)



manager:process_packages()
--pl.pretty.dump(generator.packages)


manager:generate_reports()
