import json
import os
import toml
from pathlib import Path
import pynvim
import requests

from langchain import Chain, LanguageModelModule, PromptTemplate
from langchain.llms import OpenAI
from langchain.retrievers import ContextualCompressionRetriever
from langchain.retrievers.document_compressors import LLMChainExtractor

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
langchain_llm = LanguageModelModule(
    LANGCHAIN_API_URL,
    headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEYS['openai_api_key']}",
    },
    method="post",
    **API_KEYS
)

# Define a PromptTemplate to manage and format prompts sent to LangChain API
prompt_template = PromptTemplate(
    "I am working with {package} version {version} in my project. "
    "Please provide the most relevant and up-to-date information and "
    "documentation to help me understand how to use this specific version "
    "effectively. My question is: {user_question}"
)

# Create a Chain with the langchain_llm and prompt_template
langchain_chain = Chain(langchain_llm, prompt_template)

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
        relevant_documents = self.compression_retriever.get_relevant_documents(prompt)
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

# Instantiate a LangChainClient with the compression_retriever instance
langchain_client = LangChainClient(compression_retriever)

# Set up the DocumentCompressor and ContextualCompressionRetriever instances
compressor = LLMChainExtractor.from_llm(OpenAI(temperature=0))
compression_retriever = ContextualCompressionRetriever(base_compressor=compressor, base_retriever=base_retriever)

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

def set_prompt_variables(package_name, package_version, user_question):
    prompt_template.set_variables(package=package_name, version=package_version, user_question=user_question)

@pynvim.function("MetaCodeAIQuery", sync=True)
def MetaCodeAIQuery(nvim, args):
    package_name = args[0]
    project_root = Path(args[1])
    user_question = args[2]  # Add this line to get the user's question

    tsconfig, package_json, cargo_toml = get_project_info(project_root)

    package_versions = extract_package_versions(tsconfig, package_json, cargo_toml)

    package_version = package_versions.get(package_name)

    if not package_version:
        nvim.command(f'echo "Package {package_name} not found in the project"')
        return

    set_prompt_variables(package_name, package_version, user_question)  # Update this line

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
