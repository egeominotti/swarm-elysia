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
      environment: {
        kubernetes: isKubernetes(),
        nodeEnv: Bun.env.NODE_ENV || "development",
        variables: getFilteredEnv(),
      },
    };

    return processInfo;
  })
  .listen(3000);

// Stampa informazioni dettagliate all'avvio del server
const envDetails = getFilteredEnv();
const k8sInfo = isKubernetes()
  ? `Running in Kubernetes cluster (Service: ${
      Bun.env.SWARM_APP_SERVICE_SERVICE_HOST || "unknown"
    })`
  : "Not running in Kubernetes";

console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${
    app.server?.port
  } with PID ${process.pid}
📊 Environment: ${Bun.env.NODE_ENV || "development"}
🏠 Hostname: ${hostname()}
🐳 Container ID: ${getContainerID()}
🔄 ${k8sInfo}
⏱️ Started at: ${new Date().toISOString()}
💾 Memory: ${Math.round(process.memoryUsage().rss / 1024 / 1024)}MB RSS
`
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

function isKubernetes() {
  return Boolean(
    Bun.env.KUBERNETES_SERVICE_HOST && Bun.env.KUBERNETES_SERVICE_PORT
  );
}

function getFilteredEnv() {
  // Filtra e restituisce solo le variabili d'ambiente che potrebbero essere utili
  // ma esclude eventuali informazioni sensibili
  const envVars = {};
  const safeEnvVars = [
    "NODE_ENV",
    "HOSTNAME",
    "KUBERNETES_SERVICE_HOST",
    "SWARM_APP_SERVICE_SERVICE_HOST",
    "SWARM_APP_SERVICE_PORT",
    "PATH",
    "TZ",
  ];

  for (const key of safeEnvVars) {
    if (key in Bun.env) {
      envVars[key] = Bun.env[key];
    }
  }

  return envVars;
}
