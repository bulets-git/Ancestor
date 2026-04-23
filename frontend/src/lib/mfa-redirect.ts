export interface AalState {
  currentLevel?: string | null;
  nextLevel?: string | null;
}

export function requiresMfaChallenge(aal: AalState | null | undefined): boolean {
  return aal?.currentLevel === 'aal1' && aal?.nextLevel === 'aal2';
}

export function getPostAuthNext(pathname: string, search: string): string {
  const next = `${pathname}${search}`;
  return next.startsWith('/') ? next : '/';
}

export function buildMfaRedirectPath(next: string): string {
  const safeNext = next.startsWith('/') ? next : '/';
  return `/auth/mfa?next=${encodeURIComponent(safeNext)}`;
}
