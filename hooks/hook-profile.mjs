/**
 * Hook Profile System — Shared gatekeeper for Node.js hooks.
 *
 * Usage:
 *   import { shouldSkip } from './hook-profile.mjs';
 *   if (shouldSkip('nexus-session-start', 'standard')) process.exit(0);
 *
 * Environment variables:
 *   CLAUDE_HOOK_PROFILE   — minimal | standard | strict (default: standard)
 *   CLAUDE_DISABLED_HOOKS — comma-separated hook IDs to skip
 */

const PROFILE_ORDER = { minimal: 1, standard: 2, strict: 3 };

export function shouldSkip(hookId, minProfile = 'standard') {
  // Check disabled list
  const disabled = (process.env.CLAUDE_DISABLED_HOOKS ?? '')
    .split(',')
    .map(s => s.trim().toLowerCase())
    .filter(Boolean);

  if (disabled.includes(hookId.toLowerCase())) return true;

  // Check profile level
  const current = (process.env.CLAUDE_HOOK_PROFILE ?? 'standard').toLowerCase();
  const currentLevel = PROFILE_ORDER[current] ?? 2;
  const requiredLevel = PROFILE_ORDER[minProfile] ?? 2;

  return currentLevel < requiredLevel;
}

