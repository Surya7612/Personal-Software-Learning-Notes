import os
from datetime import datetime

notes_dir = '.'
output_dir = 'daily_notes'
allowed_extensions = ['.md', '.pdf', '.docx', '.py', '.java', '.cpp']

def generate_checklist():
    today = datetime.now().strftime('%Y-%m-%d')
    checklist_filename = os.path.join(output_dir, f'daily_notes_{today}.md')
    checklist_content = f"## Daily Notes for {today}\n\n"
    today_start = datetime.combine(datetime.now(), datetime.min.time())
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for root, dirs, files in os.walk(notes_dir):
        for file in files:
            if any(file.endswith(ext) for ext in allowed_extensions):
                filepath = os.path.join(root, file)
                if '.git' not in filepath:
                    # Check the modification time
                    mod_time = datetime.fromtimestamp(os.path.getmtime(filepath))
                    if mod_time > today_start:
                        checklist_content += f"- {file} - {filepath}\n"

    with open(checklist_filename, 'w') as f:
        f.write(checklist_content)

    print(checklist_content)  # Debugging line

if __name__ == "__main__":
    generate_checklist()
