#!/usr/bin/env bash
# 重新生成「油迹-单文件预览.html」
# 用法：在 prototype 目录下运行  ./build-preview.sh
# 作用：把 index.html + style.css + data.js + app.js 打包成一个自包含 HTML，双击即可预览
set -e
cd "$(dirname "$0")"

python3 - <<'EOF'
html = open('index.html', encoding='utf-8').read()
css  = open('style.css', encoding='utf-8').read()
data = open('data.js',  encoding='utf-8').read()
app  = open('app.js',   encoding='utf-8').read()

html = html.replace('<link rel="stylesheet" href="style.css">', '<style>\n' + css + '\n</style>')
html = html.replace('<script src="data.js"></script>', '<script>\n' + data + '\n</script>')
html = html.replace('<script src="app.js"></script>',  '<script>\n' + app  + '\n</script>')

assert '<script src=' not in html, '还有外链脚本没内联成功'
out = '油迹-单文件预览.html'
open(out, 'w', encoding='utf-8').write(html)
print(f'已生成 {out}（{len(html)} 字节），双击即可预览')
EOF
