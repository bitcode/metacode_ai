from setuptools import setup, find_packages

setup(
    name="metacode-ai-neovim-plugin",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "toml",
        "pynvim",
        "requests",
        "langchain",
        "python-dotenv",
    ],
    entry_points={
        "console_scripts": [
            "metacode-ai = metacode_ai.main:main"
        ]
    },
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
    ],
    python_requires=">=3.7",
)
