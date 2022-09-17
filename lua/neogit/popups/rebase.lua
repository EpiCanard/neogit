local cli = require("neogit.lib.git.cli")
local git = require("neogit.lib.git")
local popup = require("neogit.lib.popup")
local CommitSelectViewBuffer = require("neogit.buffers.commit_select_view")
local rebase = require("neogit.lib.git.rebase")
local status = require("neogit.status")

local M = {}

function M.create()
  local _, exitCode = cli.rebase.args("--show-current-patch").call_sync()
  local rebaseInProgress = exitCode == 0

  local p = popup
    .builder()
    :name("NeogitRebasePopup")
    :action("p", "Rebase onto master", function()
      cli.rebase.args("master").call_sync()
    end)
    :action("e", "Rebase onto elsewhere", function()
      local branch = git.branch.prompt_for_branch(git.branch.get_all_branches())
      cli.rebase.args(branch).call_sync()
    end)
    :action("i", "Interactive", function()
      local commits = rebase.commits()
      CommitSelectViewBuffer.new(commits, function(_view, selected)
        rebase.run_interactive(selected.oid)
        _view:close()
      end):open()
    end)
    :action_if(rebaseInProgress, "c", "Rebase --continue", function()
      cli.rebase.continue.call_sync()
      status.dispatch_refresh(true)
    end)
    :action_if(rebaseInProgress, "s", "Rebase --skip", function()
      cli.rebase.skip.call_sync()
      status.dispatch_refresh(true)
    end)
    :action_if(rebaseInProgress, "a", "Rebase --abort", function()
      cli.rebase.abort.call_sync()
      status.dispatch_refresh(true)
    end)
    :build()

  p:show()

  return p
end

return M
