-- ══════════════════════════════════════════════════════════════
-- Automatically Verify Google Users
-- Redefines handle_new_user() to set is_verified=true for Google signups
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (user_id, email, full_name, role, is_verified)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        'viewer',
        (COALESCE(NEW.raw_app_meta_data->>'provider', '') = 'google' OR NEW.raw_app_meta_data->'providers' @> '["google"]'::jsonb)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
