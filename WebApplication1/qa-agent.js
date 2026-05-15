const API_URL = process.env.ALLONBIZ_API_URL || 'http://localhost:5247/api/v1';

function createPassword() {
  const nonce = Date.now().toString(36);
  return `Qa${nonce}9!a`;
}

async function qaVerify() {
  console.log('allonbiz QA agent: starting verification flow');

  const testUser = {
    email: `qa_test_${Date.now()}@example.com`,
    password: createPassword(),
    firstName: 'QA',
    lastName: 'Agent'
  };

  try {
    console.log('Step 1: register test user');
    const registrationResponse = await fetch(`${API_URL}/auth/register-user`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(testUser)
    });

    const registrationPayload = await registrationResponse.json();
    if (!registrationResponse.ok || !registrationPayload.data?.accessToken) {
      throw new Error(`Registration failed: ${JSON.stringify(registrationPayload)}`);
    }

    const userId = registrationPayload.data.userId;
    console.log(`Registration succeeded for ${userId}`);

    console.log('Step 2: login with the new account');
    const loginResponse = await fetch(`${API_URL}/auth/user-login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testUser.email,
        password: testUser.password
      })
    });

    const loginPayload = await loginResponse.json();
    if (!loginResponse.ok || !loginPayload.data?.accessToken) {
      throw new Error(`Login failed: ${JSON.stringify(loginPayload)}`);
    }

    console.log(`Login succeeded for ${testUser.email}`);

    console.log('Step 3: check health endpoint');
    const healthResponse = await fetch('http://localhost:5247/health');
    console.log(`Health status: ${healthResponse.status}`);

    console.log('QA verification result: success');
  } catch (error) {
    console.error('QA verification failed');
    console.error(error.message);
    process.exit(1);
  }
}

qaVerify();
