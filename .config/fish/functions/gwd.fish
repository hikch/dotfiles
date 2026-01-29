function gwd --description "Remove current worktree and return to main"
    # オプション解析
    argparse 'f/force' -- $argv
    or return

    set -l main_dir (git rev-parse --path-format=absolute --git-common-dir)/..
    set -l current_worktree (pwd)

    # 確認プロンプト
    echo (set_color yellow)"🗑  Remove worktree: $current_worktree"(set_color normal)
    read -l -P "Are you sure? [y/N] " confirm

    if test "$confirm" != "y" -a "$confirm" != "Y"
        echo (set_color blue)"Cancelled."(set_color normal)
        return 1
    end

    # メインディレクトリへ移動
    cd $main_dir

    # worktreeを削除
    echo (set_color red)"Removing..."(set_color normal)
    if set -q _flag_force
        git worktree remove -f "$current_worktree"
    else
        git worktree remove "$current_worktree"
    end
end