const axios = require('axios');

const API_BASE = process.env.ALLONBIZ_API_URL || 'http://127.0.0.1:5247/api/v1';
const ADMIN_EMAIL = process.env.ALLONBIZ_ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.ALLONBIZ_ADMIN_PASSWORD;

if (!ADMIN_EMAIL || !ADMIN_PASSWORD) {
  console.error('Set ALLONBIZ_ADMIN_EMAIL and ALLONBIZ_ADMIN_PASSWORD before running this script.');
  process.exit(1);
}

async function test() {
  try {
    const loginResponse = await axios.post(`${API_BASE}/admin/auth/login`, {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD
    });

    const token = loginResponse.data.data.accessToken;
    console.log('Login OK');

    const shopsResponse = await axios.get(`${API_BASE}/admin/shops`, {
      headers: { Authorization: `Bearer ${token}` }
    });

    const shops = shopsResponse.data.data.data;
    console.log('Shops:', shops.length);

    if (shops.length > 0 && process.env.ALLONBIZ_TEST_UPDATE_SHOP === 'true') {
      const shopId = shops[0].id;
      const updateResponse = await axios.put(
        `${API_BASE}/admin/shops/${shopId}/status`,
        { isActive: true },
        { headers: { Authorization: `Bearer ${token}` } }
      );
      console.log('Updated first shop:', updateResponse.status);
    }
  } catch (error) {
    if (error.response) {
      console.error('Error:', error.response.status, error.response.data);
      return;
    }

    console.error('Error:', error.message);
  }
}

test();
