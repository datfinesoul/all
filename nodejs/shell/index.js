const fs = require('fs').promises

async function readPipedInput () {
  try {
    process.stdin.setEncoding('utf8')
    let inputData = ''
    for await (const chunk of process.stdin) {
      inputData += chunk
    }
    return inputData
  } catch (error) {
    console.error('Error:', error)
  }
}

const { promisify } = require('util')
const exec = promisify(require('node:child_process').exec)

async function runShellCommand (command) {
  try {
    const { stdout, stderr } = await exec(command)
    console.log('Command Output:', stdout)
    console.error('Command Error:', stderr)
  } catch (error) {
    console.error('Error executing command:', error)
  }
}
