--- A container that can be used to sort entries that have dependencies.
--
-- Each entry added to this list can 'depend' on other entries.
--
-- Once all entries have been added, the list can be sorted.
-- Each entry will be placed *after* all its dependencies.
--
-- This is especially useful when working out the correct loading order for
-- packages.
--
-- The list also detects dependency errors, like missing and circular
-- dependencies.
--
-- @class repl.dependency_resolver
-- @alias resolver


local resolver = {
  mt = {},
  prototype = {}
}
resolver.mt.__index = resolver.prototype
setmetatable(resolver, resolver) -- needed by resolver:__call()


--- Creates a new dependency resolver.
function resolver:__call()
  local instance = { entry_map = {} }
  return setmetatable(instance, self.mt)
end

--- Test whether the list contains an entry called `name`.
function resolver.prototype:has( name )
  return self.entry_map[name] ~= nil
end

--- Insert a new unique entry.
--
-- The same entry may not be added twice.
--
-- @param name
--
-- @param[opt] dependencies
-- A list of entry names that the added entry depends on.
--
function resolver.prototype:add( name, dependencies )
  assert(not self.entry_map[name], 'Entry '..name..' already exists.')
  dependencies = dependencies or {}
  self.entry_map[name] = dependencies
end

local function resolve_transitive_dependencies( entry_map,
                                                entry_name,
                                                resolved_dependencies,
                                                dependencies )
  for _, dependency in ipairs(dependencies) do
    if not resolved_dependencies[dependency] then
      local dependencies2 = entry_map[dependency]
      if dependencies2 then
        resolved_dependencies[dependency] = true
        resolve_transitive_dependencies(entry_map,
        dependency,
        resolved_dependencies,
        dependencies2)
      else
        error('Detected missing dependency: '..entry_name..' needs '..dependency..'.')
      end
    end
  end
end

--- Work out the correct order and return the sorted result list.
--
-- @return
-- A list which contains all entries in an order that statisfies their dependencies.
--
function resolver.prototype:sort()

  local resolvedentry_map = {}
  for name, dependencies in pairs(self.entry_map) do
    local resolved_dependencies = {}
    resolve_transitive_dependencies(self.entry_map,
                                    name,
                                    resolved_dependencies,
                                    dependencies)
    resolvedentry_map[name] = resolved_dependencies
  end

  local entries = {}
  for name, dependencies in pairs(resolvedentry_map) do
    table.insert(entries, {name=name, dependencies=dependencies})
  end

  table.sort(entries, function( a, b )
    local a_depends_on_b = b.dependencies[a.name]
    local b_depends_on_a = a.dependencies[b.name]

    if a_depends_on_b and b_depends_on_a then
      error('Detected cross reference: '..a.name..' and '..b.name..' depend on each other.')
    elseif a_depends_on_b then
      return true
    elseif b_depends_on_a then
      return false
    else
      return false -- don't care
    end
  end)

  local names = {}
  for i, entry in ipairs(entries) do
    names[i] = entry.name
  end
  return names
end


return resolver
