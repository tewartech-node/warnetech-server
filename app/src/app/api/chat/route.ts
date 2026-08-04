import { streamText } from "ai";
import { google } from "@ai-sdk/google";

export const dynamic = "force-dynamic";

export async function GET() {
  const result = streamText({
    // "gemini-flash-latest" is a Google-maintained alias that always points at
    // their current recommended flash model, so this doesn't need updating
    // when specific dated model versions get retired.
    model: google(process.env.GOOGLE_MODEL ?? "gemini-flash-latest"),
    prompt: "Explain quantum computing in simple terms.",
  });

  return result.toTextStreamResponse();
}
