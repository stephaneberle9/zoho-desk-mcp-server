/**
 * Configuration Management for Zoho Desk MCP Server
 * Loads credentials from environment variables or config file
 *
 * @author Varun Dubey (vapvarun) <varun@wbcomdesigns.com>
 * @company Wbcom Designs
 * @license GPL-2.0-or-later
 * @link https://github.com/vapvarun/zoho-desk-mcp-server
 */

import { readFileSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export type ZohoRegion = 'US' | 'EU' | 'IN' | 'AU' | 'JP' | 'CA';

export const ZOHO_DESK_URLS: Record<ZohoRegion, string> = {
  US: 'https://desk.zoho.com',
  EU: 'https://desk.zoho.eu',
  IN: 'https://desk.zoho.in',
  AU: 'https://desk.zoho.com.au',
  JP: 'https://desk.zoho.jp',
  CA: 'https://desk.zohocloud.ca',
};

export const ZOHO_ACCOUNTS_URLS: Record<ZohoRegion, string> = {
  US: 'https://accounts.zoho.com',
  EU: 'https://accounts.zoho.eu',
  IN: 'https://accounts.zoho.in',
  AU: 'https://accounts.zoho.com.au',
  JP: 'https://accounts.zoho.jp',
  CA: 'https://accounts.zohocloud.ca',
};

export interface ZohoConfig {
  accessToken: string;
  orgId: string;
  clientId?: string;
  clientSecret?: string;
  refreshToken?: string;
  region?: ZohoRegion;
}

export function getConfigPath(): string {
  return join(__dirname, '..', 'config.json');
}

export function persistAccessToken(newToken: string): boolean {
  try {
    const configPath = getConfigPath();
    const configFile = readFileSync(configPath, 'utf-8');
    const config = JSON.parse(configFile);
    config.accessToken = newToken;
    writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n', 'utf-8');
    return true;
  } catch (error) {
    return false;
  }
}

export function loadConfig(): ZohoConfig {
  // Priority 1: Environment variables
  if (process.env.ZOHO_ACCESS_TOKEN && process.env.ZOHO_ORG_ID) {
    return {
      accessToken: process.env.ZOHO_ACCESS_TOKEN,
      orgId: process.env.ZOHO_ORG_ID,
      clientId: process.env.ZOHO_CLIENT_ID,
      clientSecret: process.env.ZOHO_CLIENT_SECRET,
      refreshToken: process.env.ZOHO_REFRESH_TOKEN,
      region: (process.env.ZOHO_REGION as ZohoRegion) || 'US',
    };
  }

  // Priority 2: config.json file
  try {
    const configPath = join(__dirname, '..', 'config.json');
    const configFile = readFileSync(configPath, 'utf-8');
    const config = JSON.parse(configFile);

    if (!config.accessToken || !config.orgId) {
      throw new Error('config.json must contain accessToken and orgId');
    }

    return config;
  } catch (error) {
    throw new Error(
      'Zoho Desk credentials not found. Please set ZOHO_ACCESS_TOKEN and ZOHO_ORG_ID environment variables, or create a config.json file.'
    );
  }
}
