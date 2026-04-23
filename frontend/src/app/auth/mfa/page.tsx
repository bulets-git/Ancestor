'use client';

import { Suspense, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { ArrowLeft, Loader2, ShieldCheck } from 'lucide-react';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { requiresMfaChallenge } from '@/lib/mfa-redirect';
import { supabase } from '@/lib/supabase';

function MfaPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const nextParam = searchParams.get('next') ?? '/';
  const next = nextParam.startsWith('/') ? nextParam : '/';

  const [factorId, setFactorId] = useState<string | null>(null);
  const [challengeId, setChallengeId] = useState<string | null>(null);
  const [code, setCode] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isVerifying, setIsVerifying] = useState(false);

  useEffect(() => {
    let cancelled = false;

    const loadChallenge = async () => {
      try {
        const { data: sessionData } = await supabase.auth.getSession();
        if (!sessionData.session) {
          router.replace('/login');
          return;
        }

        const { data: aalData, error: aalError } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
        if (aalError) throw aalError;

        if (!requiresMfaChallenge(aalData)) {
          router.replace(next);
          return;
        }

        const { data: factorsData, error: factorsError } = await supabase.auth.mfa.listFactors();
        if (factorsError) throw factorsError;

        const totp = factorsData?.totp?.find((factor) => factor.status === 'verified');
        if (!totp) {
          await supabase.auth.signOut();
          toast.error('Tài khoản không có thiết bị MFA hợp lệ. Vui lòng đăng nhập lại.');
          router.replace('/login?error=mfa-factor-missing');
          return;
        }

        const { data: challengeData, error: challengeError } = await supabase.auth.mfa.challenge({
          factorId: totp.id,
        });
        if (challengeError) throw challengeError;

        if (!cancelled) {
          setFactorId(totp.id);
          setChallengeId(challengeData.id);
          setIsLoading(false);
        }
      } catch (err) {
        console.error('[MFA] init failed:', err);
        if (!cancelled) {
          toast.error(err instanceof Error ? err.message : 'Không thể khởi tạo bước xác thực 2 bước');
          router.replace('/login?error=mfa-init-failed');
        }
      }
    };

    void loadChallenge();
    return () => {
      cancelled = true;
    };
  }, [next, router]);

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!factorId || !challengeId || code.length !== 6) return;

    setIsVerifying(true);
    try {
      const { error } = await supabase.auth.mfa.verify({
        factorId,
        challengeId,
        code,
      });

      if (error) {
        const { data: retryChallenge, error: retryError } = await supabase.auth.mfa.challenge({ factorId });
        if (!retryError) setChallengeId(retryChallenge.id);
        throw error;
      }

      toast.success('Xác thực 2 bước thành công.');
      router.replace(next);
    } catch (err) {
      const status = (err as { status?: number } | null)?.status;
      toast.error(
        status === 422
          ? 'Mã xác thực không đúng hoặc đã hết hạn. Vui lòng thử lại.'
          : err instanceof Error
            ? err.message
            : 'Xác thực 2 bước thất bại'
      );
      setCode('');
    } finally {
      setIsVerifying(false);
    }
  };

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    router.replace('/login');
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-emerald-50 to-emerald-100 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="mx-auto w-12 h-12 bg-emerald-600 rounded-lg flex items-center justify-center text-white mb-4">
            <ShieldCheck className="h-6 w-6" />
          </div>
          <CardTitle>Xác thực 2 bước</CardTitle>
          <CardDescription>Hoàn tất đăng nhập bằng mã từ ứng dụng xác thực</CardDescription>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex items-center justify-center py-8 text-sm text-muted-foreground">
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              Đang chuẩn bị thử thách xác thực...
            </div>
          ) : (
            <form onSubmit={handleVerify} className="space-y-4">
              <div className="flex items-center gap-3 p-3 rounded-lg bg-emerald-50 border border-emerald-200">
                <ShieldCheck className="h-5 w-5 text-emerald-600 shrink-0" />
                <p className="text-sm text-emerald-800">
                  Nhập mã 6 chữ số từ Google Authenticator hoặc ứng dụng TOTP tương đương.
                </p>
              </div>
              <div className="space-y-2">
                <Label htmlFor="totp-code">Mã xác thực</Label>
                <Input
                  id="totp-code"
                  type="text"
                  inputMode="numeric"
                  pattern="[0-9]*"
                  maxLength={6}
                  placeholder="000000"
                  value={code}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  className="text-center text-xl tracking-[0.4em] font-mono"
                  autoFocus
                  required
                />
              </div>
              <Button type="submit" className="w-full" disabled={isVerifying || code.length !== 6}>
                {isVerifying ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Đang xác thực...
                  </>
                ) : (
                  'Xác nhận'
                )}
              </Button>
              <Button
                type="button"
                variant="ghost"
                className="w-full"
                onClick={handleSignOut}
                disabled={isVerifying}
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Quay lại đăng nhập
              </Button>
            </form>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

export default function MfaPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-emerald-50 to-emerald-100 p-4">
          <Card className="w-full max-w-md">
            <CardContent className="flex items-center justify-center py-10 text-sm text-muted-foreground">
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
              Đang tải bước xác thực...
            </CardContent>
          </Card>
        </div>
      }
    >
      <MfaPageContent />
    </Suspense>
  );
}
