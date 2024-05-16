import os
from datetime import datetime

notes_dir = '.'
checklist_file = 'daily_checklist.md'
allowed_extensions = ['.md', '.pdf', '.docx', '.py', '.java', '.cpp']

def generate_checklist():
    today = datetime.now().strftime('%Y-%m-%d')
    checklist_content = f"## Daily Checklist for {today}\n\n"

    for root, dirs, files in os.walk(notes_dir):
        for file in files:
            if any(file.endswith(ext) for ext in allowed_extensions):
                filepath = os.path.join(root, file)
                # Exclude files in the .git directory
                if '.git' not in filepath:
                    checklist_content += f"- [ ] {file} - {filepath}\n"

    with open(checklist_file, 'w') as f:
        f.write(checklist_content)

    print(checklist_content)  # Debugging line

if __name__ == "__main__":
    generate_checklist()
