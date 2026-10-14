// Persisted development settings must never redirect a production image upload.
export function backendAddress(
  development: boolean,
  configured: string | undefined,
  persisted?: string,
): string {
  const address = (development ? persisted || configured : configured)?.trim();
  if (!address && development) return "http://localhost:8787";
  if (!address)
    throw new Error("Image analysis is not connected. Please contact support.");
  const parsed = new URL(address);
  const local =
    /^(localhost|127\.0\.0\.1|10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(1[6-9]|2\d|3[01])\.\d+\.\d+)$/.test(
      parsed.hostname,
    );
  if (
    (parsed.protocol !== "https:" &&
      !(development && parsed.protocol === "http:" && local)) ||
    parsed.username ||
    parsed.password ||
    parsed.search ||
    parsed.hash
  )
    throw new Error("Image analysis needs a secure backend address.");
  return parsed.toString().replace(/\/$/, "");
}
