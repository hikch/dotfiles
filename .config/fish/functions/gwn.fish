function gwn --description "Create or checkout git worktree with fzf"
    # 1. 既に使用中のブランチを取得
    set -l checked_out_branches (git worktree list --porcelain | grep "^branch" | sed 's/branch refs\/heads\///')

    # 2. ブランチ候補を取得して使用中のブランチを除外
    set -l all_branches (git branch -a --format="%(refname:short)" | sed 's/origin\///' | sort -u)
    set -l available_branches
    for branch in $all_branches
        if not contains $branch $checked_out_branches
            set -a available_branches $branch
        end
    end

    # 3. fzf で選択。入力も受け付ける。
    # --select-1: 候補が1つだけの時は自動選択
    # --print-query: 入力内容も出力
    set -l fzf_output (string join \n $available_branches | fzf \
        --query="$argv[1]" \
        --print-query \
        --header="↑↓: select | Enter: confirm | Type new name to create")

    # fzfの出力が空なら終了
    if test -z "$fzf_output"
        return
    end

    set -l query $fzf_output[1]
    set -l selection $fzf_output[2]

    # 4. ターゲットを決定
    # 選択が空、または選択がクエリと完全一致しない場合は、クエリを使う
    set -l target_branch
    if test -z "$selection"
        # 候補がない場合は query を新規ブランチ名として使う
        set target_branch $query
    else
        # 候補が選択された場合はそれを使う
        set target_branch $selection
    end

    # 確認プロンプト（クエリと選択が異なる場合）
    if test -n "$selection" -a "$selection" != "$query"
        echo (set_color yellow)"Selected: '$selection' (input was: '$query')"(set_color normal)
        read -l -P "Use? [y/i($query)/c(ancel)] " confirm
        switch $confirm
            case c C cancel
                echo (set_color blue)"Cancelled."(set_color normal)
                return 1
            case i I
                set target_branch $query
            case '*'
                # y or Enter: use selection (default)
                set target_branch $selection
        end
    end

    # 5. Worktreeの作成
    if git rev-parse --verify "$target_branch" >/dev/null 2>&1
        echo (set_color blue)"🌿 Using existing branch: $target_branch"(set_color normal)
        git worktree add "../$target_branch" "$target_branch"
    else
        echo (set_color green)"🌱 Creating new branch: $target_branch"(set_color normal)
        git worktree add -b "$target_branch" "../$target_branch"
    end

    # 6. 移動
    if test $status -eq 0
        cd "../$target_branch"
    end
end