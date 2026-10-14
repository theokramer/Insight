import Purchases, {
  CustomerInfo,
  PRODUCT_CATEGORY,
  PURCHASES_ERROR_CODE,
} from "react-native-purchases";
import { Platform } from "react-native";
import { create } from "zustand";
export const ENTITLEMENT =
  process.env.EXPO_PUBLIC_REVENUECAT_ENTITLEMENT || "insight_pro";
export const useSubscription = create<{
  configured: boolean;
  active: boolean;
  resolved: boolean;
  error?: string;
  setInfo: (info: CustomerInfo) => void;
}>((set) => ({
  configured: false,
  active: false,
  resolved: false,
  setInfo: (info) =>
    set({
      active: !!info.entitlements.active[ENTITLEMENT],
      resolved: true,
      error: undefined,
    }),
}));
let initialization: Promise<void> | undefined;
export function initializePurchases(): Promise<void> {
  return (initialization ||= configurePurchases().finally(() => {
    if (!useSubscription.getState().configured) initialization = undefined;
  }));
}
async function configurePurchases() {
  const key =
    Platform.OS === "ios"
      ? process.env.EXPO_PUBLIC_REVENUECAT_IOS_KEY
      : process.env.EXPO_PUBLIC_REVENUECAT_ANDROID_KEY;
  if (!key) return;
  try {
    Purchases.configure({ apiKey: key });
    useSubscription.setState({ configured: true });
    Purchases.addCustomerInfoUpdateListener((info) =>
      useSubscription.getState().setInfo(info),
    );
  } catch {
    useSubscription.setState({
      configured: false,
      error: "Subscriptions could not connect. Please try again.",
    });
    return;
  }
  try {
    await refreshSubscription();
  } catch {
    // The SDK is configured even when an offline launch cannot fetch access.
    // Keep it ready so the next purchase, restore, or Pro action can reconnect.
    useSubscription.setState({
      resolved: true,
      error: "Could not check your subscription. Please check your connection.",
    });
  }
}
export async function refreshSubscription() {
  if (!useSubscription.getState().configured) return false;
  const info = await Purchases.getCustomerInfo();
  useSubscription.getState().setInfo(info);
  return !!info.entitlements.active[ENTITLEMENT];
}
export async function subscriberId() {
  if (!(await refreshSubscription()))
    throw new Error("Insight Pro is required for GPT image creation.");
  return Purchases.getAppUserID();
}
export async function restore() {
  if (!useSubscription.getState().configured)
    throw new Error("Subscriptions are not configured yet.");
  const info = await Purchases.restorePurchases();
  useSubscription.getState().setInfo(info);
  return !!info.entitlements.active[ENTITLEMENT];
}

// Superwall owns presentation. RevenueCat owns the store transaction and access.
export const purchaseController: import("expo-superwall").CustomPurchaseControllerContext =
  {
    async onPurchase(params) {
      await initializePurchases();
      if (!useSubscription.getState().configured)
        return { type: "failed", error: "Purchases are not connected yet." };
      try {
        const products = await Purchases.getProducts(
          [params.productId],
          PRODUCT_CATEGORY.SUBSCRIPTION,
        );
        const product = products.find(
          (p) =>
            p.identifier === params.productId ||
            (params.platform === "android" &&
              p.identifier === `${params.productId}:${params.basePlanId}`),
        );
        if (!product)
          return {
            type: "failed",
            error: "This plan is unavailable in the store.",
          };
        let result;
        if (params.platform === "android") {
          const optionId = params.offerId
            ? `${params.basePlanId}:${params.offerId}`
            : params.basePlanId;
          const option = product.subscriptionOptions?.find(
            (o) => o.id === optionId,
          );
          if (!option)
            return {
              type: "failed",
              error: "The selected plan is unavailable.",
            };
          result = await Purchases.purchaseSubscriptionOption(option);
        } else result = await Purchases.purchaseStoreProduct(product);
        useSubscription.getState().setInfo(result.customerInfo);
        return result.customerInfo.entitlements.active[ENTITLEMENT]
          ? { type: "purchased" }
          : { type: "pending" };
      } catch (error: any) {
        if (
          error.userCancelled ||
          error.code === PURCHASES_ERROR_CODE.PURCHASE_CANCELLED_ERROR
        )
          return { type: "cancelled" };
        if (error.code === PURCHASES_ERROR_CODE.PAYMENT_PENDING_ERROR)
          return { type: "pending" };
        return {
          type: "failed",
          error:
            "The store could not complete your purchase. Please try again.",
        };
      }
    },
    async onPurchaseRestore() {
      try {
        await initializePurchases();
        return (await restore())
          ? { type: "restored" }
          : {
              type: "failed",
              error: "No active Insight Pro subscription was found.",
            };
      } catch {
        return {
          type: "failed",
          error: "Could not restore purchases. Please check your connection.",
        };
      }
    },
  };
