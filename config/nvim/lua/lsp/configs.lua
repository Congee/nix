-- To debug :lua print(vim.inspect(vim.lsp.get_client_by_id(1).config))

local lspconfig = require('lspconfig');
local lsp_status = require('lsp-status');

--- @type table<string, lspconfig.Config>
--- @diagnostic disable: missing-fields
return {
  basedpyright = {},
  nil_ls = {},
  bashls = {},
  dockerls = {},
  docker_compose_language_service = {},
  html = {},
  ansiblels = {},
  gopls = {},
  vimls = {},
  mesonlsp = {},
  somesass_ls = {},
  volar = {}, -- The hybrid mode is broken from nvim-lspconfig
  ts_ls = {
    init_options = {
      plugins = {
        {
          name = "@vue/typescript-plugin",
          location = vim.fs.dirname(vim.uv.fs_realpath(vim.fn.exepath('vue-language-server'))) .. '/../lib/node_modules/@vue/language-server/node_modules/@vue/typescript-plugin',
          languages = { "javascript", "typescript", "vue" },
        },
      },
    },
    filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", 'vue' },
  },

  yamlls = {
    settings = {
      redhat = { telemetry = { enabled = false } },
      yaml = {
        customTags = {
          "!vault scalar",
          -- "!reset scalar",
          -- "!reset sequence",
          -- "!reset mapping",
          -- "!override scalar",
          -- "!override mapping",
          -- "!override sequence",
        },
        -- Schemas https://www.schemastore.org
        schemas = {
          ["http://json.schemastore.org/github-action.json"] = ".github/action.{yml,yaml}",
          kubernetes = "templates/**",
        },
      }
    }
  },

  helm_ls = {
    settings = {
      helm = {
        command = "helm_ls",
        args = { "serve" },
        filetypes = { "helm", "helmfile" },
        rootPatterns = { "Chart.yaml" },
      },
    },
  },

  jsonls = {
    filetypes = {"json", "jsonc"},
    settings = {
      json = {
        -- Schemas https://www.schemastore.org
        schemas = {
          {
            fileMatch = {"package.json"},
            url = "https://json.schemastore.org/package.json"
          },
          {
            fileMatch = {"tsconfig*.json"},
            url = "https://json.schemastore.org/tsconfig.json"
          },
        }
      }
    }
  },

  lua_ls = {
    settings = {
      Lua = {
        hint = { enable = true },
      },
    },
  },
  buf_ls = { },

  sourcekit = {
    filetypes = {'swift', 'objective-c', 'objective-cpp'},
    root_dir = lspconfig.util.root_pattern('Package.swift', '.git'),
    single_file_support = true,
  },
  clangd = {
    handlers = lsp_status.extensions.clangd.setup(),
    init_options = {
      clangdFileStatus = true,
    },
    meson = false,
  },
  -- TODO: try artempyanykh/marksman when my obsidian.md is complex enough
  harper_ls = {
    enabled = false, -- builtin spell is good enough so far
    filetypes = { 'markdown' },
    root_markers = {},
  },
}
