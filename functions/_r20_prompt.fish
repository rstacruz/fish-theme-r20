# Cheatsheet:
#   _r20_prompt            # prints the entire prompt
#
#   _r20_color prompt      # => (set_color brblack)
#   _r20_glyph end         # => ">"
#
#   _r20_git_ahead_behind  # => "+1 -1"
#   _r20_git_branch        # => "master"
#   _r20_git_is_dirty      # success or fail

function _r20_prompt --description 'Prompt' --argument-names side fast
  set -l exit_code $status
  set -l gitroot (_r20_git_root)
  set -l duration (_r20_format_time $CMD_DURATION 1)

  if test "$side" = right
    # duration
    if test -n "$duration"
      _r20_prompt_right_end
      _r20_color duration
      echo -n "$duration "
    end

    # Exit code
    if test "$exit_code" != 0
      _r20_prompt_right_end
      _r20_color error
      _r20_glyph error
      echo -n "$exit_code "
    end

    return
  end

  # blank line
  echo -e '\e[0K'

  # pwd/git
  if test -n "$gitroot"
    # pwd
    _r20_pwd "$gitroot"
    echo -n ' '

    # branch
    _r20_color branch
    echo -n (_r20_git_branch)' '

    # status
    if test "$fast" != "1" # bypass for placeholder
      _r20_color git_status
      _r20_git_ahead_behind
      _r20_prompt_git_symbols
    end
  else
    _r20_color path
    echo -n (prompt_pwd)' '
  end

  # end
  if test "$fast" = "1"
    _r20_prompt_end fastprompt
  else
    _r20_prompt_end prompt
  end
end

function _r20_color \
  --description 'Print a color code' \
  --argument-names token
  if test $token = 'git_status'
    set_color green
  else if test $token = 'prompt'
    set_color brblack
  else if test $token = 'fastprompt'
    set_color brblack
  else if test $token = 'branch'
    set_color brblack
  else if test $token = 'repo'
    set_color -o brblue
  else if test $token = 'path'
    set_color magenta
  else if test $token = 'error'
    set_color red
  else if test $token = 'duration'
    set_color reset
  else
    set_color reset
  end
end

function _r20_format_time \
  --description="Format milliseconds to a human readable format" \
  --argument-names milliseconds threshold
  
  # https://github.com/rafaelrinaldi/pure/blob/master/functions/_pure_format_time.fish
  if test $milliseconds -lt 0; return 1; end

  set --local seconds (math -s0 "$milliseconds / 1000 % 60")
  set --local minutes (math -s0 "$milliseconds / 60000 % 60")
  set --local hours (math -s0 "$milliseconds / 3600000 % 24")
  set --local days (math -s0 "$milliseconds / 86400000")
  set --local time

  if test $days -gt 0
      set time $time (printf "%sd" $days)
  end

  if test $hours -gt 0
      set time $time (printf "%sh" $hours)
  end

  if test $minutes -gt 0
      set time $time (printf "%sm" $minutes)
  end

  if test $seconds -gt $threshold
      set time $time (printf "%ss" $seconds)
  end

  echo -e (string join ' ' $time)
end

function _r20_git_ahead_behind \
  --description "Prints if ahead or behind (+1 -1)"
  # Get branch and the remote it tracks
  set -l branch (_r20_git_branch)
  if test -z "$branch"; return; end

  set -l remote (git config "branch.$branch.remote")

  # No remote means its not pushed at all
  if test -z "$remote";
    echo -n (_r20_glyph unpushed)' '
    return
  end

  set -l dirty false

  # List ahead/behind counts
  # https://stackoverflow.com/a/27940027
  git rev-list --left-right --count "$branch...$remote/$branch" \
    | read --local --array --null output
  if test (count $output) != 2; return; end

  # ahead (unpushed)
  if test $output[1] != '0'
    echo -n (_r20_glyph unpushed)"$output[1]"
    set dirty true
  end

  # behind (unpushed)
  if test $output[2] != '0'
    echo -n (_r20_glyph unpulled)"$output[2]"
    set dirty true
  end

  # trailing space
  if test $dirty = true
    echo -n ' '
  end
end
function _r20_git_branch --description 'Parse current Git branch name'
    command git symbolic-ref --short HEAD 2>/dev/null
    or command git name-rev --name-only HEAD 2>/dev/null
end

function _r20_git_is_dirty \
  --description 'Checks if a git repo has changes'
  test (git status -s 2>/dev/null | wc -c) -ne 0
end

function _r20_git_root --description 'Print the git root'
  printf '%s' (command git rev-parse --show-toplevel 2>/dev/null)
end

function _r20_glyph \
  --description 'Print a glpyh' \
  --argument-names token
  if test $token = 'prompt'
    echo -n '›'
  else if test $token = 'fastprompt'
    echo -n '›'
  else if test $token = 'right_end'
    echo -n '‹'
  else if test $token = 'separator'
    echo -n '╱' # separates extras, like cmd duration
  else if test $token = 'unpushed'
    echo -n '+'
  else if test $token = 'unpulled'
    echo -n '-'
  else if test $token = 'dirty'
    echo -n '·'
  else if test $token = 'error'
    echo -n '✗ '
  end
end

function _r20_prompt_git_symbols --description 'Git status prefix'
  if _r20_git_is_dirty
    echo -n (_r20_glyph dirty)' '
  end
end

function _r20_prompt_right_end
  echo -n (_r20_color prompt)
  echo -n (_r20_glyph right_end)' '
end

function _r20_prompt_end --argument-names style
  echo -n (_r20_color $style)
  echo -n (_r20_glyph $style)' '(set_color reset)
end

function _r20_pwd \
  --description 'Prints pwd based on Git root' \
  --argument-names gitroot
  set -l gitsubdir (pwd | sed -e "s|^$gitroot||")

  set -l prefix (
    _r20_color repo
    echo -n (_r20_color repo)(basename $gitroot)
  )

  if test (pwd) = $gitsubdir
    echo -n $prefix(_r20_color path)' @ '$gitsubdir
  else
    echo -n $prefix(_r20_color path)$gitsubdir
  end
end

