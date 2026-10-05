import React, { useEffect, useRef } from "react";
import { Alert } from "react-native";
import { router } from "expo-router";
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
import { useStore } from "./store";
import { authorizeImageSharing } from "./analysis-consent";
import {
  performProAction,
  type AccessIssue,
  type ProPlacement,
} from "./pro-access";

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
  const pending = useRef(false);
  const reported = useRef(false);
  const report = (issue: AccessIssue) => {
    if (reported.current) return;
    reported.current = true;
    if (issue === "setup" && __DEV__) {
      Alert.alert(
        "Connect the GPT preview",
        "This development build needs its private preview token. Save it in Settings, then return to analyze your images.",
        [
          { text: "Cancel", style: "cancel" },
          { text: "Connect preview", onPress: () => router.push("/Settings") },
        ],
      );
      return;
    }
    const messages: Record<AccessIssue, [string, string]> = {
      preview: [
        "Couldn’t read preview access",
        "Reopen Insight and try again, or reconnect the private preview in Settings.",
      ],
      setup: [
        "Insight Pro is not available yet",
        "Store purchases are still being connected. Your images are saved, and you can draw masks manually.",
      ],
      connecting: [
        "Insight Pro is connecting",
        "Please try again in a moment. Your images are saved.",
      ],
      verification: [
        "Couldn’t verify Insight Pro",
        "Check your connection and try again. Your images are saved.",
      ],
      subscription: [
        "Insight Pro required",
        "An active Insight subscription unlocks GPT image creation. You can also draw masks manually.",
      ],
      paywall: [
        "Couldn’t load Insight Pro",
        "The subscription screen is unavailable. Please try again later. Your images are saved.",
      ],
      action: [
        "Couldn’t start analysis",
        "Your images are saved. Please try again.",
      ],
    };
    Alert.alert(...messages[issue]);
  };
  const { registerPlacement } = usePlacement({
    onError: () => {
      pending.current = false;
      report("paywall");
    },
    onDismiss: () => {
      pending.current = false;
    },
    onSkip: () => {
      pending.current = false;
    },
  });
  const configured = useSuperwall((s) => s.isConfigured);
  return async (
    placement: ProPlacement,
    action?: () => void | Promise<void>,
  ) => {
    if (pending.current) return;
    pending.current = true;
    reported.current = false;
    try {
      if (placement === "generate_occlusions" && action) {
        const allowed = await authorizeImageSharing({
          allowed: () => !!useStore.getState().analysisConsent,
          save: () => useStore.getState().setAnalysisConsent(true),
          ask: () =>
            new Promise<boolean>((resolve) =>
              Alert.alert(
                "Allow image analysis?",
                "Images you choose to analyze, their detected text, and text positions will be sent through Insight to OpenAI to find labels. OpenAI's API retention policies apply. You can turn this off in Settings and use manual masks anytime.",
                [
                  {
                    text: "Use manual masks",
                    style: "cancel",
                    onPress: () => resolve(false),
                  },
                  {
                    text: "Allow image analysis",
                    onPress: () => resolve(true),
                  },
                ],
                { cancelable: true, onDismiss: () => resolve(false) },
              ),
            ),
        });
        if (!allowed) return;
      }
      await performProAction(placement, action, {
        development: __DEV__,
        previewToken: token,
        initialize: initializePurchases,
        purchasesConfigured: () => useSubscription.getState().configured,
        subscribed: refreshSubscription,
        paywallConfigured: () => configured,
        present: (feature) => registerPlacement({ placement, feature }),
        report,
      });
    } finally {
      pending.current = false;
    }
  };
}
