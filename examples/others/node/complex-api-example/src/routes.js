const router = require('express').Router();
const pkg = require('../package.json');
const { pingUpstream, testUpstream } = require('./upstream');
const { wrap } = require('./utils');

const BASE_URL = process.env.NODE_BASE ? `/${process.env.NODE_BASE}` : '';

router.use((req, res, next) => {
  console.log(JSON.stringify({
    url: `${req.method} ${req.url}`,
    body: req.body
  }, null, 2));
  return next();
});

const sendStatus = async (req, res) => {
  const env = {};
  Object.keys(process.env).filter(x => (x && x.trim().toUpperCase() === x)).sort().forEach(key => {
    env[key] = process.env[key];
  });
  const upstream = await pingUpstream();

  res.json({
    name  : pkg.name,
    alias : process.env.NODE_ALIAS || '(not set)',
    base  : process.env.NODE_BASE || '(not set)',
    desc  : pkg.description,
    env   : process.env.NODE_ENV || '(not set)',
    ver   :  pkg.version,
    date  : (new Date()).toISOString(),
    upstream,
    env
  });
}
const testAll = async (req, res) => {
  const env = {};
  Object.keys(process.env).filter(x => (x && x.trim().toUpperCase() === x)).sort().forEach(key => {
    env[key] = process.env[key];
  });
  const upstream = await testUpstream();

  res.json({
    name  : pkg.name,
    alias : process.env.NODE_ALIAS || '(not set)',
    desc  : pkg.description,
    env   : process.env.NODE_ENV || '(not set)',
    ver   :  pkg.version,
    date  : (new Date()).toISOString(),
    upstream,
    env
  });
}

router.get(`${BASE_URL}/status`, wrap(sendStatus));
router.get(`${BASE_URL}/test`, wrap(testAll));
router.get(`${BASE_URL}/`, (req, res) => {
  res.json({
    name  : pkg.name,
    alias : process.env.NODE_ALIAS || '(not set)',
    base  : process.env.NODE_BASE || '(not set)',
    desc  : pkg.description,
    env   : process.env.NODE_ENV || '(not set)',
    ver   :  pkg.version,
    date  : (new Date()).toISOString()
  });
});

if (BASE_URL) {
  router.get(`/`, (req, res) => {
    res.json({
      name  : pkg.name,
      alias : process.env.NODE_ALIAS || '(not set)',
      base  : process.env.NODE_BASE || '(not set)',
      desc  : pkg.description,
      env   : process.env.NODE_ENV || '(not set)',
      root  : 'non-default root active',
      ver   :  pkg.version,
      date  : (new Date()).toISOString(),
    });
  });  
}

module.exports = router;
