module("lunaci.tasks.dependencies", package.seeall)


-- Dependency resolving task.
local check_package_dependencies = function(package, target, manifest)
    local config = require "lunaci.config"
    local pl = require "pl.import_into"()
    local DependencySolver = require "rocksolver.DependencySolver"
    local const = require "rocksolver.constraints"

    -- Add target to manifest as a virtual package
    local manifest = pl.tablex.deepcopy(manifest)
    manifest.packages["lua"] = {[target.compatibility] = {}}

    local solver = DependencySolver(manifest, config.platform)
    local deps, err = solver:resolve_dependencies(tostring(package))

    if err then
        return config.STATUS_FAIL, "Error resolving dependencies for package " .. tostring(package) .. ":\n" .. err, false
    end

    local has_deps = false
    local out = "Resolved dependencies for package " .. tostring(package) .. ": "
    for _, dep in pairs(deps) do
        -- Do not print self as a dependency
        if dep ~= package then
            out = out .. "\n- " .. tostring(dep)
            has_deps = true
        end
    end

    if not has_deps then
        out = out .. "None"
    end

    return config.STATUS_OK, out, true
end


return check_package_dependencies
