local gl = require('galaxyline')
local colors = require('galaxyline.theme').default
local condition = require('galaxyline.condition')
local gls = gl.section
gl.short_line_list = {'NvimTree', 'vista', 'dbui', 'packer', 'coc-explorer'}


gls.left = {
  {
    RainbowRed = {
      provider = function() return '▊ ' end,
      highlight = {colors.blue,colors.bg}
    },
  },
  {
    ViMode = {
      provider = function()
        -- auto change color according the vim mode
        local mode_color = {
          n = colors.magenta, i = colors.green,v = colors.blue,
          [''] = colors.blue, V = colors.blue,
          c = colors.red,no = colors.magenta,s = colors.orange,
          S=colors.orange,[''] = colors.orange,
          ic = colors.yellow,R = colors.violet,Rv = colors.violet,
          cv = colors.red,ce=colors.red, r = colors.cyan,
          rm = colors.cyan, ['r?'] = colors.cyan,
          ['!']  = colors.red,t = colors.red
        }
        vim.api.nvim_command('hi GalaxyViMode guifg='..mode_color[vim.fn.mode()])
        return '  '
      end,
      highlight = {colors.red,colors.bg,'bold'},
    },
  },
  {
    FileSize = {
      provider = function()
        local fileinfo = require('galaxyline.provider_fileinfo')
        local file = vim.fn.expand('%:p')
        if string.len(file) == 0 then return '' end

        if vim.fn.getfsize(file) > 100 * 1024 then  -- 100kB
          return fileinfo.get_file_size(file)
        else
          return ''
        end
      end,
      condition = condition.buffer_not_empty,
      highlight = {colors.fg,colors.bg}
    }
  },
  {
    FileIcon = {
      provider = 'FileIcon',
      condition = condition.buffer_not_empty,
      highlight = {
        require('galaxyline.provider_fileinfo').get_file_icon_color,
        colors.bg
      },
    },
  },

  {
    ReadOnly = {
      provider = function() return vim.o.readonly and '' or '' end,
      condition = function() return vim.o.readonly end,
    }
  },

  {
    FileName = {
      provider = {'FileName'},
      condition = condition.buffer_not_empty,
      highlight = {colors.green,colors.bg,'bold'}
    }
  },
  {
    CocGitStatus = {
      provider = function() return vim.g.coc_git_status end,
      separator = ' ',
      highlight = {colors.violet,colors.bg,'bold'},
      separator_highlight = {'NONE',colors.bg},
    }
  },
  {
    DiffAdd = {
      provider = 'DiffAdd',
      condition = condition.hide_in_width,
      icon = ' +',
      highlight = {colors.green,colors.bg},
    }
  },
  {
    DiffModified = {
      provider = 'DiffModified',
      condition = condition.hide_in_width,
      icon = ' !',
      highlight = {colors.orange,colors.bg},
    }
  },
  {
    DiffRemove = {
      provider = 'DiffRemove',
      condition = condition.hide_in_width,
      icon = ' -',
      highlight = {colors.red,colors.bg},
    }
  },
  {
    CocCurrentFunction = {
      provider = function() return vim.b.coc_current_function end,
      highlight = {colors.fg,colors.bg,'bold'}
    }
  },
}

gls.right = {
  {
    DiagnosticError = {
      provider = 'DiagnosticError',
      icon = '  ',
      highlight = {colors.red,colors.bg}
    }
  },
  {
    DiagnosticWarn = {
      provider = 'DiagnosticWarn',
      icon = '  ',
      highlight = {colors.yellow,colors.bg},
    }
  },

  {
    DiagnosticHint = {
      provider = 'DiagnosticHint',
      icon = ' ',
      separator = ' ',
      separator_highlight = {'NONE',colors.bg},
      highlight = {'#15aabf', colors.bg},
    }
  },

  {
    DiagnosticInfo = {
      provider = 'DiagnosticInfo',
      icon = '  ',
      highlight = {colors.blue, colors.bg},
    }
  },
  {
    FileEncode = {
      provider = function() return vim.bo.fenc ~= '' and vim.bo.fenc or vim.o.enc end,
      separator = ' ',
      separator_highlight = {'NONE',colors.bg},
      highlight = {colors.cyan,colors.bg,'bold'}
    }
  },
  {
    FileFormat = {
      provider = function() return vim.bo.fileformat end,
      separator = ' ',
      separator_highlight = {'NONE',colors.bg},
      highlight = {colors.cyan,colors.bg,'bold'}
    }
  },
  -- {
  --   GitIcon = {
  --     provider = function() return '  ' end,
  --     condition = require('galaxyline.provider_vcs').check_git_workspace,
  --     separator = ' ',
  --     separator_highlight = {'NONE',colors.bg},
  --     highlight = {colors.violet,colors.bg,'bold'},
  --   }
  -- },
  -- {
  --   GitBranch = {
  --     provider = 'GitBranch',
  --     condition = require('galaxyline.provider_vcs').check_git_workspace,
  --     highlight = {colors.violet,colors.bg,'bold'},
  --   }
  -- },

  {
    LineInfo = {
      provider = 'LineColumn',
      separator = ' ',
      separator_highlight = {'NONE',colors.bg},
      highlight = {colors.fg,colors.bg},
    },
  },
  {
    PerCent = {
      provider = 'LinePercent',
      separator_highlight = {'NONE',colors.bg},
      highlight = {colors.fg,colors.bg,'bold'},
    }
  },

  {
    RainbowBlue = {
      provider = function() return ' ▊' end,
      highlight = {colors.blue,colors.bg}
    },
  },
}


gls.short_line_left = {
  {
    BufferType = {
      provider = 'FileTypeName',
      separator = ' ',
      separator_highlight = {'NONE',colors.bg},
      highlight = {colors.blue,colors.bg,'bold'}
    }
  },
  {
    SFileName = {
      provider = function ()
        local fileinfo = require('galaxyline.provider_fileinfo')
        local fname = fileinfo.get_current_file_name()
        for _,v in ipairs(gl.short_line_list) do
          if v == vim.bo.filetype then
            return ''
          end
        end
        return fname
      end,
      condition = condition.buffer_not_empty,
      highlight = {colors.white,colors.bg,'bold'}
    }
  },
}

gls.short_line_right[1] = {
  BufferIcon = {
    provider= 'BufferIcon',
    highlight = {colors.fg,colors.bg}
  }
}
