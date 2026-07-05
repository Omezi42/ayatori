import re

# Read original LevelManager.gd
with open(r'c:\Users\omezi\Documents\ayatori\scripts\LevelManager.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Read new stages
with open(r'c:\Users\omezi\Documents\ayatori\new_stages.txt', 'r', encoding='utf-8') as f:
    new_stages_content = f.read()
    
# Process the original level configs to add layout_id: 0
def replacer(match):
    # match.group(0) is like '{"name": "さんかく", "target": [1, 5, 8], "optimal_moves": 5}'
    s = match.group(0)
    # just insert `"layout_id": 0, ` before `"optimal_moves"` or at the end
    return s.replace('}', ', "layout_id": 0}')

content = re.sub(r'\{"name":[^}]+}', replacer, content)

# Now we need to append the new stages before the end of the array `]`
# Find the array end.
# It ends with `		{"name": "メイズ", "target": [0, 4, 8, 3, 7, 1, 5, 9, 2, 6], "optimal_moves": 6, "layout_id": 0} # score: 334.0 (om:6, i:29, v:10, str:4.0)`
# wait, there's a newline and `	]`

new_lines = []
for line in new_stages_content.splitlines():
    if line.strip():
        # new stages end with `,`
        new_lines.append("\t\t" + line.strip())

new_stages_str = "\n".join(new_lines)
# Remove the trailing comma from the original last element
content = content.replace(', "layout_id": 0} # score: 334.0', ', "layout_id": 0}, # score: 334.0')
# Actually, the original last element does not have a trailing comma:
# `{"name": "メイズ", "target": [0, 4, 8, 3, 7, 1, 5, 9, 2, 6], "optimal_moves": 6} # score: 334.0 (om:6, i:29, v:10, str:4.0)`
content = re.sub(r'(\{"name": "メイズ".+?\}\s*#.*?)$', r'\1,\n' + new_stages_str, content, flags=re.MULTILINE)

# Remove the trailing comma from the last new stage
content = content.replace(' "layout_id": 2},', ' "layout_id": 2}')

# Also we need to modify the LevelData instantiation loop
content = content.replace(
    'if config.has("optimal_moves"):',
    'if config.has("layout_id"):\n\t\t\tlevel.layout_id = config["layout_id"]\n\t\tif config.has("optimal_moves"):'
)

with open(r'c:\Users\omezi\Documents\ayatori\scripts\LevelManager.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print("LevelManager.gd updated.")
