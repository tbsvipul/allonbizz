const { spawn } = require('node:child_process');

const env = { ...process.env };
delete env.DEBUG;
delete env.NEXT_TEST_MODE;
delete env.__NEXT_TEST_MODE;

const nextBin = require.resolve('next/dist/bin/next');
const extraArgs = process.argv.slice(2);
const args = [nextBin, 'dev', '--webpack', ...extraArgs];

const child = spawn(process.execPath, args, {
  stdio: 'inherit',
  env,
});

child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }

  process.exit(code ?? 0);
});
