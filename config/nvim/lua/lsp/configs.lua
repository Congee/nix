-- To debug :lua print(vim.inspect(vim.lsp.get_client_by_id(1).config))

local lsp_status = require('lsp-status');

--- @type table<string, vim.lsp.Config>
--- @diagnostic disable: missing-fields
return {
  ty = {},
  ruff = {},
  nil_ls = {},
  bashls = {
    -- man's SGR escapes survive bashls' `col -bx` and litter the hover float
    cmd_env = { GROFF_NO_SGR = '1' },
  },
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
  zls = {},

  rust_analyzer = {
    settings = {
      ['rust-analyzer'] = {
        files = { excludeDirs = { ".direnv" } },
        rustfmt = {
          -- require `rustfmt` binary
          overrideCommand = { "rustfmt", "--" },
          rangeFormatting = { enable = true },
          extraArgs = { "+nightly" },
        },
        cargo = { buildScripts = { enable = true } }
      },
    }
  },

  copilot = { settings = { telemetry = { telemetryLevel = "off" } } },
  docker_compose_language_service = {}, -- FIXME
  tombi = {},
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

  emmylua_ls = {
    -- documentHighlight resolves locals by scope, but a member by name, over every equal-text
    -- token in the file: on `vim.api.nvim_create_autocmd` a bogus `abc.nvim_create_autocmd()`
    -- lights up too. references does resolve members, so re-ask when the response is all TEXT.
    -- https://github.com/EmmyLuaLs/emmylua-analyzer-rust/blob/0.25.1/crates/emmylua_ls/src/handlers/document_highlight/highlight_tokens.rs#L74
    handlers = {
      ['textDocument/documentHighlight'] = function(_, result, ctx)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if client == nil or result == nil or #result == 0 then return end
        local function paint(items)
          vim.lsp.util.buf_highlight_references(ctx.bufnr, items, client.offset_encoding)
        end
        if not vim.iter(result):all(|h| -> h.kind == 1) then return paint(result) end

        local params = vim.deepcopy(ctx.params)
        params.context = { includeDeclaration = true }
        client:request('textDocument/references', params, function(_, refs)
          if not vim.api.nvim_buf_is_valid(ctx.bufnr) then return end
          local uri = vim.uri_from_bufnr(ctx.bufnr)
          local here = vim.tbl_filter(|r| -> r.uri == uri, refs or {})
          paint(next(here) and here or result)  -- keyword pairs come back empty
        end, ctx.bufnr)
      end,
    },
    settings = {
      ---@schema https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/refs/heads/main/crates/emmylua_code_analysis/resources/schema.json
      emmylua = {
        runtime = {
          -- LuaJIT3 is what accepts the backported v3.0 syntax (`|x| -> y`).
          version = "LuaJIT3",
          requirePattern = {
            "?.lua",
            "?/init.lua",
            "lua/?.lua",
            "lua/?/init.lua",
          },
        },
        workspace = {
          -- per-plugin `lua/` dirs only: plugin `meta/` dirs shadow the real `vim`
          library = vim.list_extend(
            { "$VIMRUNTIME" },
            vim.fn.glob(vim.fn.stdpath('data') .. '/lazy/*/lua', true, true)
          ),
          ignoreGlobs = { "**/*_spec.lua" },
        },
      },
    },
  },
  buf_ls = { },

  sourcekit = {
    filetypes = {'swift', 'objc', 'objcpp'}, -- c/cpp stay with clangd
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
