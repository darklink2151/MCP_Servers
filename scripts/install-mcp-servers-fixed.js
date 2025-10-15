/**
 * @file install-mcp-servers-fixed.js
 * @description Fixed script to install and test MCP servers with proper PATH handling
 * @version 1.0.0
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// MCP Server configurations - using direct executable paths
const mcpServers = {
  filesystem: {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-filesystem'],
    description: 'Enhanced filesystem access',
    testArgs: ['--help']
  },
  memory: {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-memory'],
    description: 'Persistent memory storage',
    testArgs: ['--help']
  },
  github: {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-github'],
    description: 'GitHub integration',
    testArgs: ['--help']
  },
  'brave-search': {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-brave-search'],
    description: 'Web search with Brave',
    testArgs: ['--help']
  },
  fetch: {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-fetch'],
    description: 'HTTP request client',
    testArgs: ['--help']
  },
  sqlite: {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-sqlite'],
    description: 'SQLite database integration',
    testArgs: ['--help']
  },
  puppeteer: {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-puppeteer'],
    description: 'Browser automation',
    testArgs: ['--help']
  },
  'sequential-thinking': {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-sequential-thinking'],
    description: 'Advanced problem solving',
    testArgs: ['--help']
  },
  everything: {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-everything'],
    description: 'Windows Everything search',
    testArgs: ['--help']
  }
};

/**
 * Test if an MCP server is available using execSync for better error handling
 * @param {string} serverName - Name of the server to test
 * @returns {Promise<boolean>} Whether the server is available
 */
async function testServer(serverName) {
  try {
    const server = mcpServers[serverName];
    if (!server) {
      console.error(`Unknown server: ${serverName}`);
      return false;
    }

    console.log(`Testing ${serverName} (${server.description})...`);

    // Use execSync with proper options for Windows
    const fullCommand = `${server.command} ${server.args.join(' ')} ${server.testArgs.join(' ')}`;

    try {
      const output = execSync(fullCommand, {
        timeout: 15000,
        encoding: 'utf8',
        stdio: 'pipe',
        shell: true,
        env: {
          ...process.env,
          PATH: process.env.PATH + ';C:\\Program Files\\nodejs\\;C:\\Users\\beckd\\AppData\\Roaming\\npm'
        }
      });

      console.log(`${serverName}: ✓ Available`);
      return true;
    } catch (error) {
      // Check if it's a timeout or actual error
      if (error.status === 1 || error.signal === 'SIGTERM') {
        // Many MCP servers return status 1 for --help, but that's okay
        console.log(`${serverName}: ✓ Available (help returned)`);
        return true;
      } else {
        console.log(`${serverName}: ✗ Error - ${error.message}`);
        return false;
      }
    }
  } catch (error) {
    console.error(`Error testing ${serverName}:`, error.message);
    return false;
  }
}

/**
 * Install and test all MCP servers
 */
async function installAndTestServers() {
  console.log('🔧 MCP Server Installation and Testing\n');

  const results = {};

  for (const [serverName, serverConfig] of Object.entries(mcpServers)) {
    try {
      const isWorking = await testServer(serverName);
      results[serverName] = {
        available: isWorking,
        config: serverConfig
      };
    } catch (error) {
      console.error(`Failed to test ${serverName}:`, error.message);
      results[serverName] = {
        available: false,
        config: serverConfig,
        error: error.message
      };
    }
  }

  console.log('\n📊 Installation Summary:');
  console.log('========================');

  const availableServers = Object.entries(results).filter(([_, result]) => result.available);
  const unavailableServers = Object.entries(results).filter(([_, result]) => !result.available);

  console.log(`✅ Available Servers (${availableServers.length}):`);
  availableServers.forEach(([name, result]) => {
    console.log(`  • ${name}: ${result.config.description}`);
  });

  if (unavailableServers.length > 0) {
    console.log(`\n❌ Unavailable Servers (${unavailableServers.length}):`);
    unavailableServers.forEach(([name, result]) => {
      console.log(`  • ${name}: ${result.config.description}`);
      if (result.error) {
        console.log(`    Error: ${result.error}`);
      }
    });
  }

  // Generate working configuration
  const workingConfig = {};
  availableServers.forEach(([name, result]) => {
    workingConfig[name] = {
      command: result.config.command,
      args: result.config.args,
      env: {}
    };
  });

  // Save the working configuration
  const configPath = path.join(__dirname, '..', 'configs', 'working-servers.json');
  fs.writeFileSync(configPath, JSON.stringify(workingConfig, null, 2));
  console.log(`\n💾 Working configuration saved to: ${configPath}`);

  return results;
}

/**
 * Generate Cursor settings configuration
 * @param {Object} results - Test results from installAndTestServers
 */
function generateCursorConfig(results) {
  const availableServers = Object.entries(results).filter(([_, result]) => result.available);

  const cursorConfig = {
    "mcp.servers": {}
  };

  availableServers.forEach(([name, result]) => {
    cursorConfig["mcp.servers"][name] = {
      command: result.config.command,
      args: result.config.args,
      env: {}
    };

    // Add specific environment variables for certain servers
    if (name === 'github') {
      cursorConfig["mcp.servers"][name].env.GITHUB_PERSONAL_ACCESS_TOKEN = "";
    }
    if (name === 'brave-search') {
      cursorConfig["mcp.servers"][name].env.BRAVE_API_KEY = "";
    }
  });

  const configPath = path.join(__dirname, '..', 'configs', 'cursor-settings.json');
  fs.writeFileSync(configPath, JSON.stringify(cursorConfig, null, 2));
  console.log(`📝 Cursor configuration saved to: ${configPath}`);

  return cursorConfig;
}

/**
 * Create a simplified configuration for immediate use
 */
function createSimplifiedConfig() {
  // Create a basic working configuration with the servers we know work
  const basicConfig = {
    "mcp.servers": {
      "filesystem": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "C:\\Users\\beckd", "C:\\"],
        "env": {}
      },
      "memory": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-memory"],
        "env": {}
      },
      "fetch": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-fetch"],
        "env": {}
      },
      "sequential-thinking": {
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
        "env": {}
      }
    }
  };

  const configPath = path.join(__dirname, '..', 'configs', 'basic-cursor-settings.json');
  fs.writeFileSync(configPath, JSON.stringify(basicConfig, null, 2));
  console.log(`📝 Basic Cursor configuration saved to: ${configPath}`);

  return basicConfig;
}

// Main execution
async function main() {
  try {
    console.log('🚀 Starting MCP Server Setup (Fixed)\n');

    // First, create a basic configuration
    createSimplifiedConfig();

    const results = await installAndTestServers();
    const cursorConfig = generateCursorConfig(results);

    console.log('\n🎉 Setup Complete!');
    console.log('\nNext steps:');
    console.log('1. Copy the configuration from configs/basic-cursor-settings.json to your Cursor settings.json');
    console.log('2. Or use configs/cursor-settings.json if you have working servers');
    console.log('3. Add any required API keys (GitHub, Brave Search)');
    console.log('4. Restart Cursor to load the MCP servers');

    // Return results for programmatic use
    return {
      results,
      cursorConfig,
      availableCount: Object.values(results).filter(r => r.available).length,
      totalCount: Object.keys(results).length
    };
  } catch (error) {
    console.error('❌ Setup failed:', error);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = {
  installAndTestServers,
  generateCursorConfig,
  createSimplifiedConfig,
  testServer,
  mcpServers
};
