local api = vim.api

local M = {}

---https://github.com/neovim/neovim/commit/bf68ba40a03a19c97454ede293ed289c547b5aaa
---@return boolean
M.has_ui2 = function()
  local get = vim.F.nil_wrap(function(name) return api.nvim_get_autocmds({ group = name }) end)
  return next(get('nvim.ui2') or get('nvim._ext_ui') or {}) and true or false
end

local _NVIM_VERSION
---vim.version.parse should exist, since usually we check nightly feature
---@param version string
---@return boolean
M.has_version = function(version)
  _NVIM_VERSION = _NVIM_VERSION
    or vim.version.parse(api.nvim_exec2('version', { output = true }).output:match('NVIM (.-)\n'))
  return _NVIM_VERSION >= vim.version.parse(version)
end

---@param func function
---@param tname string
---@return any, integer?
M.upvfind = function(func, tname)
  local i = 1
  while true do
    local name, value = debug.getupvalue(func, i)
    if not name then break end
    if name == tname then return value, i end
    i = i + 1
  end
  return nil
end

return M
