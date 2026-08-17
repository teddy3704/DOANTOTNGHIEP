[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$migrationDirectory = Join-Path $repositoryRoot 'supabase\migrations'
$databaseTestPath = Join-Path $repositoryRoot 'supabase\tests\database\mobile_preferences_rls.test.sql'
$configPath = Join-Path $repositoryRoot 'supabase\config.toml'

function Assert-Contract {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Condition) {
        throw "SUPABASE_FOUNDATION_INVALID: $Message"
    }
}

$migrations = @(Get-ChildItem -LiteralPath $migrationDirectory -File -Filter '*_create_mobile_preferences.sql')
Assert-Contract ($migrations.Count -eq 1) 'Expected exactly one CLI-generated mobile_preferences migration.'

$migration = Get-Content -Raw -LiteralPath $migrations[0].FullName
$databaseTest = Get-Content -Raw -LiteralPath $databaseTestPath
$config = Get-Content -Raw -LiteralPath $configPath

$createTableMatches = [regex]::Matches(
    $migration,
    '(?im)^\s*create\s+table\s+([a-z0-9_.]+)'
)
Assert-Contract ($createTableMatches.Count -eq 1) 'Migration must create exactly one table.'
Assert-Contract (
    $createTableMatches[0].Groups[1].Value -eq 'public.mobile_preferences'
) 'The only app-owned table must be public.mobile_preferences.'

$requiredPatterns = [ordered]@{
    'owner UUID primary key' = '(?is)owner_id\s+uuid\s+primary\s+key'
    'theme mode allowlist' = "(?is)check\s*\(\s*theme_mode\s+in\s*\(\s*'system'\s*,\s*'light'\s*,\s*'dark'\s*\)\s*\)"
    'timezone-aware created timestamp' = '(?is)created_at\s+timestamptz\s+not\s+null\s+default\s+now\(\)'
    'timezone-aware updated timestamp' = '(?is)updated_at\s+timestamptz\s+not\s+null\s+default\s+now\(\)'
    'RLS enabled' = '(?is)alter\s+table\s+public\.mobile_preferences\s+enable\s+row\s+level\s+security'
    'RLS forced' = '(?is)alter\s+table\s+public\.mobile_preferences\s+force\s+row\s+level\s+security'
    'authenticated SELECT grant' = '(?is)grant\s+select\s+on\s+table\s+public\.mobile_preferences\s+to\s+authenticated'
    'column-scoped INSERT grant' = '(?is)grant\s+insert\s*\(\s*owner_id\s*,\s*theme_mode\s*\)\s+on\s+table\s+public\.mobile_preferences\s+to\s+authenticated'
    'column-scoped UPDATE grant' = '(?is)grant\s+update\s*\(\s*theme_mode\s*\)\s+on\s+table\s+public\.mobile_preferences\s+to\s+authenticated'
    'own-row identity predicate' = '(?is)\(\s*select\s+auth\.uid\(\)\s*\)\s*=\s*owner_id'
    'anonymous-session rejection' = "(?is)auth\.jwt\(\)\s*->>\s*'is_anonymous'"
    'select policy' = '(?is)create\s+policy\s+mobile_preferences_select_own'
    'insert policy' = '(?is)create\s+policy\s+mobile_preferences_insert_own'
    'update policy' = '(?is)create\s+policy\s+mobile_preferences_update_own'
    'fixed-purpose save function' = '(?is)create\s+function\s+public\.save_mobile_theme_preference\s*\(\s*p_theme_mode\s+text\s*\)'
    'invoker rights function' = '(?is)create\s+function\s+public\.save_mobile_theme_preference.*?security\s+invoker'
    'server-derived owner identity' = '(?is)values\s*\(\s*\(\s*select\s+auth\.uid\(\)\s*\)\s*,\s*p_theme_mode\s*\)'
    'theme-only conflict update' = '(?is)on\s+conflict\s*\(\s*owner_id\s*\)\s+do\s+update\s+set\s+theme_mode\s*=\s*excluded\.theme_mode'
    'authenticated function execute grant' = '(?is)grant\s+execute\s+on\s+function\s+public\.save_mobile_theme_preference\s*\(\s*text\s*\)\s+to\s+authenticated'
}

foreach ($entry in $requiredPatterns.GetEnumerator()) {
    Assert-Contract ([regex]::IsMatch($migration, $entry.Value)) "Missing $($entry.Key)."
}

$forbiddenPatterns = [ordered]@{
    'Moodle-clone table' = '(?im)^\s*create\s+table\s+(?:public\.)?(?:users|profiles|courses|assignments|grades|submissions)\b'
    'auth.users foreign key' = '(?is)references\s+auth\.users'
    'DELETE grant' = '(?is)grant\s+delete\b'
    'DELETE policy' = '(?is)for\s+delete\b'
    'anon grant' = '(?is)grant\s+[^;]+\s+to\s+anon\b'
    'unrestricted policy' = '(?is)using\s*\(\s*true\s*\)'
    'security-definer function' = '(?is)security\s+definer'
    'credential-like assignment' = '(?im)(password|service_role_key|secret_key|access_token)\s*=\s*[''"][^''"]+[''"]'
}

foreach ($entry in $forbiddenPatterns.GetEnumerator()) {
    Assert-Contract (-not [regex]::IsMatch($migration, $entry.Value)) "Forbidden $($entry.Key) detected."
}

$policyCount = [regex]::Matches(
    $migration,
    '(?im)^\s*create\s+policy\s+mobile_preferences_[a-z0-9_]+'
).Count
Assert-Contract ($policyCount -eq 3) 'Expected exactly three mobile_preferences policies.'

Assert-Contract (
    [regex]::IsMatch($databaseTest, '(?is)select\s+plan\(28\)')
) 'pgTAP test plan is missing or has an unexpected assertion count.'
Assert-Contract (
    [regex]::IsMatch($databaseTest, '(?is)save_mobile_theme_preference')
) 'pgTAP test must exercise the fixed-purpose theme save function.'
Assert-Contract (
    [regex]::IsMatch($databaseTest, '(?is)anonymous authenticated session cannot insert')
) 'pgTAP test must cover anonymous authenticated sessions.'
Assert-Contract (
    [regex]::IsMatch($databaseTest, '(?is)another user cannot see the owner row')
) 'pgTAP test must cover cross-user isolation.'
Assert-Contract (
    [regex]::IsMatch($databaseTest, '(?is)authenticated user cannot insert a row for another owner')
) 'pgTAP test must cover cross-owner INSERT rejection.'
Assert-Contract (
    [regex]::IsMatch($databaseTest, '(?is)anon cannot select the table')
) 'pgTAP test must cover the anon role.'

Assert-Contract (
    [regex]::IsMatch($config, '(?ms)^\[db\.seed\].*?^enabled\s*=\s*false\s*$')
) 'Supabase seed must remain disabled until reviewed app-owned seed data exists.'
Assert-Contract (
    [regex]::IsMatch($config, '(?ms)^\[auth\].*?^enable_signup\s*=\s*false\s*$')
) 'Local Supabase signup must remain disabled.'
Assert-Contract (
    [regex]::IsMatch($config, '(?ms)^\[auth\].*?^enable_anonymous_sign_ins\s*=\s*false\s*$')
) 'Anonymous Supabase sign-in must remain disabled.'

Write-Output 'SUPABASE_FOUNDATION_STATIC_VALIDATION=PASS'
Write-Output ('MIGRATION=' + $migrations[0].Name)
Write-Output 'APP_OWNED_TABLES=1'
Write-Output 'RLS_POLICIES=3'
Write-Output 'PGTAP_ASSERTIONS=28'
