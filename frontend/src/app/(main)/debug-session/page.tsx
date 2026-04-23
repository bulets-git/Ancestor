'use client';
import { useAuth } from '@/components/auth/auth-provider';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export default function DebugSessionPage() {
  const { user, profile, session, isLoading } = useAuth();

  return (
    <div className="p-8 space-y-4">
      <h1 className="text-2xl font-bold">Debug Session</h1>
      <Card>
        <CardHeader>
          <CardTitle>Auth State</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          <p><strong>Loading:</strong> {isLoading ? 'Yes' : 'No'}</p>
          <p><strong>User ID:</strong> {user?.id || 'Not logged in'}</p>
          <p><strong>Email:</strong> {user?.email || 'N/A'}</p>
          <p><strong>Profile Role:</strong> {profile?.role || 'N/A'}</p>
          <p><strong>Is Verified:</strong> {profile?.is_verified ? 'Yes' : 'No'}</p>
          <p><strong>Session exists:</strong> {session ? 'Yes' : 'No'}</p>
        </CardContent>
      </Card>
      
      <Card>
        <CardHeader>
          <CardTitle>Cookies (Client Side)</CardTitle>
        </CardHeader>
        <CardContent>
          <pre className="bg-muted p-4 rounded-lg overflow-auto max-h-40 text-xs">
            {typeof window !== 'undefined' ? document.cookie : 'N/A'}
          </pre>
        </CardContent>
      </Card>

      <Button onClick={() => window.location.replace('/login')}>Go to Login</Button>
    </div>
  );
}
