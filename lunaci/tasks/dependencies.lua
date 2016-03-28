module("lunaci.tasks.dependencies", package.seeall)


local check_package_dependencies = function(package, target, manifest)
    local config = require "lunaci.config"
    local pl = require "pl.import_into"()
    local DependencySolver = require "rocksolver.DependencySolver"
    local const = require "rocksolver.constraints"

    -- Add target to manifest as a virtual package
    local manifest = pl.tablex.deepcopy(manifest)
    target_name, target_version = const.split(target)
    manifest.packages[target_name] = {[target_version] = {}}

    local solver = DependencySolver(manifest, config.platform)
    local deps, err = solver:resolve_dependencies(tostring(package))

    if err then
        return false, "Error resolving dependencies for package " .. tostring(package) .. ":\n" .. err, false
    end

    local has_deps = false
    local out = "Resolved dependencies for package " .. tostring(package) .. ": "
    for _, dep in pairs(deps) do
        if dep ~= package then
            out = out .. "\n- " .. tostring(dep)
            has_deps = true
        end
    end

    if not has_deps then
        out = out .. "None"
    end

    return true, out, true
end


return check_package_dependencies
