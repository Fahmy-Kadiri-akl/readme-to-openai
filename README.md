# ReadMe.io to OpenAI Vector Store Script

This script extracts documentation from ReadMe.io (a documentation platform at readme.io), saves it to a local directory structure, and optionally uploads the documents to OpenAI for vector storage (for RAG applications).

The script specifically pulls documentation from **your organization's ReadMe.io documentation portal** (accessed through dash.readme.com). It preserves the hierarchical structure of the documentation (categories, docs, child docs, and grandchild docs) and transforms internal links to absolute URLs.

> **Note:** The script is hardcoded to convert ReadMe.io internal links to "https://docs.akeyless.io/docs/" format. You'll need to modify this URL in the script if your documentation is hosted at a different domain.

## Operation Modes

The script has two primary modes of operation:

### 1. Local-Only Mode (Default)

In this mode, the script:
- Downloads all documentation from ReadMe.io
- Organizes it into a structured directory tree on your local machine
- Converts internal links to absolute URLs
- Does not interact with OpenAI at all

**Required environment variables:**
- `README_API_KEY`
- `DOCS_BASE_URL`

**Command:**
```bash
nu readme-to-openai.nu
```

### 2. OpenAI Upload Mode

In this mode, the script does everything from local-only mode, plus:
- Uploads each document to OpenAI
- Adds each document to your Vector Store with metadata
- Creates a structured vector database for RAG applications

**Required environment variables:**
- All local-only variables, plus:
- `OPENAI_API_KEY`
- `VECTOR_STORE_ID`

**Command:**
```bash
nu readme-to-openai.nu --upload
```

