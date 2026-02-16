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
  html = {},
  ansiblels = {},
  gopls = {},
  vimls = {},
  mesonlsp = {},
  somesass_ls = {
    settings = {
      somesass = {
        css = { completion = { includeFromCurrentDocument = true } },
        scss = { completion = { includeFromCurrentDocument = true } },
      },
    },
  },

  vtsls = {
    settings = {
      vtsls = {
        tsserver = {
          logVerbosity = 'verbose',
          globalPlugins = {
            {
              name = '@vue/typescript-plugin',
              location = vim.fn.resolve(vim.fn.fnamemodify(vim.fn.exepath('vue-language-server'), ':h')) .. "/../lib/language-tools/packages/language-server",
              languages = { "vue" },
              configNamespace = 'typescript',
            }
          }
        },
      },
    },
    filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
  },
  vue_ls = {},

  copilot = { settings = { telemetry = { telemetryLevel = "off" } } },
  docker_compose_language_service = {}, -- FIXME
  yamlls = {
    settings = {
      redhat = { telemetry = { enabled = false } },
      yaml = {
        customTags = {
          "!vault scalar",
          "!reset scalar",
          "!reset sequence",
          "!reset mapping",
          "!override scalar",
          "!override mapping",
          "!override sequence",
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
