import re

file_path = 'lib/features/agent/customers/lookup_client_screen.dart'
with open(file_path, 'r') as f:
    content = f.read()

# Let's inspect the exact lines where `!isBackdated` is
for line in content.split('\n'):
    if '!isBackdated' in line:
        print(line)
