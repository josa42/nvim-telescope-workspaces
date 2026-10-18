local workspaces = require('jg.telescope-workspaces')

local cwd = vim.fn.getcwd()
local root

local function write(path, content)
  path = vim.fs.joinpath(root, path)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile(vim.split(content, '\n'), path)
end

local function package_json(patterns)
  write('package.json', vim.json.encode({ workspaces = patterns }))
end

local function path(p)
  return vim.fs.joinpath(root, p)
end

describe('jg.telescope-workspaces', function()
  before_each(function()
    root = vim.fn.tempname()
    vim.fn.mkdir(root, 'p')
    root = vim.uv.fs_realpath(root)

    write('packages/a/package.json', '{}')
    write('packages/b/package.json', '{}')
    write('packages/no-package/README.md', '')
    write('tools/x/package.json', '{}')

    vim.fn.chdir(root)
    workspaces.set_current_workspace(nil)
  end)

  after_each(function()
    vim.fn.chdir(cwd)
    vim.fn.delete(root, 'rf')
  end)

  describe('get_workspaces()', function()
    it('returns sorted workspace names', function()
      package_json({ 'tools/*', 'packages/*' })
      assert.same({ 'a', 'b', 'x' }, workspaces.get_workspaces())
    end)

    it('supports patterns with a trailing slash', function()
      package_json({ 'packages/*/' })
      assert.same({ 'a', 'b' }, workspaces.get_workspaces())
    end)

    it('supports negated patterns', function()
      package_json({ 'packages/*', '!packages/b', 'tools/*' })
      assert.same({ 'a', 'x' }, workspaces.get_workspaces())
    end)

    it('applies negated patterns in order', function()
      package_json({ 'packages/*', '!packages/*', 'packages/b' })
      assert.same({ 'b' }, workspaces.get_workspaces())
    end)

    it('finds workspaces from a subdirectory', function()
      package_json({ 'packages/*' })
      vim.fn.chdir(path('packages/a'))
      assert.same({ 'a', 'b' }, workspaces.get_workspaces())
    end)

    it('returns nothing without package.json', function()
      assert.same({}, workspaces.get_workspaces())
    end)

    it('returns nothing for invalid package.json', function()
      for _, content in ipairs({ 'not json', '"string"', '{"workspaces":null}', '{"workspaces":"packages/*"}' }) do
        write('package.json', content)
        assert.same({}, workspaces.get_workspaces(), content)
      end
    end)
  end)

  describe('get_current_workspace_path()', function()
    before_each(function()
      package_json({ 'packages/*' })
    end)

    it('returns the path of the current workspace', function()
      workspaces.set_current_workspace('b')
      assert.equal(path('packages/b'), workspaces.get_current_workspace_path())
    end)

    it('returns "." without a current workspace', function()
      assert.equal('.', workspaces.get_current_workspace_path())
    end)

    it('returns "." for an unknown workspace', function()
      workspaces.set_current_workspace('unknown')
      assert.equal('.', workspaces.get_current_workspace_path())
    end)
  end)
end)
