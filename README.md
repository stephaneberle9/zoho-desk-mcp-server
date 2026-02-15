# 🎫 Zoho Desk MCP Server

[![License](https://img.shields.io/badge/license-GPL--2.0--or--later-blue.svg)](LICENSE)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.3-blue.svg)](https://www.typescriptlang.org/)
[![Node](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![MCP](https://img.shields.io/badge/MCP-0.5.0-purple.svg)](https://modelcontextprotocol.io/)

**AI-Powered Support Ticket Management for Claude AI**

A Model Context Protocol (MCP) server that provides comprehensive Zoho Desk integration, enabling Claude AI to manage support tickets, customers, agents, and more through natural language.

**Author:** [Varun Dubey (vapvarun)](https://github.com/vapvarun) | **Company:** [Wbcom Designs](https://wbcomdesigns.com)

---

## ✨ Features

### 🎯 Complete Ticket Management
- **List & Filter**: View tickets by status, priority, date with advanced filtering
- **CRUD Operations**: Create, read, update, and delete support tickets
- **Threaded Conversations**: Automatically includes all replies when reading tickets
- **Comments & Notes**: Add internal comments and public updates to tickets
- **Tag Management**: Organize tickets with tags and categories

### 👥 Customer & Contact Management
- **Customer Profiles**: Access complete contact information and history
- **Ticket History**: View all tickets for specific customers
- **Multi-Contact Support**: Manage multiple contacts per organization

### 🤝 Team & Department Management
- **Agent Directory**: List all support agents and their details
- **Department Organization**: View and manage support departments
- **Assignment Control**: Assign tickets to specific agents

### 🔍 Advanced Search
- **Full-Text Search**: Find tickets by keywords across all fields
- **Smart Filtering**: Combine multiple search criteria
- **Quick Lookup**: Fast access to specific tickets and contacts

### 🤖 AI Integration
- **Natural Language**: Manage tickets using conversational AI
- **Context Awareness**: Claude understands ticket context and relationships
- **Automated Workflows**: Let AI suggest and execute support workflows

---

## 📦 Installation

### Prerequisites
- Node.js 18 or higher
- Zoho Desk account with API access
- Claude Desktop or MCP-compatible client

### Quick Setup

```bash
# Clone the repository
git clone https://github.com/vapvarun/zoho-desk-mcp-server.git
cd zoho-desk-mcp-server

# Install dependencies
npm install

# Configure credentials (see Configuration section)
cp config.example.json config.json
# Edit config.json with your Zoho credentials

# Build the server
npm run build

# Test the server
npm start
```

---

## ⚙️ Configuration

Choose one of the following methods to configure your Zoho Desk credentials:

### Method 1: Semi-Automated Setup with config.json (Recommended)

This method uses a PowerShell script to automatically exchange your authorization code for tokens and create the `config.json` file.

#### Step 1: Create Zoho API Client

- Go to [Zoho API Console](https://api-console.zoho.com/) (or your regional URL)
- Create a new **"Self Client"** application

#### Step 2: Generate Authorization Code

- In your Self Client, go to the **"Generate Code"** tab
- Enter required scopes (comma-separated):

  ```text
  Desk.tickets.ALL,Desk.contacts.ALL,Desk.settings.READ,Desk.basic.READ,Desk.search.READ,Desk.tasks.ALL
  ```

- Set a description (e.g. "MCP Server") and expiry duration (default 3 minutes)
- Click **"Create"**, select your Zoho portal, then click **"Create"** again
- Click **"Download"** to save the `self_client.json` file

#### Step 3: Run Setup Script

Run the included PowerShell script — it reads the downloaded JSON, exchanges the code for tokens, and creates the `config.json` file automatically:

```powershell
# Auto-detects the latest self_client*.json in your Downloads folder
./setup-token.ps1

# Or specify the file explicitly
./setup-token.ps1 -JsonFile ~/Downloads/self_client.json
```

> **macOS/Linux**: PowerShell is available cross-platform as `pwsh`. Install it with:
>
> - **macOS**: `brew install powershell/tap/powershell`
> - **Ubuntu/Debian**: `sudo snap install powershell --classic`
> - **Other Linux**: See [Installing PowerShell on Linux](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux)
>
> Then run: `pwsh ./setup-token.ps1`

#### Step 4: Add Organization ID

- Go to [Zoho Desk](https://desk.zoho.com/) (or your regional URL)
- Navigate to **Settings** → **Developer Space** → **APIs**
- Your Org ID is listed under **API Details**
- Add the `orgId` field to your `config.json`:

  ```json
  {
    "accessToken": "1000.xxxxx...",
    "clientId": "1000.XXXXX...",
    "clientSecret": "xxxxx...",
    "refreshToken": "1000.xxxxx...",
    "region": "EU",
    "orgId": "657932157"
  }
  ```

#### Step 5: Test the Connection

```powershell
./test-connection.ps1
```

You should see your region, org ID, and the number of tickets in your Zoho Desk account:

```text
Testing Zoho Desk API connection...
  Region: EU (https://desk.zoho.eu)
  Org ID: 20111145693
SUCCESS: Connected to Zoho Desk API
Tickets returned: 2
```

If it fails with `INVALID_OAUTH`, your access token may have expired — generate a fresh authorization code (step 2) and run the setup script again (step 3).

**Your `config.json` is ready now!**

**⚠️ IMPORTANT**: Never commit `config.json` to git! It's already in `.gitignore`.

---

### Method 2: Manual Setup with config.json

This method uses curl to manually exchange your authorization code and create the `config.json` file by hand. You'll create the config file first and fill in the details progressively as you obtain them.

#### Step 1: Create the config.json file

Copy the template to create your configuration file:

```bash
cp config.example.json config.json
```

Open `config.json` in your editor. It should look like this:

```json
{
  "accessToken": "YOUR_ACCESS_TOKEN",
  "orgId": "YOUR_ORG_ID",
  "clientId": "YOUR_CLIENT_ID",
  "clientSecret": "YOUR_CLIENT_SECRET",
  "refreshToken": "YOUR_REFRESH_TOKEN",
  "region": "US"
}
```

Set your `region` (options: `US`, `EU`, `IN`, `AU`, `JP`, `CA`, defaults to `US` if omitted). Leave the other placeholders for now — you'll fill them in as you complete the following steps.

#### Step 2: Create Zoho API Client

- Go to [Zoho API Console](https://api-console.zoho.com/) (or your regional URL)
- Create a new **"Self Client"** application
- Copy your **Client ID** and **Client Secret** into your `config.json`

#### Step 3: Generate Authorization Code

- In your Self Client, go to the **"Generate Code"** tab
- Enter required scopes (comma-separated):

  ```text
  Desk.tickets.ALL,Desk.contacts.ALL,Desk.settings.READ,Desk.basic.READ,Desk.search.READ,Desk.tasks.ALL
  ```

- Set a description (e.g. "MCP Server") and expiry duration (default 3 minutes)
- Click **"Create"**, select your Zoho portal, then click **"Create"** again
- Copy the authorization code

#### Step 4: Exchange Code for Tokens

Run this curl command using your Client ID, Client Secret, and authorization code (adjust the URL for your region):

```bash
curl -X POST "https://accounts.zoho.com/oauth/v2/token" \
  -d "grant_type=authorization_code" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "code=YOUR_AUTHORIZATION_CODE"
```

**Regional Accounts URLs:**

| Region | Accounts URL |
| --------- | ------------ |
| US | `https://accounts.zoho.com` |
| EU | `https://accounts.zoho.eu` |
| India | `https://accounts.zoho.in` |
| Australia | `https://accounts.zoho.com.au` |
| Japan | `https://accounts.zoho.jp` |
| Canada | `https://accounts.zohocloud.ca` |

The response will contain `access_token` and `refresh_token`. Copy these values into your `config.json`:

- `access_token` → `accessToken` field
- `refresh_token` → `refreshToken` field

The refresh token does not expire and is used to generate new access tokens when they expire (every 1 hour).

#### Step 5: Get Organization ID

- Go to [Zoho Desk](https://desk.zoho.com/) (or your regional URL)
- Navigate to **Settings** → **Developer Space** → **APIs**
- Your Org ID is listed under **API Details**
- Update the `orgId` field in your `config.json`

#### Step 6: Test the Connection

```powershell
./test-connection.ps1
```

You should see your region, org ID, and the number of tickets in your Zoho Desk account:

```text
Testing Zoho Desk API connection...
  Region: EU (https://desk.zoho.eu)
  Org ID: 20111145693
SUCCESS: Connected to Zoho Desk API
Tickets returned: 2
```

If it fails with `INVALID_OAUTH`, your access token may have expired — generate a fresh authorization code (step 3) and exchange it for a new access and refresh token pair (step 4).

**Your `config.json` is ready now!**

**⚠️ IMPORTANT**: Never commit `config.json` to git! It's already in `.gitignore`.

---

### Method 3: Environment Variables (For Production)

Instead of using a `config.json` file, you can configure credentials via environment variables:

```bash
export ZOHO_ACCESS_TOKEN="1000.xxxxx..."
export ZOHO_ORG_ID="657932157"
export ZOHO_CLIENT_ID="1000.XXXXX..."
export ZOHO_CLIENT_SECRET="xxxxx..."
export ZOHO_REFRESH_TOKEN="1000.xxxxx..."
export ZOHO_REGION="US"  # US, EU, IN, AU, JP, or CA
```

See the [Usage](#-usage) section below for how to pass these to Claude Desktop.

---

## 🚀 Usage

### With Claude Desktop

Add to your Claude Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS, `%APPDATA%\Claude\claude_desktop_config.json` on Windows):

The server automatically reads credentials from the `config.json` file located in the Zoho Desk MCP Server's root directory, so no `env` block is needed:

```json
{
  "mcpServers": {
    "zoho-desk": {
      "command": "node",
      "args": [
        "/absolute/path/to/zoho-desk-mcp-server/build/index.js"
      ]
    }
  }
}
```

**Restart Claude Desktop** for changes to take effect.

> **Note**: If you prefer environment variables over using the `config.json` file, pass **all** required vars in the `env` block:
>
> ```json
> {
>   "mcpServers": {
>     "zoho-desk": {
>       "command": "node",
>       "args": ["/absolute/path/to/zoho-desk-mcp-server/build/index.js"],
>       "env": {
>         "ZOHO_ACCESS_TOKEN": "1000.xxxxx...",
>         "ZOHO_ORG_ID": "657932157",
>         "ZOHO_CLIENT_ID": "1000.XXXXX...",
>         "ZOHO_CLIENT_SECRET": "xxxxx...",
>         "ZOHO_REFRESH_TOKEN": "1000.xxxxx...",
>         "ZOHO_REGION": "US"
>       }
>     }
>   }
> }
> ```

### From Command Line

```bash
# Using config.json (recommended)
node build/index.js

# Using environment variables
ZOHO_ACCESS_TOKEN="..." ZOHO_ORG_ID="..." ZOHO_REGION="EU" node build/index.js
```

### Example Conversations with Claude

```
"List all open support tickets"

"Create a new ticket for customer issue with login"

"Show me ticket #12345 with all conversation threads"

"Reply to ticket #12345 saying 'We're working on this issue'"

"Search for all tickets about 'password reset'"

"Add tags 'urgent' and 'security' to ticket #12345"

"Move ticket #12345 to the Technical Support department"

"Show me all tickets for contact ID 98765"

"List all support agents in the Sales department"

"List all departments and move ticket #98765 to department ID 123456"
```

---

## 🤖 Automation & Slack Integration

### Real-Time Notifications (via Claude MCP)

Get instant Slack notifications when you reply or comment on tickets **through Claude AI**:
- 💬 **Ticket Replies** - Notified when you reply via MCP
- 💭 **Comments** - Notified when you add comments via MCP
- 🔒 **Privacy Aware** - Shows whether reply/comment is public or private
- 🎫 **Ticket Context** - Includes ticket #, subject, status, priority
- ⚡ **Instant** - No delay, sent immediately after action

**No webhook setup required!** Notifications are sent automatically when using Claude to interact with tickets.

### Automated Daily Summaries

Send **OPEN** Zoho Desk ticket summaries to Slack automatically with smart filtering.

**Features:**
- ✅ Shows only OPEN tickets (skips closed/resolved)
- 🗑️ Automatically filters spam/marketing tickets (guest posts, backlinks, etc.)
- 📊 Daily/weekly ticket summaries
- 🔔 Slack notifications
- 📈 Priority breakdowns (High, Medium, Low)
- 📋 Recent tickets list (top 5)
- 🎯 Customizable filters and schedules

**Real-Time Notifications Setup:**
1. Slack webhook URL already configured in `config.json` ✅
2. Restart Claude Desktop
3. Use Claude to reply/comment on tickets
4. Get instant Slack notifications!

**See:** [`SLACK_NOTIFICATIONS.md`](SLACK_NOTIFICATIONS.md) for complete guide.

**Scheduled Summaries Setup:**

```bash
# Configure Slack webhook (already done!)
# Test manually
cd automation
node ticket-summary-slack.js

# Schedule with cron (daily at 9 AM)
crontab -e
# Add: 0 9 * * * cd /path/to/automation && node ticket-summary-slack.js
```

**See:** [`automation/README.md`](automation/README.md) for complete setup guide.

---

## 🛠️ Available Tools

### Ticket Management (12 tools)
- `zoho_list_tickets` - List tickets with filters (status, priority, date)
- `zoho_list_open_tickets` - Quick access to all open tickets
- `zoho_get_ticket` - Get ticket details with threaded replies
- `zoho_get_ticket_full` - Get complete ticket with ALL threads AND comments
- `zoho_get_thread` - Get a specific conversation thread
- `zoho_get_latest_thread` - Get most recent message on a ticket
- `zoho_create_ticket` - Create new support ticket
- `zoho_update_ticket` - Update ticket status/priority/assignee/department
- `zoho_move_ticket` - Move/transfer ticket to different department
- `zoho_reply_ticket` - Add reply or private note
- `zoho_delete_ticket` - Delete/trash a ticket
- `zoho_search_tickets` - Full-text ticket search

### Ticket History & Metrics (2 tools)
- `zoho_get_ticket_history` - Get audit trail/activity history
- `zoho_get_ticket_metrics` - Get response times, resolution metrics

### Ticket Attachments (2 tools)
- `zoho_list_ticket_attachments` - List all attachments on a ticket
- `zoho_delete_ticket_attachment` - Remove attachment from ticket

### Bulk Operations (4 tools)
- `zoho_bulk_close_tickets` - Close multiple tickets at once
- `zoho_mark_tickets_read` - Mark multiple tickets as read
- `zoho_mark_tickets_unread` - Mark multiple tickets as unread
- `zoho_trash_tickets` - Move multiple tickets to trash

### Ticket Comments (2 tools)
- `zoho_list_ticket_comments` - List all comments on a ticket
- `zoho_add_ticket_comment` - Add internal or public comment

### Ticket Tags (2 tools)
- `zoho_get_ticket_tags` - Get all tags for a ticket
- `zoho_add_ticket_tags` - Add categorization tags

### Contacts (3 tools)
- `zoho_list_contacts` - List all customers
- `zoho_get_contact` - Get contact details
- `zoho_get_contact_tickets` - Get customer's ticket history

### Accounts/Companies (7 tools)
- `zoho_list_accounts` - List all company accounts
- `zoho_get_account` - Get account details
- `zoho_create_account` - Create new account
- `zoho_update_account` - Update account info
- `zoho_delete_account` - Delete an account
- `zoho_get_account_tickets` - Get all tickets for an account
- `zoho_get_account_contacts` - Get contacts in an account

### Time Tracking (5 tools)
- `zoho_list_ticket_time_entries` - List time entries on a ticket
- `zoho_add_ticket_time_entry` - Log time spent on ticket
- `zoho_update_ticket_time_entry` - Update time entry
- `zoho_delete_ticket_time_entry` - Remove time entry
- `zoho_get_ticket_time_summary` - Get total time summary

### Tasks (6 tools)
- `zoho_list_tasks` - List all tasks
- `zoho_get_task` - Get task details
- `zoho_create_task` - Create new task
- `zoho_update_task` - Update task
- `zoho_delete_task` - Delete task
- `zoho_list_ticket_tasks` - Get tasks linked to a ticket

### Products (2 tools)
- `zoho_list_products` - List all products
- `zoho_get_product` - Get product details

### Departments & Agents (3 tools)
- `zoho_list_departments` - List all departments
- `zoho_list_agents` - List all support agents
- `zoho_get_agent` - Get agent profile

**Total: 50 AI-powered tools**

---

## 📚 API Coverage

This MCP server implements comprehensive Zoho Desk API v1 coverage:

- ✅ Tickets API - Full CRUD + bulk operations
- ✅ Ticket Threads API - Conversations, replies, latest thread
- ✅ Ticket Comments API - Internal notes and public comments
- ✅ Ticket Tags API - Tag management
- ✅ Ticket Attachments API - List and delete attachments
- ✅ Ticket History API - Audit trail and activity log
- ✅ Ticket Metrics API - Response and resolution times
- ✅ Contacts API - Customer management
- ✅ Accounts API - Company/organization management
- ✅ Time Entries API - Time tracking and billing
- ✅ Tasks API - Task management linked to tickets
- ✅ Products API - Product catalog access
- ✅ Departments API - Organization structure
- ✅ Agents API - Team member access
- ✅ Search API - Advanced ticket search
- ✅ OAuth 2.0 - Automatic token refresh

**API Documentation**: [Zoho Desk API Reference](https://desk.zoho.com/DeskAPIDocument)

---

## 🔧 Development

### Project Structure

```
zoho-desk-mcp-server/
├── src/
│   ├── index.ts         # Entry point
│   ├── server.ts        # MCP server implementation
│   ├── zoho-api.ts      # Zoho Desk API client
│   ├── tools.ts         # MCP tool definitions
│   └── config.ts        # Configuration loader
├── build/               # Compiled JavaScript (git-ignored)
├── config.json          # Your credentials (git-ignored)
├── config.example.json  # Template for configuration
├── package.json
├── tsconfig.json
└── README.md
```

### Build & Development

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Development mode (auto-rebuild on changes)
npm run dev

# Start the server
npm start
```

### TypeScript Configuration

Uses strict TypeScript 5.3+ with:
- ES2022 target
- Node16 module resolution
- Full type checking enabled
- Source maps for debugging

---

## 🔐 Security

### Important Security Notes

1. **Never Commit Credentials**: `config.json` is git-ignored by default
2. **Token Expiration**: Access tokens expire - implement refresh logic
3. **OAuth Scopes**: Request only necessary API scopes
4. **Environment Variables**: Preferred for production deployments
5. **HTTPS Only**: All API requests use secure connections

### Token Refresh

**Zoho access tokens expire after 1 hour.** When your token expires, you'll see authentication errors.

#### Quick Token Refresh (Recommended)

Use the included refresh script:

```bash
cd /path/to/zoho-desk-mcp-server
./refresh-token.sh
```

This script automatically:
- ✅ Requests a new access token from Zoho
- ✅ Updates `config.json`
- ✅ Updates Claude Desktop config
- ✅ Updates WordPress (if available)

**After refreshing, restart Claude Desktop!**

#### Manual Token Refresh

```bash
curl -X POST "https://accounts.zoho.com/oauth/v2/token" \
  -d "refresh_token=YOUR_REFRESH_TOKEN" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "grant_type=refresh_token"
```

Then update the `accessToken` in:
1. `config.json`
2. Claude Desktop config
3. Restart Claude Desktop

#### Programmatic Token Refresh

The Zoho API client includes token refresh support:

```typescript
import { ZohoAPI } from './zoho-api.js';

await ZohoAPI.refreshAccessToken(
  clientId,
  clientSecret,
  refreshToken
);
```

### Reporting Security Issues

Please report security vulnerabilities to: **varun@wbcomdesigns.com**

Do not create public GitHub issues for security problems.

---

## 🤝 Contributing

We welcome contributions!

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes with clear commit messages
4. Add tests if applicable
5. Run `npm run build` to ensure it compiles
6. Submit a pull request

---

## 📄 License

**GPL-2.0-or-later** - See [LICENSE](LICENSE) file for details.

This is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 2 of the License, or (at your option) any later version.

---

## 👨‍💻 Author & Support

**Varun Dubey (vapvarun)**
- GitHub: [@vapvarun](https://github.com/vapvarun)
- Email: varun@wbcomdesigns.com
- Company: [Wbcom Designs](https://wbcomdesigns.com)

**Company:** Wbcom Designs
- Website: https://wbcomdesigns.com
- Premium WordPress Plugins & Themes
- Custom Development Services

---

## 🙏 Acknowledgments

- **Anthropic** - For Claude AI and the Model Context Protocol
- **Zoho** - For the comprehensive Desk API
- **MCP Community** - For protocol standards and best practices

---

## 📊 Related Projects

- [Basecamp MCP Server](https://github.com/vapvarun/basecamp-mcp-server) - Basecamp project management for Claude AI
- [Wbcom Designs](https://wbcomdesigns.com) - Premium WordPress solutions

---

## 🌟 Show Your Support

If this project helps you, please ⭐️ star it on GitHub!

---

**Made with ❤️ by [Varun Dubey](https://github.com/vapvarun) at [Wbcom Designs](https://wbcomdesigns.com)**
