local dependency_resolver = require 'repl.dependency_resolver'
pcall(require, 'luarocks.loader')
require 'Test.More'

plan(8)

do -- can sort dependencies {{{
  local resolver = dependency_resolver()
  resolver:add('a', {'b', 'c'})
  resolver:add('b', {'c'})
  resolver:add('c')
  local result = resolver:sort()
  ok(#result == 3)
  ok(result[1] == 'c')
  ok(result[2] == 'b')
  ok(result[3] == 'a')
end -- }}}

do -- raises an error for duplicated entries {{{
  local resolver = dependency_resolver()
  resolver:add('a')
  ok(pcall(resolver.add, resolver, 'a') == false)
end -- }}}

do -- raises an error for missing dependencies {{{
  local resolver = dependency_resolver()
  resolver:add('a', {'b'})
  ok(pcall(resolver.sort, resolver) == false)
end -- }}}

do -- raises an error for direct dependency cycles {{{
  local resolver = dependency_resolver()
  resolver:add('a', {'b'})
  resolver:add('b', {'a'})
  ok(pcall(resolver.sort, resolver) == false)
end -- }}}

do -- raises an error for indirect dependency cycles {{{
  local resolver = dependency_resolver()
  resolver:add('a', {'b'})
  resolver:add('b', {'c'})
  resolver:add('c', {'a'})
  ok(pcall(resolver.sort, resolver) == false)
end -- }}}
