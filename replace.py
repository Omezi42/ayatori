import re

with open('c:/Users/omezi/Documents/ayatori/scripts/LevelManager.gd', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r',\s*"optimal_moves":\s*\d+', '', content)

with open('c:/Users/omezi/Documents/ayatori/scripts/LevelManager.gd', 'w', encoding='utf-8') as f:
    f.write(content)
