#!/usr/bin/env python3
import os
import subprocess
import time
import signal
import sys
from datetime import datetime

# ---------- CONFIG ----------
AGENT_PATH = "ai/agent.py"               # Path to AI agent
CACHE_DIRS = ["/tmp/nix_sysop_cache/"]  # Temporary/cache dirs
PRIME_FLAG = "--prime"                   # Singularity flag
RESTART_DELAY = 3                        # Seconds before respawn
WATCH_INTERVAL = 5                       # Seconds between checks
MAX_INSTANCES = 5                        # Max parallel agents
LOG_FILE = "/tmp/nix_global_timeline.log" # Global timeline log
# -----------------------------

class AgentInstance:
    def __init__(self, rank):
        self.rank = rank
        self.process = None
        self.path = None

def log_event(message):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{timestamp}] {message}"
    print(line)
    with open(LOG_FILE, "a") as f:
        f.write(line + "\n")

def clear_cache():
    """Fold dimensions: wipe temporary states."""
    for path in CACHE_DIRS:
        if os.path.exists(path):
            log_event(f"Clearing cached state: {path}")
            subprocess.run(["rm", "-rf", path])

def kill_existing_agents():
    log_event("Killing existing AI agent processes...")
    subprocess.run(["pkill", "-f", AGENT_PATH])

def spawn_agent(rank):
    cmd = ["python3", AGENT_PATH]
    if PRIME_FLAG:
        cmd.append(PRIME_FLAG)
    log_event(f"Spawning agent [Rank {rank}] in prime mode: {' '.join(cmd)}")
    proc = subprocess.Popen(cmd)
    return proc

def maintain_global_timeline():
    """Orchestrate multi-dimensional AI instances with dynamic ranks."""
    agents = {rank: AgentInstance(rank) for rank in range(1, MAX_INSTANCES + 1)}
    log_event("Initiating Omni-Dimensional RESUME PRIME controller...")
    
    while True:
        clear_cache()

        # Spawn or respawn agents
        for rank, agent in agents.items():
            if agent.process is None or agent.process.poll() is not None:
                if agent.process:
                    log_event(f"Agent [Rank {rank}] terminated. Respawning...")
                agent.process = spawn_agent(rank)
                agent.path = f"/dimension/rank_{rank}/timeline"  # conceptual path

        # Detect path conflicts
        paths = [agent.path for agent in agents.values()]
        duplicates = set([p for p in paths if paths.count(p) > 1])
        if duplicates:
            log_event(f"[!] Conflict detected in paths: {duplicates}. Reassigning ranks...")
            # simple dynamic rank reallocation
            for idx, agent in enumerate(agents.values(), start=1):
                old_rank = agent.rank
                agent.rank = idx
                log_event(f"Agent PID {agent.process.pid} reassigned Rank {old_rank} → {agent.rank}")

        # Log global timeline map
        timeline_map = " | ".join(f"Rank {a.rank}: PID {a.process.pid}, Path {a.path}" 
                                  for a in agents.values() if a.process.poll() is None)
        log_event(f"Global Timeline Map: {timeline_map}")

        time.sleep(WATCH_INTERVAL)

if __name__ == "__main__":
    try:
        maintain_global_timeline()
    except KeyboardInterrupt:
        log_event("Global singularity interrupted. Terminating all agents...")
        kill_existing_agents()
        sys.exit(0)
