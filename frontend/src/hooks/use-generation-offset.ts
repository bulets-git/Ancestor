/**
 * @project AncestorTree
 * @file src/hooks/use-generation-offset.ts
 * @description Hook and utility for generation display with offset support.
 *
 * Generation Offset (Giải pháp 3):
 *   DB stores generation starting at 1.
 *   When ancestors are discovered before generation 1, admin increases the
 *   `generation_offset` in clan_settings without touching any existing data.
 *
 *   Display formula:  displayGen = db_generation + generation_offset
 *
 * Example: offset=2 → DB gen 1 shows as "Đời 3", DB gen 2 shows as "Đời 4", etc.
 */

'use client';

import { useClanSettings } from '@/hooks/use-clan-settings';

/** Returns the current generation offset (0 if not set). */
export function useGenerationOffset(): number {
  const { data: settings } = useClanSettings();
  return settings?.generation_offset ?? 0;
}

/**
 * Converts a DB generation number to the display generation number.
 * @param dbGen  - The generation value stored in the `people` table
 * @param offset - The clan's generation_offset from clan_settings
 */
export function displayGen(dbGen: number, offset: number): number {
  return dbGen + offset;
}

/**
 * Hook that returns a ready-to-use formatter function.
 * Usage:  const genLabel = useGenLabel();  genLabel(person.generation) → "Đời 5"
 */
export function useGenLabel() {
  const offset = useGenerationOffset();
  return (dbGen: number) => `Đời ${displayGen(dbGen, offset)}`;
}
