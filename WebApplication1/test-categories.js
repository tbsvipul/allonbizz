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

async function testCategories() {
  const token = await login();

  console.log('Testing GET /admin/categories...');
  const getResponse = await fetch(`${API_URL}/admin/categories`, {
    headers: { Authorization: `Bearer ${token}` }
  });
  const getPayload = await getResponse.json();
  console.log('GET Status:', getResponse.status);
  console.log('GET Data success:', getPayload.success);

  console.log('Testing POST /admin/categories...');
  const postResponse = await fetch(`${API_URL}/admin/categories`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      name: `Category ${Date.now()}`,
      icon: 'test',
      color: '#FF0000',
      description: 'Generated smoke-test category',
      isActive: true
    })
  });

  const postPayload = await postResponse.json();
  console.log('POST Status:', postResponse.status);
  console.log('POST Response:', JSON.stringify(postPayload, null, 2));
}

testCategories().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
