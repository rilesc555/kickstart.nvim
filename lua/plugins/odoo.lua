return {
  cmd = 'Odools',
  config = function()
    local target = '0.4.0'

    local download = function(url, output_path, asset_type)
      print('Starting download from: ' .. url)
      print('Saving to: ' .. output_path)

      local stdout = vim.uv.new_pipe(false)
      local stderr = vim.uv.new_pipe(false)

      local handle
      local args, cmd
      if asset_type == 'file' then
        cmd = 'wget'
        args = { '-qO', output_path, url }
      else
        cmd = 'git'
        args = { 'clone', '-q', url, output_path }
      end
      handle = vim.uv.spawn(cmd, {
        args = args,
        stdio = { nil, stdout, stderr },
      }, function(code, signal)
        stdout:close()
        stderr:close()
        handle:close()

        if code == 0 then
          print('\nDownload successful!')
        else
          print('\nDownload failed with exit code ' .. code)
        end
      end)

      stdout:read_start(function(err, data)
        assert(not err, err)
        if data then
          io.write(data)
          io.flush()
        end
      end)

      stderr:read_start(function(err, data)
        assert(not err, err)
        if data then
          io.write('\nError: ' .. data)
          io.flush()
        end
      end)
    end

    local download_requirements = function()
      local bin_dir_path = vim.fn.stdpath 'data' .. '/odoo'
      local bin_path = bin_dir_path .. '/odoo_ls_server'
      if vim.fn.isdirectory(bin_dir_path) == 0 then
        vim.fn.mkdir(bin_dir_path, 'p')
      end
      pcall(vim.cmd.LspStop, 'odools')
      download('https://github.com/odoo/odoo-ls/releases/download/' .. target .. '/odoo_ls_server', bin_path, 'file')
      if vim.fn.executable 'git' == 1 then
        local path = bin_dir_path .. '/typeshed'
        if vim.fn.isdirectory(path) == 0 then
          download('https://github.com/python/typeshed.git', path, 'repo')
        else
          print 'typeshed already downloaded'
        end
      else
        vim.api.nvim_err_writeln 'git needed to download python typeshed'
      end
      vim.fn.fs_chmod(bin_path, 493) -- -rwxr-xr-x
      pcall(vim.cmd.LspStart, 'odools')
    end

    local odoo_command = function(opts)
      if opts.fargs and opts.fargs[1] == 'install' then
        download_requirements()
      end
    end

    vim.api.nvim_create_user_command('Odools', odoo_command, {
      nargs = 1,
      complete = function()
        return { 'install' }
      end,
    })
  end,
}
