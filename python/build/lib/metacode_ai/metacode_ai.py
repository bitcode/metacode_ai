import json
import os
import toml
from pathlib import Path
import pynvim
import requests

from langchain.llms import OpenAI
from langchain.prompts import PromptTemplate
from langchain.prompts import StringPromptTemplate
from pydantic import BaseModel, validator
from langchain.llms import OpenAI
from langchain.agents import load_tools
from langchain.agents import initialize_agent
from langchain.agents import AgentType
from langchain.retrievers import ContextualCompressionRetriever
from langchain.retrievers.document_compressors import LLMChainExtractor
from langchain.utilities import SerpAPIWrapper

from .json_parser import parse_tsconfig
from .toml_parser import parse_cargo_toml

from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get API keys from environment variables
API_KEYS = {
    "openai_api_key": os.getenv("OPENAI_API_KEY"),
    "cohere_api_key": os.getenv("COHERE_API_KEY"),
    "gooseai_api_key": os.getenv("GOOSEAI_API_KEY"),
    "huggingfacehub_api_token": os.getenv("HUGGINGFACEHUB_API_TOKEN"),
    "huggingface_api_key": os.getenv("HUGGINGFACE_API_KEY"),
    "cerebriumai_api_key": os.getenv("CEREBRIUMAI_API_KEY"),
    "serpapi_api_key": os.getenv("SERPAPI_API_KEY"),
    "google_api_key": os.getenv("GOOGLE_API_KEY"),
    "google_cse_id": os.getenv("GOOGLE_CSE_ID"),
    "wolfram_alpha_appid": os.getenv("WOLFRAM_ALPHA_APPID"),
}

# Define the LangChain API URL
LANGCHAIN_API_URL = "https://api.langchain.io/v1/chain"

# Create a LanguageModelModule for LangChain
langchain_llm = OpenAI(
    model_name="text-davinci-003",
    api_key=API_KEYS['openai_api_key']
)

# Initialize SerpApi agent
def create_serpapi_agent():
    params = {
        "engine": "bing",
        "gl": "us",
        "hl": "en",
    }
    return SerpAPIWrapper(params=params)

# Define a PromptTemplate to manage and format prompts sent to LangChain API
class CustomPromptTemplate(StringPromptTemplate, BaseModel):
    package: str
    version: str
    user_question: str

    @validator("package", "version", "user_question", pre=True, each_item=True, allow_reuse=True)
    def _validate(cls, value):
        if value is None:
            raise ValueError("Value cannot be None.")
        return value

    def format(self):
        return f"I am working with {self.package} version {self.version} in my project. Please provide the most relevant and up-to-date information and documentation to help me understand how to use this specific version effectively. My question is: {self.user_question}"

    prompt_template = CustomPromptTemplate(package="", version="", user_question="")

# Define a class for interacting with the LangChain API
class LangChainClient:
    def __init__(self, compression_retriever):  # Add the compression_retriever argument
        self.session = requests.Session()
        self.compression_retriever = compression_retriever  # Save the retriever instance
        # Set up headers for API authentication
        self.session.headers.update(
            {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {API_KEYS['openai_api_key']}",
            }
        )

    def query_langchain(self, prompt, package_versions):
        # Use the compression_retriever to get relevant documents
        relevant_documents = self.compression_retriever.get_relevant_documents(
            prompt)
        # Process the relevant_documents as required
        # ...
        payload = {
            "prompt": prompt,
            "package_versions": package_versions,
            "max_tokens": 2048,
            "temperature": 0.5,
        }
        response = self.session.post(LANGCHAIN_API_URL, json=payload)
        response.raise_for_status()
        return response.json()

# Set up the DocumentCompressor and ContextualCompressionRetriever instances
compressor = LLMChainExtractor.from_llm(OpenAI(api_key=API_KEYS['openai_api_key'], temperature=0))
compression_retriever = ContextualCompressionRetriever(
    base_compressor=compressor, base_retriever=base_retriever)

# Instantiate the LangChainClient with the compression_retriever instance
langchain_client = LangChainClient(compression_retriever)

def get_project_info(project_root):
    tsconfig_path = project_root / "tsconfig.json"
    package_json_path = project_root / "package.json"
    cargo_toml_path = project_root / "Cargo.toml"

    tsconfig = None
    package_json = None
    cargo_toml = None

    if tsconfig_path.is_file():
        tsconfig = parse_tsconfig(tsconfig_path)

    if package_json_path.is_file():
        with open(package_json_path, "r") as f:
            package_json = json.load(f)

    if cargo_toml_path.is_file():
        cargo_toml = parse_cargo_toml(cargo_toml_path)

    return tsconfig, package_json, cargo_toml

def extract_package_versions(tsconfig, package_json, cargo_toml):
    package_versions = {}

    if package_json:
        package_versions.update(package_json.get("dependencies", {}))
        package_versions.update(package_json.get("devDependencies", {}))

    if cargo_toml:
        package_versions.update(cargo_toml.get("dependencies", {}))

    return package_versions

def set_prompt_variables(package_name, package_version, user_question):
    prompt_template.package = package_name
    prompt_template.version = package_version
    prompt_template.user_question = user_question

@pynvim.function("MetaCodeAIQuery", sync=True)
def MetaCodeAIQuery(nvim, args):
    package_name = args[0]
    package_version = args[1]
    user_question = args[2]

    user_prompt = prompt_template.render()
    updated_suggestion = get_latest_documentation(package_name, package_version, user_prompt)

    tsconfig, package_json, cargo_toml = get_project_info(project_root)

    package_versions = extract_package_versions(
        tsconfig, package_json, cargo_toml)

    package_version = package_versions.get(package_name)

    if not package_version:
        nvim.command(f'echo "Package {package_name} not found in the project"')
        return

    set_prompt_variables(package_name, package_version, user_question)

    try:
        response = langchain_client.query_langchain(prompt_template.render(), package_versions)
    except requests.RequestException as e:
        nvim.err_write(f"Error while querying LangChain API: {str(e)}\n")
        return

    answer = response["choices"][0]["text"] if response["choices"] else "No answer found"

    buf = nvim.api.create_buf(False, True)
    nvim.api.buf_set_lines(buf, 0, -1, True, answer.splitlines())

@pynvim.plugin
class MetaCodeAIPlugin:
    def __init__(self, nvim):
        self.nvim = nvim

    @pynvim.command("MetaCodeAI", nargs="*", sync=True)
    def MetaCodeAI_command(self, args):
        self.nvim.call_function("MetaCodeAIQuery", args)
