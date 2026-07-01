import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const https = require('node:https');

const url = 'https://productionresultssa0.blob.core.windows.net/actions-cache/test';
const req = https.request(url, { method: 'HEAD' }, (res) => {
    console.log('status:', res.statusCode);
    res.resume();
});
req.on('error', console.error);
req.end();