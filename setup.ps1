# 检查是否提供了REAL_PATH参数
if ($args.Count -eq 0) {
    Write-Host "错误：请提供REAL_PATH参数"
    Write-Host "用法: .\setup.ps1 <REAL_PATH>"
    exit 1
}

# 获取REAL_PATH参数
$REAL_PATH = $args[0]
$REAL_PATH = $REAL_PATH.Replace("\", "/")

Write-Host "使用的REAL_PATH: $REAL_PATH"

# 查找所有.v文件并修改include语句
Get-ChildItem -Path . -Filter "*.v" -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $newContent = $content -replace "`include\s+[`"'].*hyper_para\.v[`"']", "`include `"$REAL_PATH`""
    Set-Content -Path $_.FullName -Value $newContent
    Write-Host "已修改文件: $($_.FullName)"
}

Write-Host "所有文件中的hyper_para.v引用已更新为使用REAL_PATH" 