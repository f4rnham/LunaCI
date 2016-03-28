module("lunaci.config", package.seeall)

local path = require "pl.path"
local log = require "logging"

data_dir = path.abspath("data")


manifest = {}
manifest.repo = "https://gist.github.com/efe9312e64d0e492282e.git"
manifest.path = path.join(data_dir, "manifest-repo")
manifest.file = path.join(manifest.path, "manifest-file")


logging = {}
logging.output = "console"
logging.level = log.INFO
logging.file = path.join(data_dir, "logs/lunaci-%s.log")
logging.date_format = "%Y-%m-%d"


ci_targets = {
    "lua 5.1",
    "lua 5.2",
    "lua 5.3",
}



platform = {"unix", "linux"}


templates = {}
templates.path = path.abspath("templates")
templates.asset_path = path.join(templates.path, "assets")

templates.dashboard_file = path.join(templates.path, "dashboard.html")
templates.package_file = path.join(templates.path, "package.html")
templates.version_file = path.join(templates.path, "version.html")

templates.output_path = path.join(data_dir, "output")
templates.output_dashboard_file = "index.html"
templates.output_package_file = "packages/%s/index.html"
templates.output_version_file = "packages/%s/%s.html"

templates.package_repo_url = "https://github.com/LuaDist2/%s"
