export class AnalysisError extends Error {
  readonly status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

export async function requestAnalysis(
  url: string,
  headers: Record<string, string>,
  payload: unknown,
  fetcher: typeof fetch = fetch,
  timeoutMs = 110000,
) {
  // RN 0.81's AbortSignal polyfill has no static timeout() method.
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetcher(`${url}/v1/occlusions`, {
      method: "POST",
      headers: { "content-type": "application/json", ...headers },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    let data;
    try {
      data = await response.json();
    } catch {
      throw new AnalysisError(
        "GPT returned an unreadable response. Please retry this image.",
        response.status,
      );
    }
    if (!response.ok) {
      throw new AnalysisError(
        typeof data?.error === "string"
          ? data.error
          : "GPT could not analyze this image. Please retry.",
        response.status,
      );
    }
    if (!data || !Array.isArray(data.masks)) {
      throw new AnalysisError(
        "GPT returned an invalid result. Please retry this image.",
        response.status,
      );
    }
    return data;
  } catch (error) {
    if (controller.signal.aborted) {
      throw new Error(
        "GPT took too long. Retry this image; your image is saved.",
      );
    }
    if (error instanceof AnalysisError) throw error;
    throw new Error(
      "Couldn’t reach GPT. Check your connection and retry; your image is saved.",
    );
  } finally {
    clearTimeout(timeout);
  }
}
