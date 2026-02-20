# MCP Server Setup Guide

This guide walks through setting up MCP (Model Context Protocol) servers for Claude Code. Each server gives Claude Code access to an external tool or data source, expanding what it can do beyond reading and writing files.

---

## Prerequisites

Before setting up any MCP server, ensure you have:

- **Node.js 18+**: Required for servers distributed as npm packages. Verify with `node --version`.
- **Python 3.10+**: Required for Python-based servers. Verify with `python3 --version`.
- **uvx**: Python package runner (like npx for Python). Install with `pip install uvx` or `pipx install uv`.
- **Docker**: Required if using the Docker MCP server or running databases in containers.

## Configuration Location

MCP servers are configured in your Claude Code settings. The configuration file location depends on your setup:

- **Project-level** (recommended): `.claude/mcp.json` in your project root.
- **User-level**: `~/.claude/mcp.json` for servers you use across all projects.

Copy the template from `mcp-config-template.json` and customise it for your project.

---

## Server Setup Instructions

### Filesystem Server

**Purpose:** Gives Claude Code read/write access to your project files.

**When you need it:** Claude Code already has file access through its built-in tools. This server is useful when you want to provide access to additional directories outside the project root (e.g., a shared component library, documentation repository).

**Setup:**
1. Copy the `filesystem` entry from the template.
2. Replace `/path/to/your/project` with the absolute path to the directory you want to expose.
3. You can add multiple paths as additional arguments.

**Verification:**
Ask Claude Code: "List the files in [your directory]." It should return the directory contents.

---

### Git Server

**Purpose:** Gives Claude Code direct access to Git operations: viewing history, diffs, branches, and making commits.

**When you need it:** For complex Git operations like analysing commit history, comparing branches, or understanding the evolution of specific files.

**Setup:**
1. Install the server: `pip install mcp-server-git` or use `uvx` (no install needed).
2. Copy the `git` entry from the template.
3. Replace `/path/to/your/project` with your Git repository root.

**Verification:**
Ask Claude Code: "Show me the last 5 commits." It should return your recent Git history.

---

### MySQL Server

**Purpose:** Gives Claude Code access to your MySQL database for schema inspection, query execution, and data analysis.

**When you need it:** When you want Claude Code to understand your database schema, debug data issues, write and test queries, or generate migrations based on the current schema state.

**Setup:**
1. Copy the `mysql` entry from the template.
2. Update the environment variables with your local database credentials:
   - `MYSQL_HOST`: Usually `localhost` for local development.
   - `MYSQL_PORT`: Usually `3306`.
   - `MYSQL_USER`: Your database username.
   - `MYSQL_PASSWORD`: Your database password.
   - `MYSQL_DATABASE`: The database name.

**Security:**
- Only use local development database credentials. Never configure production database access.
- Use a read-only database user if you only need schema inspection and SELECT queries.
- Consider creating a dedicated database user for Claude Code with limited permissions.

**Verification:**
Ask Claude Code: "Show me the tables in the database." It should return your table listing.

---

### PostgreSQL Server

**Purpose:** Same as MySQL but for PostgreSQL databases.

**Setup:**
1. Copy the `postgres` entry from the template.
2. Replace the connection string: `postgresql://username:password@localhost:5432/database`.

**Security:** Same precautions as MySQL — local development credentials only.

**Verification:**
Ask Claude Code: "Describe the schema of the customers table."

---

### Docker Server

**Purpose:** Gives Claude Code access to Docker: listing containers, inspecting configuration, reading logs, and managing images.

**When you need it:** When working with Docker Compose setups, debugging containerised services, or managing local development infrastructure.

**Setup:**
1. Ensure Docker is running: `docker ps` should work.
2. Copy the `docker` entry from the template. No configuration needed beyond the command.

**Verification:**
Ask Claude Code: "List all running Docker containers."

---

### Brave Search Server

**Purpose:** Gives Claude Code the ability to search the web for documentation, Stack Overflow answers, library APIs, and error message solutions.

**When you need it:** When Claude Code needs up-to-date information about libraries, frameworks, or APIs that may have changed after its training data cutoff.

**Setup:**
1. Get a Brave Search API key:
   - Go to https://brave.com/search/api/
   - Sign up for the free tier (2,000 queries/month).
   - Copy your API key.
2. Copy the `brave-search` entry from the template.
3. Replace `your-brave-api-key` with your actual API key.

**Verification:**
Ask Claude Code: "Search for the latest Spring Boot 4 release notes."

---

### Memory Server

**Purpose:** Gives Claude Code persistent memory across conversations. It can store and recall project context, architectural decisions, and ongoing task state.

**When you need it:** For long-running projects where you want Claude Code to remember decisions and context between sessions.

**Setup:**
1. Copy the `memory` entry from the template. No additional configuration needed.

**Verification:**
Ask Claude Code: "Remember that we decided to use UUID v7 for all new entities." In a later session, ask: "What ID strategy did we decide on?"

---

## Recommended Configurations

### Spring Boot + React SaaS Project

Use these servers:
- **Filesystem**: For project file access.
- **Git**: For version control operations.
- **MySQL**: For database schema inspection and query testing.
- **Docker**: For managing local infrastructure (MySQL, Kafka, Keycloak containers).
- **Brave Search**: For documentation lookups.

### Data Processing Project (Spark/Scala)

Use these servers:
- **Filesystem**: For project file access.
- **Git**: For version control.
- **Brave Search**: For Spark API documentation lookups.

### Minimal Setup

At minimum, configure:
- **Git**: Most universally useful for understanding project history and changes.
- **Brave Search**: For documentation and error resolution.

---

## Troubleshooting

### Server Fails to Start

1. Check that the required runtime is installed (`node`, `python3`, `uvx`).
2. Verify the server package can be downloaded: `npx -y @modelcontextprotocol/server-filesystem --help`.
3. Check Claude Code logs for error messages.

### Database Connection Refused

1. Verify the database is running: `docker ps` or `mysql -u root -p`.
2. Check the connection credentials match your local setup.
3. Ensure the database port is not blocked by a firewall.

### Permission Errors

1. Filesystem server: Ensure Claude Code has read/write access to the specified directories.
2. Docker server: Ensure the current user is in the `docker` group or Docker Desktop is running.
3. Git server: Ensure the repository path is correct and accessible.

### Server Works but Claude Code Does Not Use It

1. Restart Claude Code after changing MCP configuration.
2. Ask Claude Code explicitly: "Use the [server name] MCP server to [action]."
3. Verify the server appears in Claude Code's available tools list.
