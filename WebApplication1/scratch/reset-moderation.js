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

    console.log('Resetting moderation queue items...');
    const result = await client.query(`
      UPDATE moderation_queue
      SET status = 'pending',
          reviewed_by = NULL,
          reviewed_at = NULL,
          rejection_reason = NULL;
    `);
    console.log(`Updated ${result.rowCount} rows.`);

    console.log('\n--- CURRENT MODERATION QUEUE ITEMS ---');
    const modRes = await client.query('SELECT item_id, content_type, title, status, report_count, "FlagReasons" FROM moderation_queue;');
    console.log(modRes.rows);

  } catch (err) {
    console.error('Error executing query', err);
  } finally {
    await client.end();
  }
}

main();
