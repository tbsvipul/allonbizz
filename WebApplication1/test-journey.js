// Test Journey API endpoints - using correct user auth endpoints
const BASE = 'http://localhost:5247/api/v1';

async function request(method, path, body, token) {
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json' },
  };
  if (token) opts.headers['Authorization'] = `Bearer ${token}`;
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${BASE}${path}`, opts);
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = text; }
  return { status: res.status, data };
}

async function main() {
  // Step 1: Register a user
  console.log('=== 1. Register User ===');
  const reg = await request('POST', '/auth/register-user', {
    firstName: 'Test',
    lastName: 'Journey',
    email: 'testjourney@test.com',
    password: 'Test@1234'
  });
  console.log('Register status:', reg.status);
  
  // Step 2: Login
  console.log('\n=== 2. User Login ===');
  const login = await request('POST', '/auth/user-login', {
    email: 'testjourney@test.com',
    password: 'Test@1234'
  });
  console.log('Login status:', login.status);
  
  const token = login.data?.data?.accessToken;
  if (!token) {
    console.log('No token. Response:', JSON.stringify(login.data, null, 2));
    return;
  }
  console.log('Token:', token.substring(0, 30) + '...');

  // === Test 1: Destination Journey ===
  console.log('\n=== 3. Start Destination Journey ===');
  const startDest = await request('POST', '/user/journeys/start', {
    startName: 'Home',
    startLat: 19.0760,
    startLng: 72.8777,
    type: 'destination',
    tags: ['food', 'shopping'],
    destinationName: 'Mall',
    destLat: 19.0896,
    destLng: 72.8656
  }, token);
  console.log('Status:', startDest.status, JSON.stringify(startDest.data));
  const journeyId = startDest.data?.data?.journeyId;

  if (journeyId) {
    console.log('\n=== 4. Update Progress ===');
    const prog = await request('POST', `/user/journeys/${journeyId}/progress`, {
      currentLat: 19.0800,
      currentLng: 72.8750,
      distance: 500.5,
      duration: 120,
      shopsEncountered: ['Shop A']
    }, token);
    console.log('Status:', prog.status, JSON.stringify(prog.data));

    console.log('\n=== 5. Nearby Shops ===');
    const nearby = await request('GET', `/user/journeys/${journeyId}/near?lat=19.08&lng=72.875&radius=10`, null, token);
    console.log('Status:', nearby.status, 'Shops found:', nearby.data?.data?.length ?? 0);

    console.log('\n=== 6. End Journey ===');
    const end = await request('POST', `/user/journeys/${journeyId}/end`, {
      endName: 'Mall Entrance',
      endLat: 19.0896,
      endLng: 72.8656,
      distance: 1500.0,
      duration: 600,
      shopsEncountered: ['Shop A', 'Shop B']
    }, token);
    console.log('Status:', end.status, JSON.stringify(end.data));
  }

  // === Test 2: Free Roam Journey ===
  console.log('\n=== 7. Start Free Roam ===');
  const startFree = await request('POST', '/user/journeys/start', {
    startName: 'Free Roam Start',
    startLat: 19.0760,
    startLng: 72.8777,
    type: 'freeRoam',
    tags: ['coffee']
  }, token);
  console.log('Status:', startFree.status, JSON.stringify(startFree.data));
  const freeId = startFree.data?.data?.journeyId;

  if (freeId) {
    const prog2 = await request('POST', `/user/journeys/${freeId}/progress`, {
      currentLat: 19.0770, currentLng: 72.8790, distance: 200, duration: 60, shopsEncountered: []
    }, token);
    console.log('Free roam progress:', prog2.status);

    const end2 = await request('POST', `/user/journeys/${freeId}/end`, {
      endName: 'Free Roam End', endLat: 19.0780, endLng: 72.8800, distance: 800, duration: 300, shopsEncountered: ['Cafe C']
    }, token);
    console.log('Free roam end:', end2.status);
  }

  // === Test 3: Past Journeys ===
  console.log('\n=== 8. Get Past Journeys ===');
  const journeys = await request('GET', '/user/journeys', null, token);
  console.log('Status:', journeys.status);
  if (journeys.data?.data) {
    console.log('Total journeys:', journeys.data.data.length);
    journeys.data.data.forEach((j, i) => {
      console.log(`  ${i+1}. type=${j.type} start="${j.startName}" end="${j.endName}" dist=${j.distance} dur=${j.duration} startTime=${j.startTime} tags=${JSON.stringify(j.tags)} shops=${JSON.stringify(j.shopsEncountered)}`);
    });
  } else {
    console.log('Response:', JSON.stringify(journeys.data, null, 2));
  }

  console.log('\n=== ALL TESTS COMPLETE ===');
}

main().catch(e => console.error('FATAL:', e));
