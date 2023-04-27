import json

def parse_tsconfig(file_path):
    try:
        with open(file_path, "r") as f:
            content = f.read()
        return json.loads(content)
    except FileNotFoundError:
        print("Error parsing tsconfig.json, file not found.")
        return None
    except json.JSONDecodeError:
        print("Error parsing tsconfig.json, invalid JSON format.")
        return None

# Other JSON parsing functions can be added here
