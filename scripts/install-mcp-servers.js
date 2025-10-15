/**
 * @file install-mcp-servers.js
 * @description Script to install and test MCP servers dynamically
 * @version 1.0.0
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// MCP Server configurations
const mcpServers = {
  filesystem: {
    package: '@modelcontextprotocol/server-filesystem',
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-filesystem'],
    description: 'Enhanced filesystem access'
  },
  memory: {
    package: '@modelcontextprotocol/server-memory',
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-memory'],
    description: 'Persistent memory storage'
  },
  github: {
    package: '@modelcontextprotocol/server-github',
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-github'],
    description: 'GitHub integration'
  },
  'brave-search': {
    package: '@modelcontextprotocol/server-brave-search',
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-brave-search'],
    description: 'Web search with Brave'
  },
  fetch: {
    package: '@modelcontextprotocol/server-fetch',
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-fetch'],
    description: 'HTTP request client'
  },
  sqlite: {
    package: '@modelcontextprotocol/server-sqlite',
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-sqlite'],
    description: 'SQLite database integration'
  },
  puppeteer: {
    package: '@modelcontextprotocol/server-puppeteer',
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-puppeteer'],
    description: 'Browser automation'
  },
  'sequential-thinking': {
    package: '@modelcontextprotocol/server-sequential-thinking',
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-sequential-thinking'],
    description: 'Advanced problem solving'
  },
  everything: {
    package: '@modelcontextprotocol/server-everything',
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-everything'],
    description: 'Windows Everything search'
  }
};

/**
 * Test if an MCP server is available
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

    // Test if the server can be executed
    const testProcess = spawn(server.command, [...server.args, '--help'], {
      stdio: 'pipe',
      timeout: 10000
    });

    return new Promise((resolve) => {
      let output = '';
      let errorOutput = '';

      testProcess.stdout.on('data', (data) => {
        output += data.toString();
      });

      testProcess.stderr.on('data', (data) => {
        errorOutput += data.toString();
      });

      testProcess.on('close', (code) => {
        // Consider it working if we get any output (help, version, or even error about missing args)
        const isWorking = output.length > 0 || errorOutput.includes('--help') || code === 0;
        console.log(`${serverName}: ${isWorking ? '✓ Available' : '✗ Not available'}`);
        if (!isWorking && errorOutput) {
          console.log(`  Error: ${errorOutput.trim()}`);
        }
        resolve(isWorking);
      });

      testProcess.on('error', (err) => {
        console.log(`${serverName}: ✗ Error - ${err.message}`);
        resolve(false);
      });

      // Kill the process after timeout
      setTimeout(() => {
        if (!testProcess.killed) {
          testProcess.kill();
          console.log(`${serverName}: ✗ Timeout`);
          resolve(false);
        }
      }, 10000);
    });
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

// Main execution
async function main() {
  try {
    console.log('🚀 Starting MCP Server Setup\n');

    const results = await installAndTestServers();
    const cursorConfig = generateCursorConfig(results);

    console.log('\n🎉 Setup Complete!');
    console.log('\nNext steps:');
    console.log('1. Copy the configuration from configs/cursor-settings.json to your Cursor settings.json');
    console.log('2. Add any required API keys (GitHub, Brave Search)');
    console.log('3. Restart Cursor to load the MCP servers');

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
  testServer,
  mcpServers
};
