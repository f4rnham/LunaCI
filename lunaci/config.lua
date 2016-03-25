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
logging.level = log.DEBUG
logging.file = path.join(data_dir, "logs/lunaci-%s.log")
logging.date_format = "%Y-%m-%d"


ci_targets = {
    {name = "lua", version = "5.2"},
}


STATUS_OK = "OK"
STATUS_NA = "N/A"
STATUS_FAIL = "Fail"


platform = {"unix", "linux"}
