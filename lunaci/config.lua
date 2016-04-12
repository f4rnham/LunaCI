module("lunaci.config", package.seeall)

local path = require "pl.path"
local log = require "logging"

local function status(s)
    return {title = s[1], msg = s[2], class = s[3]}
end
local function target(t)
    return {name = t[1], compatibility = t[2], binary = t[3]}
end


data_dir = path.abspath("data")


manifest = {}
manifest.repo = "https://gist.github.com/efe9312e64d0e492282e.git"
manifest.path = path.join(data_dir, "manifest-repo")
manifest.file = path.join(manifest.path, "manifest-file")

cache = {}
cache.path = path.join(data_dir, "cache")
cache.manifest = path.join(cache.path, "manifest.cache")
cache.reports = path.join(cache.path, "reports.cache")

logging = {}
logging.output = "console"
logging.level = log.DEBUG
logging.file = path.join(data_dir, "logs/lunaci-%s.log")
logging.date_format = "%Y-%m-%d"


ci_targets = {
    target{"Lua 5.3", "5.3", "lua5.3/bin/lua"},
    target{"Lua 5.2", "5.2", "lua5.2/bin/lua"},
    target{"Lua 5.1", "5.1", "lua5.1/bin/lua"},
    target{"LuaJIT 2.0.3",  "5.1.5", "luaJIT/bin/luajit"},
}


STATUS_OK   = status{"OK", "Success", "success"}
STATUS_FAIL = status{"Fail", "Failure", "danger"}
STATUS_NA   = status{"N/A", "Not applicable", "info"}
STATUS_INT  = status{"Internal", "Internal tooling error", "warning"}


platform = {"unix", "linux"}


templates = {}
templates.path = path.abspath("templates")
templates.asset_path = path.join(templates.path, "assets")

templates.dashboard_file = path.join(templates.path, "dashboard.html")
templates.package_file = path.join(templates.path, "package.html")
templates.version_file = path.join(templates.path, "version.html")

templates.output_path = path.join(data_dir, "output")
templates.output_dashboard = "index.html"
templates.output_package = "packages/%s/index.html"
templates.output_version = "packages/%s/%s.html"

templates.package_repo_url = "https://github.com/LuaDist2/%s"
