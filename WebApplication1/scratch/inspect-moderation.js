const { Client } = require('pg');

async function main() {
  const client = new Client({
    host: 'localhost',
    port: 5432,
    database: 'navideals_dev',
    user: 'postgres',
    password: 'admin',
  });

  try {
    await client.connect();
    console.log('Connected to DB');

    console.log('\n--- ADMIN ACCOUNTS ---');
    const adminRes = await client.query('SELECT admin_id, email, first_name, last_name, role FROM admin_accounts;');
    console.log(adminRes.rows);

    console.log('\n--- MODERATION QUEUE ITEMS ---');
    const modRes = await client.query('SELECT item_id, content_type, title, status, report_count, "FlagReasons" FROM moderation_queue;');
    console.log(modRes.rows);

  } catch (err) {
    console.error('Error executing query', err);
  } finally {
    await client.end();
  }
}

main();
