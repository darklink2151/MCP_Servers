/**
 * @file mcp-manager.js
 * @description Master control script for managing MCP servers and workflows
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');
const os = require('os');

// Global variables
let config = null;
const servers = {};
let workflowRoot = '';
let serverProcesses = {};

/**
 * Initialize the MCP workflow manager
 * @param {string} configPath - Path to the master configuration file
 * @returns {Promise<boolean>} Success status
 */
async function initialize(configPath = './configs/master-config.json') {
  try {
    // Resolve the configuration path
    const resolvedPath = path.resolve(configPath);
    console.log(`Loading configuration from: ${resolvedPath}`);

    // Load the master configuration
    const configData = fs.readFileSync(resolvedPath, 'utf8');
    config = JSON.parse(configData);

    // Process environment variables
    const home = os.homedir();
    workflowRoot = config.workflowRoot.replace('${HOME}', home);

    // Setup environment variables
    Object.entries(config.environmentVariables).forEach(([key, value]) => {
      const processedValue = value
        .replace('${WORKFLOW_ROOT}', workflowRoot)
        .replace('${HOME}', home);
      process.env[key] = processedValue;
    });

    // Ensure directories exist
    ensureDirectoryStructure();

    console.log('MCP Manager initialized successfully');
    return true;
  } catch (error) {
    console.error('Failed to initialize MCP Manager:', error);
    return false;
  }
}

/**
 * Ensure all required directories exist
 */
function ensureDirectoryStructure() {
  const directories = [
    workflowRoot,
    path.join(workflowRoot, 'configs'),
    path.join(workflowRoot, 'scripts'),
    path.join(workflowRoot, 'resources'),
    path.join(workflowRoot, 'logs'),
    path.join(workflowRoot, 'templates'),
    path.join(workflowRoot, 'resources', 'databases'),
    path.join(workflowRoot, 'resources', 'screenshots'),
    path.join(workflowRoot, 'resources', 'downloads'),
    path.join(workflowRoot, 'resources', 'memory-store'),
    path.join(workflowRoot, 'backups')
  ];

  directories.forEach(dir => {
    if (!fs.existsSync(dir)) {
      console.log(`Creating directory: ${dir}`);
      fs.mkdirSync(dir, { recursive: true });
    }
  });
}

/**
 * Start a specific MCP server
 * @param {string} serverName - Name of the server to start
 * @returns {Promise<boolean>} Success status
 */
