local repl  = require 'repl'
local utils = require 'test-utils'
pcall(require, 'luarocks.loader')
require 'Test.More'

plan(20)

local clone = repl:clone()

do -- basic tests {{{
  local loaded

  clone:loadplugin(nil, function()
    loaded = true
  end)

  ok(loaded)

  error_like(function()
    clone:loadplugin(nil, function()
      error 'uh-oh'
    end)
  end, 'uh%-oh')

end -- }}}

do -- loading the same plugin twice {{{
  local function plugin()
  end

  local line_no

  clone:loadplugin(nil, plugin)
  local _, err = pcall(function()
    line_no = utils.next_line_number()
    clone:loadplugin(nil, plugin)
  end)
  like(err, tostring(line_no) .. ': plugin "function:%s+%S+" has already been loaded')

  _, err = pcall(function()
    line_no = utils.next_line_number()
    clone:clone():loadplugin(nil, plugin)
  end)
  like(err, tostring(line_no) .. ': plugin "function:%s+%S+" has already been loaded')

  repl:clone():loadplugin(nil, plugin)
  repl:clone():loadplugin(nil, plugin)
end -- }}}

do -- loading plugins by name {{{
  local loaded

  package.preload['repl.plugins.test'] = function()
    loaded = true
  end

  clone:clone():loadplugin 'test'

  ok(loaded)
  loaded = false

  clone:clone():loadplugin 'test'

  ok(loaded, 'loading a plugin twice should initialize it twice')

  package.preload['repl.plugins.test'] = function()
    error 'uh-oh'
  end

  error_like(function()
    clone:clone():loadplugin 'test'
  end, 'uh%-oh')

  package.preload['repl.plugins.test'] = nil

  local line_no

  local _, err = pcall(function()
    line_no = utils.next_line_number()
    clone:clone():loadplugin 'test'
  end)
  like(err, tostring(line_no) .. ': unable to locate plugin')
end -- }}}

do -- hasplugin tests {{{
  local child = repl:clone()

  local plugin = function()
  end

  child:loadplugin(nil, plugin)

  local grandchild = child:clone()

  ok(not repl:hasplugin(plugin))
  ok(child:hasplugin(plugin))
  ok(grandchild:hasplugin(plugin))

  plugin = function()
  end

  child:loadplugin(nil, plugin)

  ok(not repl:hasplugin(plugin))
  ok(child:hasplugin(plugin))
  ok(not grandchild:hasplugin(plugin))
end -- }}}

do -- global tests {{{
  local clone = repl:clone()
  local line_no

  local _, err = pcall(function()
    clone:loadplugin(nil, function()
      line_no = utils.next_line_number()
      foo     = 17
    end)
  end)

  like(err, tostring(line_no) .. ': global environment is read%-only %(key = "foo"%)')

  _, err = pcall(function()
    clone:loadplugin(nil, function()
      line_no = utils.next_line_number()
      _G.foo  = 17
    end)
  end)

  like(err, tostring(line_no) .. ': global environment is read%-only %(key = "foo"%)')
end -- }}}

do -- plugin initialization {{{
  local clone = repl:clone()

  local initialized = false

  clone:loadplugin(nil, function()
    function init()
      initialized = true
    end
  end)

  ok(not initialized)

  clone:initplugins()

  ok(initialized)
end -- }}}

do -- correct resolution of plugin dependencies {{{
  local clone = repl:clone()

  local a_initialized = false
  local b_initialized_after_a = false

  clone:loadplugin('plugin b', function()
    repl:dependsonplugin('plugin a')
    function init()
      if a_initialized then
        b_initialized_after_a = true
      end
    end
  end)

  clone:loadplugin('plugin a', function()
    function init()
      a_initialized = true
    end
  end)

  clone:initplugins()

  ok(b_initialized_after_a, 'plugins are initialized after their dependencies have been initialized')
end -- }}}

do -- correct resolution of feature dependencies {{{
  local clone = repl:clone()

  local a_initialized = false
  local b_initialized_after_a = false

  clone:loadplugin('plugin b', function()
    repl:dependsonfeature('foo feature')
    function init()
      if a_initialized then
        b_initialized_after_a = true
      end
    end
  end)

  clone:loadplugin('plugin a', function()
    features = 'foo feature'
    function init()
      a_initialized = true
    end
  end)

  clone:initplugins()

  ok(b_initialized_after_a, 'plugins are initialized after their dependencies have been initialized')
end -- }}}
