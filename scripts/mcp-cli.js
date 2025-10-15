#!/usr/bin/env node
/**
 * @file mcp-cli.js
 * @description Command-line interface for the MCP workflow manager
 * @version 1.0.0
 */

const { program } = require('commander');
const path = require('path');
const fs = require('fs');
const mcpManager = require('./mcp-manager');

// Define the program version and description
program
  .name('mcp-cli')
  .description('Command-line interface for the MCP workflow manager')
  .version('1.0.0');

// Initialize command
program
  .command('init')
  .description('Initialize the MCP workflow manager')
  .option('-c, --config <path>', 'Path to the master configuration file', './configs/master-config.json')
  .action(async (options) => {
    console.log('Initializing MCP workflow manager...');
    const success = await mcpManager.initialize(options.config);
    if (success) {
      console.log('MCP workflow manager initialized successfully');
    } else {
      console.error('Failed to initialize MCP workflow manager');
      process.exit(1);
    }
  });

// Start server command
program
  .command('start-server <serverName>')
  .description('Start a specific MCP server')
  .option('-c, --config <path>', 'Path to the master configuration file', './configs/master-config.json')
  .action(async (serverName, options) => {
    await mcpManager.initialize(options.config);
    console.log(`Starting server: ${serverName}`);
    const success = await mcpManager.startServer(serverName);
    if (success) {
      console.log(`Server ${serverName} started successfully`);
    } else {
      console.error(`Failed to start server ${serverName}`);
      process.exit(1);
    }
  });

// Stop server command
program
  .command('stop-server <serverName>')
  .description('Stop a specific MCP server')
  .option('-c, --config <path>', 'Path to the master configuration file', './configs/master-config.json')
  .action(async (serverName, options) => {
    await mcpManager.initialize(options.config);
    console.log(`Stopping server: ${serverName}`);
    const success = await mcpManager.stopServer(serverName);
    if (success) {
      console.log(`Server ${serverName} stopped successfully`);
    } else {
      console.error(`Failed to stop server ${serverName}`);
      process.exit(1);
    }
  });

// Start workflow command
program
  .command('start-workflow <workflowName>')
  .description('Start all servers for a specific workflow')
  .option('-c, --config <path>', 'Path to the master configuration file', './configs/master-config.json')
  .action(async (workflowName, options) => {
    await mcpManager.initialize(options.config);
    console.log(`Starting workflow: ${workflowName}`);
    const success = await mcpManager.startWorkflow(workflowName);
    if (success) {
      console.log(`Workflow ${workflowName} started successfully`);
    } else {
      console.error(`Failed to start workflow ${workflowName}`);
      process.exit(1);
    }
  });

// Stop workflow command
program
  .command('stop-workflow <workflowName>')
  .description('Stop all servers for a specific workflow')
  .option('-c, --config <path>', 'Path to the master configuration file', './configs/master-config.json')
  .action(async (workflowName, options) => {
    await mcpManager.initialize(options.config);
    console.log(`Stopping workflow: ${workflowName}`);
    const success = await mcpManager.stopWorkflow(workflowName);
    if (success) {
      console.log(`Workflow ${workflowName} stopped successfully`);
    } else {
      console.error(`Failed to stop workflow ${workflowName}`);
      process.exit(1);
    }
  });

// Start autostart servers command
program
  .command('start-autostart')
  .description('Start all configured autostart servers')
  .option('-c, --config <path>', 'Path to the master configuration file', './configs/master-config.json')
  .action(async (options) => {
    await mcpManager.initialize(options.config);
    console.log('Starting autostart servers...');
    const success = await mcpManager.startAutostartServers();
    if (success) {
      console.log('Autostart servers started successfully');
    } else {
      console.error('Failed to start some autostart servers');
      process.exit(1);
    }
  });

// Stop all servers command
program
  .command('stop-all')
  .description('Stop all running servers')
  .option('-c, --config <path>', 'Path to the master configuration file', './configs/master-config.json')
  .action(async (options) => {
    await mcpManager.initialize(options.config);
    console.log('Stopping all servers...');
    const success = await mcpManager.stopAllServers();
    if (success) {
      console.log('All servers stopped successfully');
    } else {
      console.error('Failed to stop some servers');
      process.exit(1);
    }
  });

