const API_URL = process.env.ALLONBIZ_API_URL || 'http://localhost:5247/api/v1';
const ADMIN_EMAIL = process.env.ALLONBIZ_ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.ALLONBIZ_ADMIN_PASSWORD;

if (!ADMIN_EMAIL || !ADMIN_PASSWORD) {
  console.error('Set ALLONBIZ_ADMIN_EMAIL and ALLONBIZ_ADMIN_PASSWORD before running this script.');
  process.exit(1);
}

async function login() {
  const response = await fetch(`${API_URL}/admin/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD
    })
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(`Login failed: ${JSON.stringify(payload)}`);
  }

  return payload.data.accessToken;
}

async function testSync() {
  const token = await login();

  console.log('Testing POST /admin/categories/sync-firestore...');
  const response = await fetch(`${API_URL}/admin/categories/sync-firestore`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` }
  });

  const payload = await response.json();
  console.log('Sync Status:', response.status);
  console.log('Sync Response:', JSON.stringify(payload, null, 2));
}

testSync().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
