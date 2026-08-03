import { streamText } from "ai";

export const dynamic = "force-dynamic";

export async function GET() {
  const result = streamText({
    model: "openai/gpt-5.5",
    prompt: "Explain quantum computing in simple terms.",
  });

  return result.toTextStreamResponse();
}