If you run with `--upload` but haven't set the OpenAI environment variables, the script will automatically revert to local-only mode.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Running the Script](#running-the-script)
5. [Command Line Options](#command-line-options)
6. [Output Structure](#output-structure)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)

## Prerequisites

Before using this script, you need to have the following installed and set up:

### 1. Nushell

This script requires Nushell, a modern shell designed for working with structured data.

**For Windows:**
1. Download the installer from [Nushell's GitHub releases page](https://github.com/nushell/nushell/releases)
2. Run the installer and follow the prompts
3. Open a new command prompt or PowerShell window and type `nu` to enter Nushell

**For macOS:**
```bash
# Using Homebrew
brew install nushell
```

**For Linux:**
```bash
# Using a package manager (example for Ubuntu/Debian)
sudo apt update
sudo apt install nushell
```

### 2. API Keys

You will need:
- A ReadMe.io API key
- An OpenAI API key
- An OpenAI Vector Store ID

## Installation

1. **Download the script:**
   
   Create a new directory for your project:
   ```bash
   mkdir readme-to-openai
   cd readme-to-openai
   ```

   Create a file named `readme-to-openai.nu` and copy the entire script content into this file.

2. **Make the script executable:**
   
   ```bash
   chmod +x readme-to-openai.nu
   ```

## Configuration

### Setting Environment Variables

The script requires different environment variables depending on whether you're just extracting documentation or also uploading to OpenAI:

#### Always Required:
- `README_API_KEY` - Your ReadMe.io API key
- `DOCS_BASE_URL` - The base URL of your documentation

#### Required Only for OpenAI Upload (when using --upload flag):
- `OPENAI_API_KEY` - Your OpenAI API key
- `VECTOR_STORE_ID` - Your OpenAI Vector Store ID

**For Windows (Command Prompt):**
```cmd
set README_API_KEY=your_readme_api_key_here
set DOCS_BASE_URL=https://docs.yourcompany.com/docs

REM Only needed if using --upload flag:
set OPENAI_API_KEY=your_openai_api_key_here
set VECTOR_STORE_ID=your_vector_store_id_here
```

**For Windows (PowerShell):**
```powershell
$env:README_API_KEY = "your_readme_api_key_here"
$env:DOCS_BASE_URL = "https://docs.yourcompany.com/docs"

# Only needed if using --upload flag:
$env:OPENAI_API_KEY = "your_openai_api_key_here"
$env:VECTOR_STORE_ID = "your_vector_store_id_here"
```

**For macOS/Linux:**
```bash
export README_API_KEY=your_readme_api_key_here
export DOCS_BASE_URL=https://docs.yourcompany.com/docs

# Only needed if using --upload flag:
export OPENAI_API_KEY=your_openai_api_key_here
export VECTOR_STORE_ID=your_vector_store_id_here
```

> **Important:** For the `DOCS_BASE_URL` variable, replace "https://docs.yourcompany.com/docs" with the actual base URL of your documentation. This is typically the URL that appears before the document slug in your documentation links. Do not include a trailing slash.

### Where to Get These Keys

1. **ReadMe.io API Key:**
   - Log in to your ReadMe.io dashboard at https://dash.readme.com/
   - Go to Settings > API Keys
   - Create a new API key with read permissions
   
   > **Note:** The script is designed to work with ReadMe.io documentation only. It uses the ReadMe.io API to extract your documentation content, which is accessed through dash.readme.com.

2. **OpenAI API Key:**
   - Log in to your OpenAI account
   - Go to API keys section
   - Create a new API key

3. **Vector Store ID:**
   - Log in to OpenAI platform
   - Go to Vector Stores
   - Create a new Vector Store if you don't have one
   - Copy the ID of your Vector Store

## Running the Script

### Basic Usage (Local Only)

To run the script without uploading to OpenAI (local-only mode), you only need to set the `README_API_KEY` and `DOCS_BASE_URL` environment variables. Then run:

```bash
nu readme-to-openai.nu
```

This will:
- Download all documentation from your ReadMe.io instance
- Save it to the `data/docs` directory with proper directory structure
- Convert all internal links to absolute URLs
- NOT upload anything to OpenAI

### Uploading to OpenAI

To enable uploading to OpenAI's vector storage, set all four environment variables and add the `--upload` flag:

```bash
nu readme-to-openai.nu --upload
```

If you try to use the `--upload` flag without setting the OpenAI environment variables (`OPENAI_API_KEY` and `VECTOR_STORE_ID`), the script will automatically fall back to local-only mode and display a warning.

## Command Line Options

| Option | Short Flag | Description | Default |
|--------|------------|-------------|---------|
| `--upload` | `-u` | Upload documents to OpenAI | `false` |
| `--concurrency` | `-c` | Number of parallel processes | `4` |
| `--data-dir` | `-d` | Override default data directory | `data/docs` |
| `--rate-limit` | `-r` | Rate limit in milliseconds | `200` |
| `--verbose` | `-v` | Enable verbose output | `false` |
| `--parallel` | `-p` | Use parallel processing | `false` |
| `--resume` | `-R` | Resume from last checkpoint | `true` |

### Examples

**Process with parallel execution:**
```bash
nu readme-to-openai.nu --parallel
```

**Use a custom data directory:**
```bash
nu readme-to-openai.nu --data-dir="my-docs"
```

**Upload with higher concurrency and faster rate limit:**
```bash
nu readme-to-openai.nu --upload --concurrency=8 --rate-limit=100
```

## Output Structure

The script creates a directory structure that mirrors your ReadMe.io documentation hierarchy:

```
data/docs/
├── Category 1/
│   ├── doc-slug.md
│   ├── doc-slug.meta.json
│   ├── Parent Doc/
│   │   ├── child-doc-slug.md
│   │   ├── child-doc-slug.meta.json
│   │   └── Child Doc/
│   │       ├── grandchild-doc-slug.md
│   │       └── grandchild-doc-slug.meta.json
├── Category 2/
│   └── ...
└── ...
```

Each document will have:
- A `.md` file containing the document content
- A `.meta.json` file containing metadata about the document

## Checkpointing and Resuming

The script automatically creates checkpoints as it processes documents. If the script is interrupted, you can resume from where it left off by running the script with the `--resume` flag (enabled by default).

To force a fresh start (ignoring any existing checkpoint):
```bash
nu readme-to-openai.nu --resume=false
```

## Report Generation

After the script finishes, a `report.json` file is created containing statistics about the run:
- Start and end times
- Number of documents processed
- Number of documents uploaded
- Any errors encountered

## Documentation Base URL

The script uses the `DOCS_BASE_URL` environment variable to transform internal links to absolute URLs. This ensures that when the documentation is extracted, all internal references are converted to fully qualified URLs that will work anywhere.

For example, if your documentation is hosted at:
- https://docs.yourcompany.com/docs/getting-started
- https://docs.yourcompany.com/docs/api-reference

Then your `DOCS_BASE_URL` should be set to:
```
https://docs.yourcompany.com/docs
```

When the script processes internal references like `(doc:getting-started)`, it will transform them to `https://docs.yourcompany.com/docs/getting-started`.

## Troubleshooting

### "Error: Environment variable is not set"

The script requires different variables depending on your usage:

For local-only mode (default):
```bash
export README_API_KEY=your_key
export DOCS_BASE_URL=your_docs_url
```

For OpenAI upload mode (--upload flag):
```bash
export README_API_KEY=your_key
export DOCS_BASE_URL=your_docs_url
export OPENAI_API_KEY=your_key
export VECTOR_STORE_ID=your_id
```

Verify they're set correctly:
```bash
echo $README_API_KEY
echo $DOCS_BASE_URL
# Only for upload mode:
echo $OPENAI_API_KEY
echo $VECTOR_STORE_ID
```

### "Error: Vector store ID does not exist"

Verify your Vector Store ID is correct and accessible with your OpenAI API key. You can check your vector stores in the OpenAI dashboard.

### "Error: Failed HTTP request after X attempts"

This usually indicates:
- Network connectivity issues
- Rate limiting from ReadMe.io or OpenAI
- Incorrect API keys

Try increasing the `--rate-limit` value to slow down requests:
```bash
nu readme-to-openai.nu --rate-limit=500
```

### "Error: Failed to upload file"

Check that:
- Your OpenAI API key has proper permissions
- You haven't exceeded your API usage limits
- The file isn't too large (OpenAI has file size limits)

## FAQ

### How long will this take to run?

The time depends on:
- Number of documents in your ReadMe.io instance
- Your network speed
- Rate limits on both ReadMe.io and OpenAI APIs

For large documentation sets, it could take several hours.

### Will this overwrite existing files?

Yes, if files with the same names already exist in the output directory, they will be overwritten. If you want to keep previous runs, create a backup of the output directory before running the script again.

### How can I use the uploaded documents in OpenAI?

After uploading, your documents will be available in your OpenAI vector store. You can:
1. Use them with OpenAI Assistants
2. Query them via the OpenAI API
3. Build RAG (Retrieval Augmented Generation) applications

### Can I use this for multiple ReadMe.io instances?

Yes, but you'll need to:
1. Update the environment variables for each instance
2. Use different output directories with the `--data-dir` option

### How can I keep my documents up to date?

Run the script periodically to refresh your local copy and vector store. The script will process all documents each time it runs, unless you use filtering options.

## Support

If you encounter any issues not covered in this README, please check:
1. The script's error output
2. The generated `report.json` file
3. ReadMe.io and OpenAI documentation for API changes