async function startServer(serverName) {
  try {
    if (!config || !config.servers[serverName]) {
      console.error(`Server "${serverName}" not found in configuration`);
      return false;
    }

    const serverConfig = config.servers[serverName];
    if (!serverConfig.enabled) {
      console.warn(`Server "${serverName}" is disabled in configuration`);
      return false;
    }

    // If the server is already running, don't start it again
    if (serverProcesses[serverName]) {
      console.warn(`Server "${serverName}" is already running`);
      return true;
    }

    // Load server-specific configuration
    const configPath = serverConfig.configPath.replace('${WORKFLOW_ROOT}', workflowRoot);
    if (!fs.existsSync(configPath)) {
      console.error(`Configuration file not found: ${configPath}`);
      return false;
    }

    const serverSpecificConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));

    // Prepare environment variables for the server
    const env = { ...process.env };
    if (serverSpecificConfig.env) {
      Object.entries(serverSpecificConfig.env).forEach(([key, value]) => {
        // Replace variables with actual values
        if (typeof value === 'string') {
          const processed = value.replace('${WORKFLOW_ROOT}', workflowRoot);
          env[key] = processed;
        } else {
          env[key] = value;
        }
      });
    }

    // Start the server
    console.log(`Starting ${serverName} server...`);
    const serverProcess = spawn(serverSpecificConfig.command, serverSpecificConfig.args, {
      env,
      stdio: 'pipe',
      detached: false
    });

    // Store the process reference
    serverProcesses[serverName] = serverProcess;

    // Handle process output
    const logFile = path.join(workflowRoot, 'logs', `${serverName}.log`);
    const logStream = fs.createWriteStream(logFile, { flags: 'a' });

    serverProcess.stdout.pipe(logStream);
    serverProcess.stderr.pipe(logStream);

    serverProcess.stdout.on('data', (data) => {
      console.log(`[${serverName}] ${data.toString().trim()}`);
    });

    serverProcess.stderr.on('data', (data) => {
      console.error(`[${serverName}] ERROR: ${data.toString().trim()}`);
    });

    // Handle process exit
    serverProcess.on('exit', (code, signal) => {
      const exitMessage = `${serverName} server exited with code ${code} (signal: ${signal})`;
      if (code !== 0) {
        console.error(exitMessage);
      } else {
        console.log(exitMessage);
      }
      delete serverProcesses[serverName];
      logStream.end();
    });

    // Wait a bit to see if the process fails immediately
    return new Promise((resolve) => {
      const timeout = setTimeout(() => {
        if (serverProcesses[serverName]) {
          console.log(`${serverName} server started successfully`);
          resolve(true);
        } else {
          console.error(`${serverName} server failed to start`);
          resolve(false);
        }
      }, 2000);

      serverProcess.on('error', (err) => {
        clearTimeout(timeout);
        console.error(`Failed to start ${serverName} server:`, err);
        delete serverProcesses[serverName];
        resolve(false);
      });
    });
  } catch (error) {
    console.error(`Error starting ${serverName} server:`, error);
    return false;
  }
}

/**
 * Stop a specific MCP server
 * @param {string} serverName - Name of the server to stop
 * @returns {boolean} Success status
 */
function stopServer(serverName) {
  if (!serverProcesses[serverName]) {
    console.warn(`Server "${serverName}" is not running`);
    return true;
  }

  console.log(`Stopping ${serverName} server...`);
  try {
    // Send SIGTERM to gracefully terminate the process
    serverProcesses[serverName].kill('SIGTERM');

    // Wait for the process to exit
    return new Promise((resolve) => {
      const timeout = setTimeout(() => {
        if (serverProcesses[serverName]) {
          console.warn(`${serverName} server did not exit gracefully, forcing termination`);
          serverProcesses[serverName].kill('SIGKILL');
          delete serverProcesses[serverName];
        }
        resolve(true);
      }, 5000);

      serverProcesses[serverName].on('exit', () => {
        clearTimeout(timeout);
        console.log(`${serverName} server stopped successfully`);
        delete serverProcesses[serverName];
        resolve(true);
      });
    });
  } catch (error) {
    console.error(`Error stopping ${serverName} server:`, error);
    return false;
  }
}

/**
 * Start all servers for a specific workflow
 * @param {string} workflowName - Name of the workflow to start
 * @returns {Promise<boolean>} Success status
 */
async function startWorkflow(workflowName) {
  try {
    if (!config || !config.workflows[workflowName]) {
      console.error(`Workflow "${workflowName}" not found in configuration`);
      return false;
    }

    const workflow = config.workflows[workflowName];
    console.log(`Starting "${workflow.name}" workflow...`);

    // Start each server in the workflow
    const serverResults = [];
    for (const serverName of workflow.servers) {
      const success = await startServer(serverName);
      serverResults.push({ server: serverName, success });
    }

    // Check if all servers started successfully
    const allSuccess = serverResults.every(result => result.success);
    if (allSuccess) {
      console.log(`Workflow "${workflow.name}" started successfully`);
    } else {
      console.error(`Some servers failed to start for workflow "${workflow.name}"`);
      const failedServers = serverResults.filter(result => !result.success).map(result => result.server);
      console.error(`Failed servers: ${failedServers.join(', ')}`);
    }

    return allSuccess;
  } catch (error) {
    console.error(`Error starting workflow "${workflowName}":`, error);
    return false;
  }
}

