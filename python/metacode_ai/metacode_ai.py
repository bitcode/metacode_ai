import json
import os
import toml
from pathlib import Path
import pynvim
import requests

from langchain import Chain, LanguageModelModule, PromptTemplate

from .json_parser import parse_tsconfig
from .toml_parser import parse_cargo_toml

from .api_keys import (
    OPENAI_API_KEY,
    COHERE_API_KEY,
    GOOSEAI_API_KEY,
    HUGGINGFACEHUB_API_TOKEN,
    HUGGINGFACE_API_KEY,
    CEREBRIUMAI_API_KEY,
    SERPAPI_API_KEY,
    GOOGLE_API_KEY,
    GOOGLE_CSE_ID,
    WOLFRAM_ALPHA_APPID,
)

API_KEYS = {
    "openai_api_key": OPENAI_API_KEY,
    "cohere_api_key": COHERE_API_KEY,
    "gooseai_api_key": GOOSEAI_API_KEY,
    "huggingfacehub_api_token": HUGGINGFACEHUB_API_TOKEN,
    "huggingface_api_key": HUGGINGFACE_API_KEY,
    "cerebriumai_api_key": CEREBRIUMAI_API_KEY,
    "serpapi_api_key": SERPAPI_API_KEY,
    "google_api_key": GOOGLE_API_KEY,
    "google_cse_id": GOOGLE_CSE_ID,
    "wolfram_alpha_appid": WOLFRAM_ALPHA_APPID,
}

# Create a LanguageModelModule for LangChain
langchain_llm = LanguageModelModule(
    LANGCHAIN_API_URL,
    headers={"Content-Type": "application/json"},
    method="post",
    **API_KEYS
)

# Define a PromptTemplate to manage and format prompts sent to LangChain API
prompt_template = PromptTemplate("How to use {package} version {version}?")

# Create a Chain with the langchain_llm and prompt_template
langchain_chain = Chain(langchain_llm, prompt_template)

# Define a class for interacting with the LangChain API
class LangChainClient:
    def __init__(self):
        self.session = requests.Session()
        # Set up headers for API authentication
        self.session.headers.update(
            {
                "Content-Type": "application/json",
            }
        )

    def query_langchain(self, prompt, package_versions):
        payload = {
            "prompt": prompt,
            "package_versions": package_versions,
            "max_tokens": 2048,
            "temperature": 0.5,
        }
        response = self.session.post(LANGCHAIN_API_URL, json=payload)
        response.raise_for_status()
        return response.json()

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

# Other parse functions remain the same

def get_project_info(project_root):
    # Same implementation as before

def extract_package_versions(tsconfig, package_json, cargo_toml):
    package_versions = {}

    if package_json:
        package_versions.update(package_json.get("dependencies", {}))
        package_versions.update(package_json.get("devDependencies", {}))

    if cargo_toml:
        package_versions.update(cargo_toml.get("dependencies", {}))

    return package_versions

@pynvim.function("MetaCodeAIQuery", sync=True)
def MetaCodeAIQuery(nvim, args):
    package_name = args[0]
    project_root = Path(args[1])

    tsconfig, package_json, cargo_toml = get_project_info(project_root)

    package_versions = extract_package_versions(tsconfig, package_json, cargo_toml)

    package_version = package_versions.get(package_name)

    if not package_version:
        nvim.command(f'echo "Package {package_name} not found in the project"')
        return

    prompt_template.set_variables(package=package_name, version=package_version)

    try:
        response = langchain_chain.run()
    except requests.RequestException as e:
        nvim.err_write(f"Error while querying LangChain API: {str(e)}\n")
        return

    answer = response["choices"][0]["text"] if response["choices"] else "No answer found"

    buf = nvim.api.create_buf(False, True)
    nvim.api.buf_set_lines(buf, 0, -1, True, answer.splitlines())

    width = min(80, nvim.api.win_get_width(0))

# Neovim plugin class for MetaCodeAI
@pynvim.plugin
class MetaCodeAIPlugin:
    def __init__(self, nvim):
        self.nvim = nvim
