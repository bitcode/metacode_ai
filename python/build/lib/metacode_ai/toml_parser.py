import toml

def parse_cargo_toml(file_path):
    try:
        return toml.load(file_path)
    except FileNotFoundError:
        print("Error parsing Cargo.toml, file not found.")
        return None
    except toml.TomlDecodeError:
        print("Error parsing Cargo.toml, invalid TOML format.")
        return None

# Other TOML parsing functions can be added here
