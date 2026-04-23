/**
 * @project AncestorTree
 * @file src/components/layout/dynamic-title.tsx
 * @description Updates browser tab title based on clan settings from database.
 *              Fallback to static metadata if DB is unavailable.
 */

'use client';

import { useEffect } from 'react';
import { useClanSettings } from '@/hooks/use-clan-settings';
import { CLAN_NAME, CLAN_FULL_NAME } from '@/lib/clan-config';

export function DynamicTitle() {
  const { data: cs } = useClanSettings();

  useEffect(() => {
    if (!cs) return;

    const clanName = cs.clan_name || CLAN_NAME;
    const clanFullName = cs.clan_full_name || CLAN_FULL_NAME;

    // Use a small delay to ensure Next.js has set its own title first
    const timer = setTimeout(() => {
      const currentTitle = document.title;
      
      // If title has a separator, it's likely a subpage title (e.g. "People | Gia Phả Họ Đặng")
      if (currentTitle.includes('|')) {
        const parts = currentTitle.split('|');
        const pageName = parts[0].trim();
        document.title = `${pageName} | Gia Phả ${clanName}`;
      } else if (currentTitle.includes('Gia Phả Điện Tử')) {
        // Root page title
        document.title = `Gia Phả Điện Tử - ${clanFullName}`;
      }
    }, 100);

    return () => clearTimeout(timer);
  }, [cs]);

  return null;
}
