export async function authorizeImageSharing(options: {
  allowed: () => boolean;
  ask: () => Promise<boolean>;
  save: () => void;
}) {
  if (options.allowed()) return true;
  if (!(await options.ask())) return false;
  options.save();
  return true;
}
