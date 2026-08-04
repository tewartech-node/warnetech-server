// Local reference script — mirrors src/app/api/chat/route.ts.
// Requires GOOGLE_GENERATIVE_AI_API_KEY in .env (get one free, no card,
// at https://aistudio.google.com/apikey), then:
//   node --env-file=.env index.mjs

import { streamText } from 'ai'
import { google } from '@ai-sdk/google'

const result = streamText({
  model: google(process.env.GOOGLE_MODEL ?? 'gemini-flash-latest'),
  prompt: 'Explain quantum computing in simple terms.',
})

for await (const chunk of result.textStream) {
  process.stdout.write(chunk)
}
