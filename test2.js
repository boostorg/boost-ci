import { createRequire } from "module";
const require = createRequire(import.meta.url);
const https = require("node:https");

const agent = new https.Agent({ keepAlive: true });
const options = {
    agent,
    hostname: "productionresultssa0.blob.core.windows.net",
    path: "/actions-cache/test",
    port: "",
    method: "HEAD",
    headers: { "x-ms-version": "2025-11-05", "User-Agent": "azsdk-js-azure-storage-blob/12.32.0" },
};

console.log("before request");
const req = https.request(options, (res) => {
    console.log("response:", res.statusCode);
    process.exit(0);
});
console.log("after request");
req.on("error", (e) => { console.log("error:", e.message); process.exit(1); });
req.on("socket", (s) => {
    s.on("lookup", (e,a) => console.log("DNS:", a));
    s.on("connect", () => console.log("TCP connected"));
    s.on("secureConnect", () => console.log("TLS done"));
});
req.end();