local M = {}

local l = {}

function l.read_json(path)
  local file = io.open(path, 'r')
  if file == nil then
    return
  end

  local content = file:read('*a')
  file:close()

  if content == nil then
    return
  end

  local valid, data = pcall(vim.json.decode, content, { luanil = { object = true, array = true } })
  if valid and type(data) == 'table' then
    return data
  end
end

function M.get_workspace_paths()
  -- TODO read workspaces from other monorepo tools?
  return l.get_npm_workspaces()
end

function M.get_workspaces()
  local workspaces = {}

  for workspace in pairs(M.get_workspace_paths()) do
    table.insert(workspaces, workspace)
  end

  return workspaces
end

function M.set_current_workspace(workspace)
  M.current_workspace = workspace
end

function M.get_current_workspace()
  return M.current_workspace
end

function M.get_current_workspace_path()
  local ns = M.get_workspace_paths()
  local name = M.get_current_workspace() or ''

  return ns[name] or '.'
end

function l.get_npm_workspaces()
  local ns = {}

  local pkg = l.read_json('package.json')
  if pkg ~= nil then
    for _, pattern in ipairs(pkg.workspaces or {}) do
      for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
        path = vim.fs.normalize(path)
        if vim.fn.filereadable(vim.fs.joinpath(path, 'package.json')) == 1 then
          ns[vim.fs.basename(path)] = path
        end
      end
    end
  end

  return ns
end

return M
