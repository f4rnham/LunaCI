module("lunaci.config", package.seeall)

local path = require "pl.path"
local log = require "logging"

-- Utility function for defining task statuses
local function status(s)
    return {title = s[1], msg = s[2], class = s[3]}
end
-- Utility function for defining CI targets
local function target(t)
    return {name = t[1], compatibility = t[2], binary = t[3]}
end


-- Base data directory path
data_dir = path.abspath("data")

tmp_dir = path.join(data_dir, "tmp")


-- Manifest
manifest = {}
manifest.repo = "https://gist.github.com/efe9312e64d0e492282e.git"
manifest.path = path.join(data_dir, "manifest-repo")
manifest.file = path.join(manifest.path, "manifest-file")


-- Cache
cache = {}
cache.path = path.join(data_dir, "cache")
cache.manifest = path.join(cache.path, "manifest.cache")
cache.reports = path.join(cache.path, "reports.cache")


-- Logging
logging = {}
logging.output = "console"
logging.level = log.DEBUG
logging.file = path.join(data_dir, "logs/lunaci-%s.log")
logging.date_format = "%Y-%m-%d"


-- LunaCI Targets
targets = {
    target{"Lua 5.3", "5.3", "lua5.3/bin/lua"},
    target{"Lua 5.2", "5.2", "lua5.2/bin/lua"},
    target{"Lua 5.1", "5.1", "lua5.1/bin/lua"},
}


-- LunaCI platform defintion
platform = {"unix", "linux"}


-- Task status definitions
STATUS_OK   = status{"OK", "Success", "success"}
STATUS_FAIL = status{"Fail", "Failure", "danger"}
STATUS_NA   = status{"N/A", "Not applicable", "info"}
STATUS_INT  = status{"Internal", "Internal tooling error", "warning"}
STATUS_SKIP = status{"Skip", "Skipped", "info"}
STATUS_DEP_F = status{"DF", "Dependency caused fail", "info"}
STATUS_CE = status{"CE", "Compile error", "danger"}
STATUS_KE  = status{"KE", "Known error", "warning"}


-- Output repository
output = {}
output.repo = path.join(data_dir, "output")
output.remote = "git@github.com:LuaDist/lunaci.git"
output.remote_name = "origin"
output.branch = "gh-pages"
output.git_user_name = "LunaCI"
output.git_user_mail = "lunaci@luadist.org"


-- Templating
templates = {}
templates.path = path.abspath("templates")
templates.asset_path = path.join(templates.path, "assets")
templates.pkg_repo = "https://github.com/LuaDist2/%s"
templates.pkg_repo_version = "https://github.com/LuaDist2/%s/tree/%s"

-- Template files
templates.dashboard_file = path.join(templates.path, "dashboard.html")
templates.package_file = path.join(templates.path, "package.html")
templates.version_file = path.join(templates.path, "version.html")

-- Template output paths
templates.output_path = output.repo
templates.output_dashboard = "index.html"
templates.output_package = "packages/%s/index.html"
templates.output_version = "packages/%s/%s.html"


