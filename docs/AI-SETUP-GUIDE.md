# AI Setup and Configuration Guide

## 🤖 Overview

This guide explains how to set up and customize AI behavior in your environment, including both cloud-based AI (Claude) and local AI models (Ollama).

## 📂 Configuration Locations

### Main Configuration Files

- `configs/ai-config.toml`: Primary AI behavior settings
- `configs/memory-config.json`: AI memory and context settings
- `resources/memory-store/`: Persistent memory storage

### Model Locations

- **Claude**: Cloud-based, no local storage
- **Ollama**: Local models at `%USERPROFILE%/.ollama/models/`

## 🚀 Setting Up Ollama

1. **Install Ollama**

```powershell
# Download and install Ollama
winget install Ollama.Ollama

# Start Ollama service
ollama serve
```

2. **Pull Models**

```powershell
# Pull recommended models
ollama pull codellama  # Best for coding
ollama pull llama2     # General purpose
ollama pull mistral    # Fast, efficient
```

3. **Test Installation**

```powershell
# Test Ollama
ollama run codellama "Write a hello world in Python"
```

## ⚙️ Customizing AI Behavior

### Temperature Control

```toml
[ai.general]
temperature = 0.7  # Higher = more creative, Lower = more focused
```

### Personality Settings

```toml
[ai.behavior]
personality = "professional"  # Options: professional, friendly, technical
expertise_level = "expert"   # Options: beginner, intermediate, expert
```

### Model Selection

```toml
[ai.models]
default_model = "claude-3-sonnet"  # Cloud AI
fallback_model = "codellama"       # Local AI
```

## 🔄 Integration Options

### 1. Cloud AI (Claude)

- Best for: Complex tasks, natural language
- Requires: Internet connection, API key
- Location: Cloud-based, no local storage

### 2. Local AI (Ollama)

- Best for: Offline work, privacy
- Storage: `%USERPROFILE%/.ollama/models/`
- Models: CodeLlama, Llama2, Mistral

### 3. Hybrid Setup

```toml
[ai.ollama]
enabled = true
fallback = true  # Use when cloud AI is unavailable
```

## 📝 Memory and Context

### Storage Location

- Primary: `resources/memory-store/`
- Format: JSON files for persistence
- Backup: `backups/` directory

### Configuration

```toml
[ai.memory]
context_window = 4000
memory_persistence = true
```

## 🛠️ Advanced Customization

### Custom Model Parameters

```toml
[ai.models.custom]
name = "my-codellama"
base = "codellama"
parameters = { temp = 0.8, top_p = 0.9 }
```

### Behavior Templates

```toml
[ai.templates]
coding = { style = "clean", documentation = "detailed" }
research = { depth = "thorough", citations = true }
```

## 🔒 Security

### API Keys

- Store in environment variables
- Never in configuration files
- Use `MCP_AI_KEY` for Claude

### Access Control

```toml
[ai.security]
api_key_required = true
allowed_domains = ["localhost"]
```

## 📊 Monitoring

### Logs Location

- Main: `logs/ai-interactions.log`
- Format: JSON structured logging
- Rotation: 10MB files, 5 files max

## 🚫 Common Issues

1. **Ollama Not Starting**

   ```powershell
   # Check Ollama service
   ollama serve
   # Should show "Ollama is running"
   ```

2. **Memory Issues**
   - Clear cache: `Remove-Item resources/memory-store/* -Force`
   - Adjust context: Lower `context_window` in config

3. **Model Loading Slow**
   - Use smaller models
   - Check disk space
   - Monitor resource usage

## 🔄 Updates and Maintenance

### Updating Models

```powershell
# Update Ollama models
ollama pull codellama:latest
```

### Backup Configuration

```powershell
# Backup AI settings
Copy-Item configs/ai-config.toml backups/
```

## 📚 Resources

- [Ollama Documentation](https://ollama.ai/docs)
- [Claude API Reference](https://docs.anthropic.com/claude/reference)
- [Local AI Models Guide](https://ollama.ai/library)

---

Remember: Always backup your configuration before making changes!
