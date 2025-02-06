#!/bin/bash

# 检查是否提供了 commit message
if [ -z "$1" ]; then
    echo "❌ 错误: 请提供 commit message!"
    echo "示例: ./SubmitToGit.sh 'Update README'"
    exit 1
fi

# 添加所有文件
git add .

# 提交代码，使用传入的 commit message
git commit -m "$1"

# 推送到 GitHub
git branch -M main
git push -u origin main