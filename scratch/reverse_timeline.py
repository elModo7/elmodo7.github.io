with open('about.html', 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if '<div class="timeline">' in line:
        start_idx = i
    if '<i class="fas fa-clock bg-gray"></i>' in line:
        end_idx = i + 1

timeline_prefix = lines[:start_idx + 1]
timeline_suffix = lines[end_idx:]

timeline_content = lines[start_idx + 1 : end_idx]
clock_idx = -1
for i, line in enumerate(timeline_content):
    if '<i class="fas fa-clock bg-gray"></i>' in line:
        clock_idx = i - 1  # The div wraps the i tag

# the clock item is 3 lines: div, i, /div
clock_item = timeline_content[clock_idx:]
timeline_content = timeline_content[:clock_idx]

# Split timeline_content into blocks based on indentation
blocks = []
current_block = []
indentation = None

for line in timeline_content:
    if line.strip() == '': continue
    if indentation is None:
        leading = len(line) - len(line.lstrip('\t'))
        indentation = '\t' * leading

    if line.startswith(indentation + '<div'):
        if current_block:
            blocks.append(current_block)
        current_block = [line]
    else:
        current_block.append(line)
        
if current_block:
    blocks.append(current_block)

# A group starts with a time-label.
groups = []
current_group = []
for b in blocks:
    if 'time-label' in b[0]:
        if current_group:
            groups.append(current_group)
        current_group = [b]
    else:
        current_group.append(b)
if current_group:
    groups.append(current_group)

# Reverse the groups, and inside each group, reverse the items
reversed_groups = reversed(groups)

new_timeline_content = []
for g in reversed_groups:
    time_label = g[0]
    items = g[1:]
    items = list(reversed(items))
    new_timeline_content.extend(time_label)
    for item in items:
        new_timeline_content.extend(item)

# Reassemble
new_lines = timeline_prefix + new_timeline_content + clock_item + timeline_suffix

with open('about.html', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print('Done reversing timeline')
