-- Java language support via Eclipse JDT LS, driven by nvim-jdtls.
-- https://github.com/mfussenegger/nvim-jdtls
--
-- The `jdtls` server itself is installed through Mason (see `ensure_installed`
-- in init.lua). It is deliberately NOT enabled through nvim-lspconfig /
-- mason-lspconfig (see `automatic_enable` in init.lua): nvim-jdtls has to
-- start it so it can pass a per-project workspace dir and jdtls-only commands.
return {
  {
    'mfussenegger/nvim-jdtls',
    ft = 'java',
    dependencies = { 'hrsh7th/cmp-nvim-lsp' },
    config = function()
      local jdtls = require 'jdtls'

      -- Multi-module projects: prefer the top-level wrapper/settings file over
      -- the nearest pom.xml / build.gradle of a sub-module.
      local root_markers = {
        { 'mvnw', 'gradlew', 'settings.gradle', 'settings.gradle.kts' },
        { 'pom.xml', 'build.gradle', 'build.gradle.kts' },
      }

      -- No build file (loose exercise folders): the project is the file's source
      -- root, i.e. its directory minus the `package` path. Using the git root
      -- instead would merge every folder into one project, so equally named
      -- default-package classes from other exercises clash.
      local function source_root(bufnr)
        local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
        for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)) do
          local pkg = line:match '^%s*package%s+([%w_.]+)%s*;'
          if pkg then
            for _ in (pkg .. '.'):gmatch '[^.]+%.' do
              dir = vim.fs.dirname(dir)
            end
            break
          end
        end
        return dir
      end

      local mason_jdtls = vim.fn.stdpath 'data' .. '/mason/packages/jdtls'

      local function start(bufnr)
        if vim.fn.executable 'jdtls' == 0 then
          vim.notify_once('jdtls not found in PATH – run :Mason and install it', vim.log.levels.WARN)
          return
        end

        local root_dir = vim.fs.root(bufnr, root_markers) or source_root(bufnr)
        -- One jdtls workspace (index/cache) per project, kept out of the project tree.
        -- The path hash keeps equally named folders (A1, A2, ...) apart.
        local workspace = vim.fn.stdpath 'cache' .. '/jdtls/' .. vim.fn.fnamemodify(root_dir, ':t') .. '-' .. vim.fn.sha256(root_dir):sub(1, 8)

        local cmd = { 'jdtls', '-data', workspace }
        -- Mason ships lombok.jar alongside jdtls; enable it so @Getter, @Builder etc. resolve.
        local lombok = mason_jdtls .. '/lombok.jar'
        if vim.uv.fs_stat(lombok) then
          table.insert(cmd, '--jvm-arg=-javaagent:' .. lombok)
        end

        jdtls.start_or_attach {
          cmd = cmd,
          root_dir = root_dir,
          capabilities = require('cmp_nvim_lsp').default_capabilities(),
          settings = {
            java = {
              signatureHelp = { enabled = true },
              completion = {
                favoriteStaticMembers = {
                  'org.junit.jupiter.api.Assertions.*',
                  'org.mockito.Mockito.*',
                },
              },
              sources = {
                -- Don't star-import until a package has this many imports.
                organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
              },
            },
          },
        }
      end

      local function map(bufnr, mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = 'Java: ' .. desc })
      end

      vim.api.nvim_create_autocmd('FileType', {
        desc = 'Start / attach jdtls for Java buffers',
        group = vim.api.nvim_create_augroup('custom-jdtls', { clear = true }),
        pattern = 'java',
        callback = function(event)
          start(event.buf)

          -- Refactorings that only jdtls offers (nvim-jdtls provides the commands).
          map(event.buf, 'n', '<leader>jo', jdtls.organize_imports, '[O]rganize imports')
          map(event.buf, 'n', '<leader>jv', jdtls.extract_variable, 'Extract [V]ariable')
          map(event.buf, 'x', '<leader>jv', function()
            jdtls.extract_variable(true)
          end, 'Extract [V]ariable')
          map(event.buf, 'n', '<leader>jc', jdtls.extract_constant, 'Extract [C]onstant')
          map(event.buf, 'x', '<leader>jc', function()
            jdtls.extract_constant(true)
          end, 'Extract [C]onstant')
          map(event.buf, 'x', '<leader>jm', function()
            jdtls.extract_method(true)
          end, 'Extract [M]ethod')
        end,
      })

      -- The plugin is loaded lazily by the first Java buffer, whose FileType
      -- event may already be over; start jdtls for the buffers that exist now.
      -- (start_or_attach reuses a running client, so a double start is harmless.)
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[bufnr].filetype == 'java' then
          vim.api.nvim_exec_autocmds('FileType', { group = 'custom-jdtls', buffer = bufnr })
        end
      end
    end,
  },

  { -- which-key group for the <leader>j mappings above
    'folke/which-key.nvim',
    opts = {
      spec = {
        { '<leader>j', group = '[J]ava', mode = { 'n', 'x' } },
      },
    },
  },
}
