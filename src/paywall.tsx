import React, { useEffect } from "react";
import { Alert } from "react-native";
import {
  CustomPurchaseControllerProvider,
  SuperwallProvider,
  usePlacement,
  useSuperwall,
  useUser,
} from "expo-superwall";
import {
  initializePurchases,
  purchaseController,
  refreshSubscription,
  useSubscription,
} from "./subscriptions";
import { token } from "./services";

const apiKeys = {
  ios: process.env.EXPO_PUBLIC_SUPERWALL_IOS_KEY,
  android: process.env.EXPO_PUBLIC_SUPERWALL_ANDROID_KEY,
};
function SubscriptionSync() {
  const { setSubscriptionStatus } = useUser();
  const configured = useSuperwall((s) => s.isConfigured);
  const active = useSubscription((s) => s.active);
  const resolved = useSubscription((s) => s.resolved);
  useEffect(() => {
    void initializePurchases();
  }, []);
  useEffect(() => {
    if (!configured || !resolved) return;
    void setSubscriptionStatus(
      active
        ? {
            status: "ACTIVE",
            entitlements: [{ id: "insight_pro", type: "SERVICE_LEVEL" }],
          }
        : { status: "INACTIVE" },
    ).catch(() => {});
  }, [active, resolved, configured, setSubscriptionStatus]);
  return null;
}
export function PaywallProvider({ children }: { children: React.ReactNode }) {
  return (
    <CustomPurchaseControllerProvider controller={purchaseController}>
      <SuperwallProvider apiKeys={apiKeys}>
        <SubscriptionSync />
        {children}
      </SuperwallProvider>
    </CustomPurchaseControllerProvider>
  );
}
export function useProAction() {
  const { registerPlacement } = usePlacement({
    onError: () =>
      Alert.alert(
        "Couldn’t load Insight Pro",
        "Please check your connection and try again.",
      ),
  });
  const configured = useSuperwall((s) => s.isConfigured);
  return async (
    placement: "generate_occlusions" | "upgrade_tapped",
    action?: () => void | Promise<void>,
  ) => {
    // A secure, development-only token permits testing the protected preview.
    if (placement === "generate_occlusions" && __DEV__ && (await token())) {
      await action?.();
      return;
    }
    if (!configured) {
      Alert.alert(
        "Insight Pro is connecting",
        "Please try again in a moment. Your images are saved.",
      );
      return;
    }
    await initializePurchases();
    try {
      await registerPlacement({
        placement,
        feature: () => {
          if (!action) return;
          void (async () => {
            // Remote holdouts and non-gated paywalls cannot bypass paid GPT access.
            if (!(await refreshSubscription())) {
              Alert.alert(
                "Insight Pro required",
                "An active Insight subscription unlocks GPT image creation. You can also draw masks manually.",
              );
              return;
            }
            await action();
          })().catch(() =>
            Alert.alert(
              "Couldn’t verify access",
              "Check your connection and try again.",
            ),
          );
        },
      });
    } catch {
      Alert.alert("Couldn’t load Insight Pro", "Please try again.");
    }
  };
}