// Get status command
program
  .command('status')
  .description('Get status of all configured servers')
  .option('-c, --config <path>', 'Path to the master configuration file', './configs/master-config.json')
  .action(async (options) => {
    await mcpManager.initialize(options.config);
    const status = mcpManager.getStatus();
    console.log('\n=== MCP WORKFLOW STATUS ===');
    console.log(`Timestamp: ${status.timestamp}`);
    console.log(`Running Servers: ${status.runningServerCount}/${status.totalServerCount}`);

    console.log('\n=== SERVERS ===');
    Object.entries(status.servers).forEach(([name, server]) => {
      const statusStr = server.running ? '✓ RUNNING' : '✗ STOPPED';
      const enabledStr = server.enabled ? 'Enabled' : 'Disabled';
      const autostartStr = server.autostart ? 'Autostart' : 'Manual';
      console.log(`${name}: ${statusStr} (${enabledStr}, ${autostartStr}, Priority: ${server.priority})`);
      if (server.running) {
        console.log(`  PID: ${server.pid}`);
      }
    });

    console.log('\n=== WORKFLOWS ===');
    Object.entries(status.workflows).forEach(([name, workflow]) => {
      const readyStr = workflow.ready ? '✓ READY' : '⚠ INCOMPLETE';
      console.log(`${workflow.name} (${name}): ${readyStr}`);
      console.log(`  Description: ${workflow.description}`);
      console.log(`  Servers: ${workflow.runningServers}/${workflow.totalServers} running`);
      console.log(`  Required: ${workflow.requiredServers.join(', ')}`);
    });
  });

// Create backup command
program
  .command('backup')
  .description('Create a backup of the workflow configuration and resources')
  .option('-c, --config <path>', 'Path to the master configuration file', './configs/master-config.json')
  .action(async (options) => {
    await mcpManager.initialize(options.config);
    console.log('Creating backup...');
    const success = await mcpManager.createBackup();
    if (success) {
      console.log('Backup created successfully');
    } else {
      console.error('Failed to create backup');
      process.exit(1);
    }
  });

// Setup command to prepare Cursor settings
program
  .command('setup-cursor')
  .description('Set up MCP servers in Cursor settings.json')
  .option('-c, --config <path>', 'Path to the master configuration file', './configs/master-config.json')
  .action(async (options) => {
    await mcpManager.initialize(options.config);

    // Get the Cursor settings path
    const home = require('os').homedir();
    const settingsPath = path.join(home, 'AppData', 'Roaming', 'Cursor', 'User', 'settings.json');

    if (!fs.existsSync(settingsPath)) {
      console.error(`Cursor settings file not found: ${settingsPath}`);
      process.exit(1);
    }

    try {
      // Read the current settings
      const settingsData = fs.readFileSync(settingsPath, 'utf8');
      let settings;
      try {
        settings = JSON.parse(settingsData);
      } catch (error) {
        console.error('Failed to parse Cursor settings file:', error);
        process.exit(1);
      }

      // Create or update the mcp.servers section
      if (!settings['mcp.servers']) {
        settings['mcp.servers'] = {};
      }

      // Add/update each server from our configuration
      const serverConfigs = {};
      Object.entries(mcpManager.getStatus().servers).forEach(([name, status]) => {
        if (status.enabled) {
          const configPath = path.join(home, 'MCP-Workflow', 'configs', `${name}-config.json`);
          if (fs.existsSync(configPath)) {
            const serverConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));

            serverConfigs[name] = {
              command: serverConfig.command,
              args: serverConfig.args,
              env: serverConfig.env || {}
            };
          }
        }
      });

      settings['mcp.servers'] = serverConfigs;

      // Backup original settings
      const backupPath = `${settingsPath}.backup-${Date.now()}`;
      fs.copyFileSync(settingsPath, backupPath);
      console.log(`Backup of original settings created: ${backupPath}`);

      // Save the updated settings
      fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
      console.log('Cursor settings updated successfully with MCP server configurations');
    } catch (error) {
      console.error('Failed to update Cursor settings:', error);
      process.exit(1);
    }
  });

// Parse command line arguments
program.parse(process.argv);

// If no arguments, show help
if (!process.argv.slice(2).length) {
  program.help();
}
