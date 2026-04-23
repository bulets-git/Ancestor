import { describe, expect, it } from 'vitest';
import {
  buildMfaRedirectPath,
  getPostAuthNext,
  requiresMfaChallenge,
} from '../mfa-redirect';

describe('mfa redirect helpers', () => {
  it('requires MFA only for aal1 sessions stepping up to aal2', () => {
    expect(requiresMfaChallenge({ currentLevel: 'aal1', nextLevel: 'aal2' })).toBe(true);
    expect(requiresMfaChallenge({ currentLevel: 'aal2', nextLevel: 'aal2' })).toBe(false);
    expect(requiresMfaChallenge({ currentLevel: 'aal1', nextLevel: 'aal1' })).toBe(false);
    expect(requiresMfaChallenge(null)).toBe(false);
  });

  it('preserves the requested path and query as the post-auth destination', () => {
    expect(getPostAuthNext('/documents', '?tab=private')).toBe('/documents?tab=private');
    expect(getPostAuthNext('/', '')).toBe('/');
  });

  it('builds a safe MFA redirect path', () => {
    expect(buildMfaRedirectPath('/documents?tab=private')).toBe('/auth/mfa?next=%2Fdocuments%3Ftab%3Dprivate');
    expect(buildMfaRedirectPath('https://evil.example')).toBe('/auth/mfa?next=%2F');
  });
});
