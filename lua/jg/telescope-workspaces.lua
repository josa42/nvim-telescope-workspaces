local M = {}

local l = {}

function l.read_json(path)
  local file = io.open(path, 'r')
  if file == nil then
    return
  end

  io.input(file)
  local content = io.read('*a')

  if content == nil then
    return
  end

  local valid, data = pcall(vim.fn.json_decode, content)
  if valid then
    return data
  end
end

local function basename(path)
  return path:gsub('(.*/)(.*)', '%2')
end

function M.get_workspace_paths()
  -- TODO read workspaces from other monorepo tools?
  return l.get_yarn_workspaces()
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
  if M.current_workspace == nil then
    -- todo remove dependnecy to gitbranch
    local branch = vim.fn['gitbranch#name']()
    local name = branch:gsub('.*/(.*)/.*', '%1')
    return name
  end

  return M.current_workspace
end

function M.get_current_workspace_path()
  local ns = M.get_workspace_paths()
  local name = M.get_current_workspace() or ''

  return ns[name] or '.'
end

function l.get_yarn_workspaces()
  local ns = {}

  local pkg = l.read_json('package.json')
  if pkg ~= nil then
    for _, pattern in ipairs(pkg.workspaces or {}) do
      for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
        ns[basename(path)] = path
      end
    end
  end

  return ns
end

return M
