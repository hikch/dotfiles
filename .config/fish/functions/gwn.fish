function gwn --description "Create or checkout git worktree with fzf"
    # 1. ブランチ候補を取得して fzf で選択。入力も受け付ける。
    set -l fzf_output (git branch -a --format="%(refname:short)" | sed 's/origin\///' | sort -u | fzf --query="$argv[1]" --select-1 --exit-0 --print-query)
    
    # fzfの出力が空なら終了
    if test -z "$fzf_output"
        return
    end

    set -l query $fzf_output[1]
    set -l branch $fzf_output[2]

    # 2. ターゲットを決定
    set -l target_branch
    if test -z "$branch"
        set target_branch $query
    else
        set target_branch $branch
    end

    # 3. Worktreeの作成
    if git rev-parse --verify "$target_branch" >/dev/null 2>&1
        echo (set_color blue)"🌿 Using existing branch: $target_branch"(set_color normal)
        git worktree add "../$target_branch" "$target_branch"
    else
        echo (set_color green)"🌱 Creating new branch: $target_branch"(set_color normal)
        git worktree add -b "$target_branch" "../$target_branch"
    end

    # 4. 移動
    if test $status -eq 0
        cd "../$target_branch"
    end
end