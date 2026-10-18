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
  table.sort(workspaces)

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

-- Find the closest package.json with workspaces, starting from the cwd.
function l.find_npm_root()
  local dir = vim.fn.getcwd()

  while true do
    local pkg = l.read_json(vim.fs.joinpath(dir, 'package.json'))
    if pkg ~= nil and type(pkg.workspaces) == 'table' then
      return dir, pkg
    end

    local parent = vim.fs.dirname(dir)
    if parent == dir then
      return
    end
    dir = parent
  end
end

function l.glob(root, pattern)
  local paths = {}
  for _, path in ipairs(vim.fn.globpath(root, pattern, false, true)) do
    paths[vim.fs.normalize(path)] = true
  end
  return paths
end

function l.get_npm_workspaces()
  local ns = {}

  local root, pkg = l.find_npm_root()
  if root == nil then
    return ns
  end

  local paths = {}
  for _, pattern in ipairs(pkg.workspaces) do
    local exclude = pattern:match('^!(.*)')
    for path in pairs(l.glob(root, exclude or pattern)) do
      paths[path] = not exclude or nil
    end
  end

  for path in pairs(paths) do
    if vim.fn.filereadable(vim.fs.joinpath(path, 'package.json')) == 1 then
      ns[vim.fs.basename(path)] = path
    end
  end

  return ns
end

return M
