# Agentic Bash (Or: How to Out-Engineer Trillion-Dollar Corporations)

Behold. You didn't need a multi-billion dollar AI research division. You didn't need a bloated Chromium-based desktop shell that takes screen recordings of your PC every two seconds to feed to a centralized cloud. 

You just needed a basic understanding of UNIX architecture and about 100 lines of bash script.

Welcome to **Agentic Bash**, a local-first, privacy-respecting script similar to an "Agentic OS" built on the radical, highly confidential architectural secret that **under Linux and Unix-likes, everything is already a text stream.**

---

<div align="center">
  <h3>"Why pay Microsoft tons of money to spy on you when you can run open models for cheap and break your own OS with open source?"<p align="right">--Sushimi Bakamoto</p></h3>
</div>

---

## 🧠 The Architecture (That Microsoft's R&D Couldn't Figure Out)

Instead of forcing a single LLM to struggle through doing the thinking and the typing at the exact same time (resulting in hallucinations and broken syntax), this system uses a highly sophisticated **Systems Architect / Junior Dev** hierarchy.

## FAQ

***Q: Is my data sent to OpenAI/Microsoft?***
A: No - not unless you explicitly choose to. It is processed entirely on your local GPU, your own local network server, or an API server of your choosing. If done locally, your terminal history and local directories remain yours. Imagine that.

***Q: Can it run on Haiku OS?***
A: No, because Ollama command isn't on Haiku AFAIK and I can't be damned to port it. Sorry, Sean.

***Q: What if the AI generates a command that formats my drive?***
A: That's why there is a literal Run this command? (y/N) prompt gate in the code. You are the final supervisor. If you press 'y' on rm -rf / --no-preserve-root, that's on you, boss.

***Q: Why not use OpenClaw, Hermes, or some other complex agent framework?***
They are way too bloated. They want you to install complex Python orchestration layers, manage Docker microservices, or configure external visual tools just to run a terminal command. We give you the raw tools, and let you do the rest—just like a good UNIX-like script should. Bash is all you need to bend an LLM to your terminal's will.
