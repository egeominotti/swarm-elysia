import { Elysia } from "elysia";
import { hostname } from "os";

const app = new Elysia({
  precompile: true,
  serve: {
    maxRequestBodySize: 1024 * 1024 * 256,
    hostname: "0.0.0.0",
    port: 3000,
  },
})
  .get("/", () => "Hello Elysia")
  .get("/info", () => {
    const processInfo = {
      pid: process.pid,
      hostname: hostname(),
      containerID: getContainerID(),
      memoryUsage: process.memoryUsage(),
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    };

    return processInfo;
  })
  .listen(3000);

console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port} with PID ${process.pid}`
);

function getContainerID() {
  try {
    if (process.platform === "linux") {
      const fs = require("fs");
      const cgroupContent = fs.readFileSync("/proc/self/cgroup", "utf8");
      const matches = cgroupContent.match(/[0-9a-f]{64}/);
      return matches ? matches[0].substring(0, 12) : "non-docker";
    }
    return "non-linux";
  } catch (error) {
    return "unknown";
  }
}
