# 🤖 AI Server - Quick Start Guide

## Overview

The AI server extends your MCP environment with advanced AI capabilities, including:

- Cloud-based Claude AI integration
- Local Ollama model support
- Hybrid AI operations (cloud + local)
- Customizable AI behavior settings

## 🚀 Quick Start

```powershell
# Start AI Development workflow
.\START-MCP.ps1 -Workflow aiDevelopment

# Or use the dashboard
.\START-MCP.ps1 -Dashboard
# Then select [1] Start Workflow → aiDevelopment
```

## 📋 What's Included

The AI integration includes:

- **AI Server Configuration**: `configs/ai-config.json`
- **AI Behavior Settings**: `configs/ai-config.toml`
- **AI Development Workflow**: In master configuration
- **Dashboard Integration**: AI workflow in the MCP Dashboard

## ⚙️ Customizing AI Behavior

Edit the AI settings in `configs/ai-config.toml`:

```toml
# Change temperature (creativity level)
[ai.general]
temperature = 0.7  # Higher = more creative, Lower = more focused

# Set preferred model
[ai.models]
default_model = "claude-3-sonnet"  # Cloud AI
fallback_model = "codellama"       # Local AI (Ollama)

# Adjust personality
[ai.behavior]
personality = "professional"  # Options: professional, friendly, technical
```

## 🔄 Using Multiple AI Models

### Cloud Models (Claude)

For complex tasks requiring advanced reasoning:

```toml
[ai.models]
default_model = "claude-3-sonnet"
```

### Local Models (Ollama)

For privacy-sensitive work or offline use:

```toml
[ai.ollama]
enabled = true
host = "http://localhost:11434"
models = ["codellama", "llama2", "mistral"]
default_model = "codellama"
```

## 📊 Integration With Other MCP Servers

The AI server works seamlessly with other MCP servers:

- **Memory Server**: Persistent context and knowledge
- **Filesystem**: Access to files for analysis
- **GitHub**: Code repository integration
- **Web Search**: Real-time information gathering
- **Sequential Thinking**: Advanced reasoning capabilities

## 🛠️ Configuration Options

### AI Server Port

The AI server runs on port 7800 by default. To change this:

```json
// In configs/ai-config.json
{
  "options": {
    "port": 7800,
    "host": "localhost"
  }
}
```

### Memory Settings

Adjust how much context the AI retains:

```toml
[ai.memory]
context_window = 4000
memory_persistence = true
```

## 🔄 Running Ollama Locally

For local AI models:

1. **Install Ollama**
   ```powershell
   winget install Ollama.Ollama
   ```

2. **Start Ollama Service**
   ```powershell
   ollama serve
   ```

3. **Pull Models**
   ```powershell
   ollama pull codellama
   ollama pull mistral
   ```

## 🚀 Next Steps

1. Start exploring with: `.\START-MCP.ps1 -Workflow aiDevelopment`
2. Customize `configs/ai-config.toml` with your preferred settings
3. Try different AI models for various tasks

## 📝 Troubleshooting

- **AI Server Not Starting**: Check the logs at `logs/ai.log`
- **Model Not Found**: Ensure you've pulled the correct Ollama model
- **Connection Issues**: Verify Ollama is running with `ollama list`

---

Happy coding with your new AI-enhanced environment!

