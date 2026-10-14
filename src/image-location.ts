// iOS moves an app's data container during reinstalls and updates. Persisted
// absolute URLs can become stale while Documents and its images are retained.
export function currentImageUri(
  uri: string | undefined,
  documentDirectory: string | null,
): string | undefined {
  if (!uri || !documentDirectory || !uri.startsWith("file://")) return uri;
  const filename = uri.match(/\/diagrams\/([a-z0-9-]+\.jpg)$/i)?.[1];
  return filename
    ? `${documentDirectory.replace(/\/$/, "")}/diagrams/${filename}`
    : uri;
}
