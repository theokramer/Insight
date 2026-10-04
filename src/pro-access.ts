export type ProPlacement = "generate_occlusions" | "upgrade_tapped";
export type AccessIssue =
  | "preview"
  | "setup"
  | "connecting"
  | "verification"
  | "subscription"
  | "paywall"
  | "action";

type AccessDependencies = {
  development: boolean;
  previewToken: () => Promise<string | null>;
  initialize: () => Promise<void>;
  purchasesConfigured: () => boolean;
  subscribed: () => Promise<boolean>;
  paywallConfigured: () => boolean;
  present: (feature: () => void) => Promise<void>;
  report: (issue: AccessIssue) => void;
};

// Keep access decisions independent from presentation so a broken paywall cannot
// block an authorized preview or subscriber, or unlock GPT for a remote holdout.
export async function performProAction(
  placement: ProPlacement,
  action: (() => void | Promise<void>) | undefined,
  deps: AccessDependencies,
) {
  const run = async () => {
    try {
      await action?.();
    } catch {
      deps.report("action");
    }
  };
  if (placement === "generate_occlusions" && deps.development) {
    let access;
    try {
      access = await deps.previewToken();
    } catch {
      deps.report("preview");
      return;
    }
    if (access) {
      await run();
      return;
    }
  }
  try {
    await deps.initialize();
  } catch {
    deps.report("verification");
    return;
  }
  if (!deps.purchasesConfigured()) {
    deps.report("setup");
    return;
  }
  if (placement === "generate_occlusions") {
    try {
      if (await deps.subscribed()) {
        await run();
        return;
      }
    } catch {
      deps.report("verification");
      return;
    }
  }
  if (!deps.paywallConfigured()) {
    deps.report("connecting");
    return;
  }
  let used = false;
  const feature = () => {
    if (used || !action) return;
    used = true;
    void (async () => {
      try {
        if (!(await deps.subscribed())) {
          deps.report("subscription");
          return;
        }
      } catch {
        deps.report("verification");
        return;
      }
      await run();
    })();
  };
  try {
    await deps.present(feature);
  } catch {
    deps.report("paywall");
  }
}
