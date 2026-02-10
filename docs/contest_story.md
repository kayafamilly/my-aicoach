# myAIcoach — Contest Project Story

## Elevator Pitch
**Your problem, your AI coach. Customize expertise and style, then get focused coaching sessions that help you decide, act, and stay consistent.**

## The Spark: Why I Built myAIcoach
The idea for **myAIcoach** came from a simple frustration: when you’re stuck—emotionally, financially, professionally, or in a relationship—most apps give you one of two things.

They either give you generic advice that doesn’t fit your reality, or they give you long content libraries where you’re left alone to do the work of translating information into action.

Real coaching is different. A good coach helps you slow down, clarify what matters, challenge your assumptions, and commit to a next step. The problem is access: coaching can be expensive, inconsistent, and hard to find across the different areas people struggle with.

So I asked myself a straightforward question:

What if anyone could have a focused, professional coaching conversation—anytime—on the topic they actually care about?

That became the foundation of myAIcoach.

## The Market Value: What Makes It Different
Most AI assistants try to do everything at once. That “generalist” behavior is exactly why they often feel shallow, inconsistent, or overly generic. myAIcoach is built around the opposite philosophy:

**specialization + customization = trust and usefulness.**

### Specialized coaches with real boundaries
myAIcoach ships with expert-style coaches across high-demand domains:

- Business mentoring for entrepreneurship and growth
- Therapy-style support for stress, anxiety, and emotional clarity
- Planning and productivity coaching for structure and execution
- Love and relationship coaching for communication and patterns
- Nutrition coaching for sustainable health habits
- Financial mentoring for budgeting and planning
- Parenting coaching for real family dynamics
- Confidence coaching for self-esteem and assertiveness

Each coach is designed to stay in its lane—like a real professional would. If a user asks for something outside the domain, the coach doesn’t pretend to know everything. It redirects, explains the boundary, and brings the conversation back to the right place.

That single choice dramatically improves the quality of the experience: the coaching feels more credible, more focused, and more human.

### The key differentiator: create your own AI coach
The real “level up” feature is that users can **create and customize their own coach for any topic** that’s personal to them.

Instead of giving people a blank prompt box and hoping they know how to “prompt engineer,” myAIcoach guides them through a structured process where they define:

- The coach’s identity and specialty
- The tone (professional, friendly, direct, empathetic)
- The expertise scope (what they’re truly strong at)
- The boundaries (what the coach should refuse and redirect)

This makes the experience feel like you’re building a real professional relationship with a coach that matches your situation, not using a generic chatbot.

### Optional web search for up-to-date context
When enabled for a custom coach, myAIcoach can search the web (via Brave Search API) to provide more current context when the user asks about fast-moving topics.

The goal is not to dump sources or paste links. It’s to help the coach ground advice in what’s happening now, while still delivering the answer in a conversational, coaching style.

## What I Learned Building It
Building myAIcoach taught me that “AI features” are rarely the hard part. The hard part is turning AI into a product people trust.

### Prompt engineering is product design
I learned to treat prompts as a product surface.

Tone, boundaries, refusal behavior, and conversation structure aren’t “details.” They are what make a coach feel professional.

A single rule—like “no markdown, no lists, no AI-speak”—can completely change how users experience the app.

### Reliability matters more than demos
Subscription flows, cancel scenarios, and edge cases don’t show up in mockups. But they define trust.

A product that feels great but breaks on real devices loses credibility instantly. Building myAIcoach forced me to test on-device and fix issues that only appear under real usage.

### UX is what makes AI feel human
The best AI model won’t save a bad experience.

myAIcoach is designed so that conversations feel like a real session:

- Plain text responses (no formatting tricks)
- Short, focused paragraphs
- A follow-up question that keeps the coaching moving
- Coaches that redirect off-topic requests instead of improvising

The goal is not entertainment. The goal is progress.

## How I Built It (Technical Overview)
myAIcoach is a **Flutter** app optimized for a real mobile experience.

- **Flutter + Material 3 UI** for a modern, clean interface
- **Provider** for state management (chat, subscription, theme)
- **Drift (SQLite)** for local storage of coaches, conversations, and messages
- **OpenRouter API** to generate AI coach responses
- **RevenueCat** for in-app purchase and subscription management
- **Brave Search API** for optional web search in custom coaches

### Local-first design
Conversations and custom coaches are stored locally on-device. This makes the app feel fast, private, and reliable.

### Dark / light mode as a user choice
I built a user-controlled theme toggle (not just system default), because personalization matters when you’re building a daily-use app.

### Professional legal and help pages
To make the product contest-ready and credible, I created Privacy Policy, Terms of Service, and Help & Support screens with coherent, professional content.

## Challenges I Faced (and How I Solved Them)
### 1) Making AI responses feel professional (not like a chatbot)
Early versions produced content that looked like “internet advice”: long, formatted, and sometimes list-heavy.

I solved this by enforcing global behavioral rules in the AI system prompt:

- No markdown
- No bullet points
- Plain conversational text
- Under a few short paragraphs
- End with one focused follow-up question

The result: coaches that feel more like a session and less like a content generator.

### 2) Preventing off-topic answers
General AI will confidently answer almost anything, which reduces trust.

Each built-in coach and custom coach prompt is designed with explicit boundaries. When a user asks outside the domain, the coach redirects politely and brings the conversation back to what it is built to do.

### 3) Subscription and trial logic on real devices
Paywalls are not just UI.

I had to handle cancellation correctly (cancel should never unlock access), ensure user-friendly error messages, and implement a trial model that matches the product rule: one custom coach during a 7-day trial.

### 4) Making “Create Coach” accessible
A blank prompt box is intimidating and leads to poor results.

I built a guided, step-by-step creation flow that generates a high-quality coach prompt automatically while still allowing advanced users to fine-tune it.

## What I’m Most Proud Of
I’m proud that myAIcoach is not a prototype.

It is a product with a clear value proposition:

- People don’t need more information; they need structured clarity.
- Specialization makes guidance feel credible.
- Customization makes guidance feel personal.
- A coaching-style conversation helps people decide, act, and stay consistent.

## Closing
myAIcoach is built on a belief that the next generation of AI apps won’t win by being the smartest chatbot.

They’ll win by being the most useful in real life.

By combining specialized expert coaches with the ability to create a coach for any personal challenge, myAIcoach turns AI into something practical: a consistent, focused coaching relationship that helps users move forward.
