// nodejs 14+

const exec = require('util').promisify(require('child_process').exec)

const repo_name = 'iw4x_bot_warfare'
const repo_url = `https://github.com/ineedbots/${repo_name}`
const deploy_check_rate = 60000

function setTerminalTitle(title)
{
  process.stdout.write(
    String.fromCharCode(27) + "]0;" + title + String.fromCharCode(7)
  );
}

setTerminalTitle('IW4x GitHub Deployer')

async function doDeploy() {
  try {
    const { stdout, stderr } = await exec(`cd ${repo_name} && git fetch`)

    if (stderr.length <= 0)
      return

    if (stderr.startsWith('From '))
    {
      console.log(Date.now(), 'git fetched! pulling and deploying...')
      await exec(`cd ${repo_name} && git pull && git submodule update --init --recursive`)
      await exec('deploy.bat')
    }
  } catch (e) {
    console.error(e); // should contain code (exit code) and signal (that caused the termination).

    console.log('Cloning...')
    try {
      await exec(`git clone ${repo_url} && cd ${repo_name} && git submodule update --init --recursive`)
    } catch (f) {
      console.error(f)
    }
  }
}

setInterval(doDeploy, deploy_check_rate)