/**
 * Stop all servers for a specific workflow
 * @param {string} workflowName - Name of the workflow to stop
 * @returns {Promise<boolean>} Success status
 */
async function stopWorkflow(workflowName) {
  try {
    if (!config || !config.workflows[workflowName]) {
      console.error(`Workflow "${workflowName}" not found in configuration`);
      return false;
    }

    const workflow = config.workflows[workflowName];
    console.log(`Stopping "${workflow.name}" workflow...`);

    // Stop each server in the workflow
    const serverResults = [];
    for (const serverName of workflow.servers) {
      const success = await stopServer(serverName);
      serverResults.push({ server: serverName, success });
    }

    // Check if all servers stopped successfully
    const allSuccess = serverResults.every(result => result.success);
    if (allSuccess) {
      console.log(`Workflow "${workflow.name}" stopped successfully`);
    } else {
      console.error(`Some servers failed to stop for workflow "${workflow.name}"`);
      const failedServers = serverResults.filter(result => !result.success).map(result => result.server);
      console.error(`Failed servers: ${failedServers.join(', ')}`);
    }

    return allSuccess;
  } catch (error) {
    console.error(`Error stopping workflow "${workflowName}":`, error);
    return false;
  }
}

/**
 * Start all configured autostart servers
 * @returns {Promise<boolean>} Success status
 */
async function startAutostartServers() {
  try {
    if (!config || !config.servers) {
      console.error('No server configuration found');
      return false;
    }

    console.log('Starting autostart servers...');

    // Get all autostart servers and sort by priority
    const autostartServers = Object.entries(config.servers)
      .filter(([_, serverConfig]) => serverConfig.enabled && serverConfig.autostart)
      .sort((a, b) => b[1].priority - a[1].priority) // Higher priority first
      .map(([name]) => name);

    if (autostartServers.length === 0) {
      console.log('No autostart servers configured');
      return true;
    }

    // Start each server
    const serverResults = [];
    for (const serverName of autostartServers) {
      const success = await startServer(serverName);
      serverResults.push({ server: serverName, success });
    }

    // Check if all servers started successfully
    const allSuccess = serverResults.every(result => result.success);
    if (allSuccess) {
      console.log('All autostart servers started successfully');
    } else {
      console.error('Some autostart servers failed to start');
      const failedServers = serverResults.filter(result => !result.success).map(result => result.server);
      console.error(`Failed servers: ${failedServers.join(', ')}`);
    }

    return allSuccess;
  } catch (error) {
    console.error('Error starting autostart servers:', error);
    return false;
  }
}

/**
 * Stop all running servers
 * @returns {Promise<boolean>} Success status
 */
async function stopAllServers() {
  try {
    const runningServers = Object.keys(serverProcesses);
    if (runningServers.length === 0) {
      console.log('No servers are currently running');
      return true;
    }

    console.log(`Stopping all running servers: ${runningServers.join(', ')}`);

    // Stop each server
    const serverResults = [];
    for (const serverName of runningServers) {
      const success = await stopServer(serverName);
      serverResults.push({ server: serverName, success });
    }

    // Check if all servers stopped successfully
    const allSuccess = serverResults.every(result => result.success);
    if (allSuccess) {
      console.log('All servers stopped successfully');
    } else {
      console.error('Some servers failed to stop');
      const failedServers = serverResults.filter(result => !result.success).map(result => result.server);
      console.error(`Failed servers: ${failedServers.join(', ')}`);
    }

    return allSuccess;
  } catch (error) {
    console.error('Error stopping all servers:', error);
    return false;
  }
}

/**
 * Get status of all configured servers
 * @returns {Object} Status information
 */
