-- To debug :lua print(vim.inspect(vim.lsp.get_client_by_id(1).config))

local lspconfig = require('lspconfig');
local cmp = require("cmp")
local navic = require("nvim-navic")
local navbuddy = require("nvim-navbuddy")
local inlayhints = require('lsp-inlayhints')
local telescope = require('telescope.builtin')

local servers = {
    'pyright',
    'nil_ls',
    'bashls',
    'dockerls',
    'docker_compose_language_service',
    'jsonls',
    'html',
    'yamlls',
    'helm_ls',
    'ansiblels',
    'tsserver',
    'gopls',
};

inlayhints.setup()
require('mason').setup();
require('mason-lspconfig').setup({
    ensure_installed = { 'biome', table.unpack(servers) },
    automatic_installation = true,
})

require('lint').linters_by_ft = {
    -- javascript = {'eslint_d'},
    python = {'ruff'},
}
vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    callback = function() require("lint").try_lint() end,
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'cmp_docs',
    callback = function()
        vim.treesitter.start(0, 'markdown')
    end,
})

-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id);
    local bufnr = ev.buf;

    -- https://github.com/neovim/nvim-lspconfig/issues/2626#issuecomment-2117022664
    if client.name == 'yamlls' and vim.bo.filetype == 'helm' then
      return vim.lsp.buf_detach_client(bufnr, client.id);
    end

    local function show_documentation()
        local filetype = vim.bo.filetype
        if vim.tbl_contains({ 'vim','help' }, filetype) then
            vim.cmd('h '..vim.fn.expand('<cword>'))
        elseif vim.tbl_contains({ 'man' }, filetype) then
            vim.cmd('Man '..vim.fn.expand('<cword>'))
        elseif vim.fn.expand('%:t') == 'Cargo.toml' and require('crates').popup_available() then
            require('crates').show_popup()
        else
            vim.lsp.buf.hover()
        end
    end

    local opts = { silent = true, buffer = bufnr }
    vim.keymap.set('n', 'gD', telescope.lsp_type_definitions, opts)
    vim.keymap.set('n', 'gd', telescope.lsp_definitions, opts)
    vim.keymap.set('n', 'gI', telescope.lsp_implementations, opts)
    vim.keymap.set('n', 'gr', telescope.lsp_references, opts)
    vim.keymap.set('n', 'K', show_documentation, opts)
    if vim.bo.filetype == 'rust' then
      vim.keymap.set("n", "<space>", function() vim.cmd.RustLsp { 'hover', 'range' } end, opts)
    end
    vim.keymap.set('n', '<leader>ac', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '[h', function()
        vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.HINT })
    end, opts)
    vim.keymap.set('n', ']h', function()
        vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.HINT })
    end, opts)
    vim.keymap.set('n', '[w', function()
        vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
    end, opts)
    vim.keymap.set('n', ']w', function()
        vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
    end, opts)
    vim.keymap.set('n', '[e', function()
        vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
    end, opts)
    vim.keymap.set('n', ']e', function()
        vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
    end, opts)
    vim.keymap.set('n', '<leader>fx', function()
        vim.lsp.buf.code_action({
            filter = function(x) return x.isPreferred end,
            apply = true,
        })
    end, opts)

    vim.b.navic_lazy_update_context = true
    if client.server_capabilities.documentSymbolProvider then
        navic.attach(client, bufnr)
        navbuddy.attach(client, bufnr)
    end

    -- lsp client somehow does not send textDocument/rangeFormatting
    if client.server_capabilities.documentRangeFormattingProvider then
        local fn = function() vim.lsp.buf.format({ async = true }) end
        vim.keymap.set('v', 'gq', fn, opts)
    end

    inlayhints.on_attach(client, bufnr)
  end,
})

