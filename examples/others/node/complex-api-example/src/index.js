require('dotenv').config();

const express = require('express');
const pkg = require('../package.json');
const routes = require('./routes');

const app = express();
app.use(express.json({limit: '50mb'}));
app.use(express.urlencoded({ limit: '50mb', extended: false }));
app.use(routes);

const NODE_ALIAS  = process.env.NODE_ALIAS || "(not set)"
const NODE_BASE   = process.env.NODE_BASE  || "(not set)"
const NODE_ENV    = process.env.NODE_ENV || "(not set)"
const NODE_PORT   = process.env.NODE_PORT || 3000;

app.use((err, req, res, next) => {
  console.log(err.stack)
  res.status(500).send('Something broke!')
})

app.listen(NODE_PORT, (err) => {
  if (err) { throw err; }
  console.log(`${pkg.description || pkg.name} v${pkg.version}`);
  console.log(`ALIAS: ${NODE_ALIAS}`);
  console.log(`BASE : ${NODE_BASE}`);
  console.log(`ENV  : ${NODE_ENV}`);
  console.log(`PORT : ${NODE_PORT}`);
});
