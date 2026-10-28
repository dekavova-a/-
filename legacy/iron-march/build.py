"""Build a self-contained offline version using only the Python standard library."""
from pathlib import Path
import re

root = Path(__file__).resolve().parent
html = (root / 'index.html').read_text(encoding='utf-8')
css = (root / 'style.css').read_text(encoding='utf-8')
html = html.replace('<link rel="stylesheet" href="style.css">', '<style>\n' + css + '\n</style>')
for script in ('sim', 'render', 'app'):
    code = (root / 'src' / (script + '.js')).read_text(encoding='utf-8')
    html = html.replace('<script src="src/' + script + '.js"></script>', '<script>\n' + code + '\n</script>')
assert not re.search(r'<script[^>]+src=', html)
(root / 'START_GAME.html').write_text(html, encoding='utf-8')
print('START_GAME.html created: ' + str(len(html.encode('utf-8'))) + ' bytes')