function getStatus() {
  if (!config || !config.servers) {
    return { error: 'No server configuration found' };
  }

  const serverStatus = {};
  Object.keys(config.servers).forEach(serverName => {
    const isRunning = !!serverProcesses[serverName];
    const serverConfig = config.servers[serverName];

    serverStatus[serverName] = {
      running: isRunning,
      enabled: serverConfig.enabled,
      autostart: serverConfig.autostart,
      priority: serverConfig.priority,
      pid: isRunning ? serverProcesses[serverName].pid : null
    };
  });

  const workflowStatus = {};
  Object.keys(config.workflows || {}).forEach(workflowName => {
    const workflow = config.workflows[workflowName];
    const requiredServers = workflow.servers || [];
    const runningCount = requiredServers.filter(server => !!serverProcesses[server]).length;

    workflowStatus[workflowName] = {
      name: workflow.name,
      description: workflow.description,
      requiredServers,
      runningServers: runningCount,
      totalServers: requiredServers.length,
      ready: runningCount === requiredServers.length
    };
  });

  return {
    timestamp: new Date().toISOString(),
    servers: serverStatus,
    workflows: workflowStatus,
    runningServerCount: Object.keys(serverProcesses).length,
    totalServerCount: Object.keys(config.servers).length
  };
}

/**
 * Create a backup of the workflow configuration and resources
 * @returns {Promise<boolean>} Success status
 */
async function createBackup() {
  try {
    if (!config || !config.backup || !config.backup.enabled) {
      console.error('Backup functionality is not enabled in configuration');
      return false;
    }

    const backupDir = config.backup.location.replace('${WORKFLOW_ROOT}', workflowRoot);
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true });
    }

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupName = `mcp-workflow-backup-${timestamp}`;
    const backupPath = path.join(backupDir, backupName);

    // Create the backup directory
    fs.mkdirSync(backupPath);

    // Copy configurations
    const configsDir = path.join(workflowRoot, 'configs');
    fs.cpSync(configsDir, path.join(backupPath, 'configs'), { recursive: true });

    // Copy templates
    const templatesDir = path.join(workflowRoot, 'templates');
    fs.cpSync(templatesDir, path.join(backupPath, 'templates'), { recursive: true });

    // Copy databases (if they exist)
    const dbDir = path.join(workflowRoot, 'resources', 'databases');
    if (fs.existsSync(dbDir)) {
      fs.cpSync(dbDir, path.join(backupPath, 'databases'), { recursive: true });
    }

    // Copy memory store (if it exists)
    const memoryDir = path.join(workflowRoot, 'resources', 'memory-store');
    if (fs.existsSync(memoryDir)) {
      fs.cpSync(memoryDir, path.join(backupPath, 'memory-store'), { recursive: true });
    }

    // Compress the backup if enabled
    if (config.backup.compression) {
      // Implementation depends on available tools, could use tar/zip via child_process
      console.log('Compression is enabled, but not implemented in this version');
    }

    // Cleanup old backups if retention is specified
    if (config.backup.retention > 0) {
      const backups = fs.readdirSync(backupDir)
        .filter(file => file.startsWith('mcp-workflow-backup-'))
        .map(file => ({
          name: file,
          path: path.join(backupDir, file),
          time: fs.statSync(path.join(backupDir, file)).mtime.getTime()
        }))
        .sort((a, b) => b.time - a.time); // Sort by date (newest first)

      // Keep only the specified number of backups
      const toDelete = backups.slice(config.backup.retention);
      for (const backup of toDelete) {
        try {
          fs.rmSync(backup.path, { recursive: true, force: true });
          console.log(`Deleted old backup: ${backup.name}`);
        } catch (error) {
          console.error(`Failed to delete old backup ${backup.name}:`, error);
        }
      }
    }

    console.log(`Backup created successfully: ${backupPath}`);
    return true;
  } catch (error) {
    console.error('Error creating backup:', error);
    return false;
  }
}

// Export the module functions
module.exports = {
  initialize,
  startServer,
  stopServer,
  startWorkflow,
  stopWorkflow,
  startAutostartServers,
  stopAllServers,
  getStatus,
  createBackup
};
