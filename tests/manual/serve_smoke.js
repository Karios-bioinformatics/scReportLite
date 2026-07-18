const http = require("http");
const fs = require("fs");
const path = require("path");

const root = path.resolve(process.argv[2] || process.cwd());
const port = Number(process.argv[3] || 8765);

const contentTypes = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8"
};

http.createServer((request, response) => {
  const pathname = decodeURIComponent(request.url.split("?")[0]);
  const relative = pathname === "/" ? "v070_smoke.html" : pathname.replace(/^\/+/, "");
  const filename = path.resolve(root, relative);

  if (!filename.startsWith(root + path.sep) && filename !== root) {
    response.writeHead(403);
    response.end("Forbidden");
    return;
  }

  fs.readFile(filename, (error, data) => {
    if (error) {
      response.writeHead(404);
      response.end("Not found");
      return;
    }
    response.setHeader("Content-Type", contentTypes[path.extname(filename)] || "application/octet-stream");
    response.end(data);
  });
}).listen(port, "127.0.0.1", () => {
  console.log(`Serving ${root} at http://127.0.0.1:${port}/`);
});
