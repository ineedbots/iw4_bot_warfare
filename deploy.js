// nodejs 14+

const exec = require('util').promisify(require('child_process').exec)

const repo_name = 'iw4x_bot_warfare'
const repo_url = `https://github.com/ineedbots/${repo_name}`
const deploy_check_rate = 60000
const title = 'IW4x Bot Warfare Git Deployer'

function printToConsole(what, error = false)
{
  log = error ? console.error : console.log

  log(`[${new Date().toISOString()}]:`, what)
}

async function doDeploy() {
  try {
    const { stdout, stderr } = await exec(`cd ${repo_name} && git fetch`)

    if (stderr.length <= 0)
      return

    if (stderr.startsWith('From '))
    {
      printToConsole('git fetched! Pulling...')
      await exec(`cd ${repo_name} && git pull && git submodule update --init --recursive`)
      printToConsole('Deploying...')
      await exec('deploy.bat')
      printToConsole('Deployed!')
    }
  } catch (e) {
    printToConsole(e, true)

    if (!e.stderr.startsWith('The system cannot find the path specified'))
      return

    printToConsole('Cloning repo...')
    try {
      await exec(`git clone ${repo_url} && cd ${repo_name} && git submodule update --init --recursive`)

      printToConsole('Cloned!')
    } catch (f) {
      printToConsole(f, true)
    }
  }
}

process.stdout.write(`${String.fromCharCode(27)}]0;${title}${String.fromCharCode(7)}`)
doDeploy()
setInterval(doDeploy, deploy_check_rate)
