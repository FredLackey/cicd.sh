const _     = require('cleaner-node');
const fetch = require('node-fetch');

const PREFIX = 'UPSTREAM_';

const doGetPromise = (url) => {
  // console.log(`in doGetPromise : ${url}`);
  return fetch(url, {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' },
  })
  .then(response => response.json())
  .catch(error => console.log(_.objects.stringify(error)));
};
const doGet = async (url) => {
  try {
    const response = await doGetPromise(url);
    return response;
    } catch (ex) {
    return ex.message || 'ERROR'
  }
};

const pingUpstream = async () => {
  const results = {};
  const keys = Object.keys(process.env).filter(x => (x && x.startsWith(PREFIX)));
  if (keys.length === 0) {
    return null;
  }
  for (let i = 0; i < keys.length; i += 1) {
    const key = keys[i];
    let uri = process.env[key];
    if (uri && !uri.startsWith('http')) {
      uri = `http://${uri}`
    }
    results[key.substring(PREFIX.length)] = await doGet(uri) || 'FAIL'
  } 
  return results;
}
const testUpstream = async () => {
  const results = {};
  const keys = Object.keys(process.env).filter(x => (x && x.startsWith(PREFIX)));
  if (keys.length === 0) {
    return null;
  }
  for (let i = 0; i < keys.length; i += 1) {
    const key = keys[i];
    let uri = process.env[key];
    if (uri && !uri.startsWith('http')) {
      uri = `http://${uri}/test`
    }
    results[key.substring(PREFIX.length)] = await doGet(uri) || 'FAIL'
  } 
  return results;
}

module.exports = {
  pingUpstream,
  testUpstream
};