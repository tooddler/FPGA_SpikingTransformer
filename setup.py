import os
import re
import sys

def main():
    if len(sys.argv) < 2:
        print("Error: Please provide REAL_PATH")
        print("Usage: python replace_includes.py <REAL_PATH>")
        sys.exit(1)

    REAL_PATH = sys.argv[1].replace("\\", "/")
    print(f"Target Path: {REAL_PATH}")

    for root, _, files in os.walk("."):
        for file in files:
            if file.endswith(".v"):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r+', encoding='utf-8') as f:
                        content = f.read()
                        # 直接匹配 `include 并替换其后所有内容
                        new_content = re.sub(
                            r'(`include\s+).*',
                            rf'\1"{REAL_PATH}"',
                            content
                        )
                        if new_content != content:
                            f.seek(0)
                            f.write(new_content)
                            f.truncate()
                            print(f"Updated: {file_path}")
                except Exception as e:
                    print(f"Failed: {file_path} ({str(e)})")

if __name__ == "__main__":
    main()