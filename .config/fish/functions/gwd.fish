function gwd --description "Remove current worktree and return to main"
    set -l main_dir (git rev-parse --path-format=absolute --git-common-dir)/..
    set -l current_worktree (pwd)

    # メインディレクトリへ移動
    cd $main_dir

    # worktreeを削除
    echo (set_color red)"🗑  Removing worktree: $current_worktree"(set_color normal)
    git worktree remove -f "$current_worktree"
end