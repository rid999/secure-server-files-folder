<pre> ``` This is plain text in a code box Multiple lines supported ``` </pre>
```
# Permission Scanner & Fixer (Universal)

## 1. Purpose
This script is designed to **scan and fix file and directory permissions** within a user-defined path.  
It ensures that files and folders follow secure permission standards while allowing the user to review and confirm changes manually.

## 2. Benefits
- **Improved security** by enforcing safe permission levels.
- **Flexible usage** for any type of project or server path (not tied to a specific CMS or platform).
- **Human-in-the-loop** decision-making to avoid careless automation.
- **Interactive scanning** with detailed issue reports.
- **Excludes common heavy folders** (`.git`, `node_modules`, `vendor`, `__pycache__`) for faster scans.

## 3. Usage
1. Clone or download the script:
   ```bash
   git clone https://github.com/yourusername/permission-scanner-fixer.git
   cd permission-scanner-fixer
   chmod +x permission_scanner_fixer.sh