-- Recently lsp client of neovim watch files by polling. This is embarrassing :/
-- https://github.com/neovim/neovim/issues/23291
-- https://github.com/neovim/neovim/issues/23725#issuecomment-1561364086
-- :lua =vim.lsp.get_active_clients()[1].server_capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
local setup = { capabilities = capabilities }
for _, lsp in ipairs(servers) do
    lspconfig[lsp].setup(setup) -- call :LspStart on startup
end

lspconfig['tsserver'].setup(vim.tbl_extend('error', setup, {
  -- XXX: replaces tsserver to avoid conflicts
  -- Ideally, only enable this on vite.config..s, but
  -- I don't have a way to disable tsserver by lspconfig.util.root_pattern()
  root_dir = lspconfig.util.root_pattern('package.json', '.git'),
  init_options = {
    plugins = {
      {
        name = "@vue/typescript-plugin",
        location = require('mason-registry').get_package('vue-language-server'):get_install_path() .. '/node_modules/@vue/language-server/node_modules/@vue/typescript-plugin',
        languages = { "javascript", "typescript", "vue" },
      },
    },
  },
  filetypes = {'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue', 'json'},
}))

lspconfig['yamlls'].setup(vim.tbl_extend('error', setup, {
  settings = {
    yaml = {
      filetypes_exclude = { 'helm' },
      customTags = {
        "!vault scalar",
      },
      -- Schemas https://www.schemastore.org
      schemas = {
        ["http://json.schemastore.org/github-action.json"] = ".github/action.{yml,yaml}",
        kubernetes = "templates/**",
      },
    }
  }
}))

lspconfig['helm_ls'].setup(vim.tbl_extend('error', setup, {
	settings = {
		helm = {
			command = "helm_ls",
			args = { "serve" },
			filetypes = { "helm", "helmfile" },
			rootPatterns = { "Chart.yaml" },
		},
	},
}))

lspconfig['jsonls'].setup(vim.tbl_extend('error', setup, {
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
}))

lspconfig['lua_ls'].setup(vim.tbl_extend('error', setup, {
    cmd = { vim.env.HOME .. '/.nix-profile/bin/lua-language-server' },
}))
lspconfig['bufls'].setup(vim.tbl_extend('error', setup, {
    cmd = { vim.env.HOME .. '/.nix-profile/bin/bufls' },
}))

lspconfig['sourcekit'].setup(vim.tbl_extend('error', setup, {
    cmd = { 'sourcekit-lsp' },
    filetypes = {'swift', 'objective-c', 'objective-cpp'},
    root_dir = lspconfig.util.root_pattern('Package.swift', '.git'),
    single_file_support = true,
}))
lspconfig['clangd'].setup(vim.tbl_extend('error', setup, { }))

cmp.setup({
    snippet = {
        expand = function(args)
            vim.fn["UltiSnips#Anon"](args.body)
        end,
    },
    sources = {
        { name = 'nvim_lsp_signature_help' },
        { name = 'nvim_lsp' },
        { name = 'path' },
        { name = 'ultisnips' },
        { name = "crates" },
    },
    window = { documentation = { max_width = 79 } },
    completion = { autocomplete = {} },
    preselect = cmp.PreselectMode.None,
    mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.mapping.scroll_docs(4)
            else
                fallback()
            end
        end),
        ['<C-X><C-O>'] = cmp.mapping.complete(),
        ['<C-Tab>'] = cmp.mapping.complete({config = { sources = { name = 'vsnip'}}}),
        ['<Tab>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
        }),
    }),
})


cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = { { name = 'buffer' } }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    mapping = vim.tbl_extend('force', cmp.mapping.preset.cmdline(), {
        ['<Tab>'] = cmp.mapping({
            c = function()
                if cmp.visible() then
                    cmp.select_next_item()
                else
                    cmp.complete()
                    cmp.select_next_item()
                end
            end,
        })
    }),
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        {
            name = 'cmdline',
            option = { ignore_cmds = { "Man", "!" }, },
        }

    })
})
