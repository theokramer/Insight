import React, { useEffect } from "react";
import { ActivityIndicator, View, useColorScheme } from "react-native";
import { Stack, router } from "expo-router";
import {
  ThemeProvider,
  DefaultTheme,
  DarkTheme,
} from "@react-navigation/native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { StatusBar } from "expo-status-bar";
import { useColors } from "../theme";
import { useStore } from "../store";
import { runQueue } from "../services";
import { initializePurchases } from "../subscriptions";
import { PaywallProvider } from "../paywall";
import { IconButton } from "../components/UI";
function BackButton() {
  return (
    <IconButton
      name="chevron-back"
      label="Back"
      onPress={() =>
        router.canGoBack() ? router.back() : router.replace("/(tabs)")
      }
    />
  );
}
function Routes() {
  const c = useColors(),
    dark = useColorScheme() === "dark";
  const hydrated = useStore((s) => s.hydrated);
  useEffect(() => {
    if (hydrated) void initializePurchases().then(() => runQueue());
  }, [hydrated]);
  if (!hydrated)
    return (
      <View
        style={{
          flex: 1,
          backgroundColor: c.bg,
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <ActivityIndicator color={c.accent} />
      </View>
    );
  return (
    <ThemeProvider
      value={{
        ...(dark ? DarkTheme : DefaultTheme),
        colors: {
          ...(dark ? DarkTheme : DefaultTheme).colors,
          background: c.bg,
          card: c.bg,
          text: c.ink,
          border: c.line,
          primary: c.accent,
        },
      }}
    >
      <Stack
        screenOptions={{
          headerShadowVisible: false,
          headerStyle: { backgroundColor: c.bg },
          headerTintColor: c.ink,
          headerBackButtonDisplayMode: "minimal",
          contentStyle: { backgroundColor: c.bg },
          headerTitleStyle: { fontSize: 16, fontWeight: "600" },
        }}
      >
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen
          name="Deck"
          options={{ title: "Collection", headerLeft: () => <BackButton /> }}
        />
        <Stack.Screen
          name="NewDeck"
          options={{
            title: "Collection",
            presentation: "modal",
            headerRight: () => (
              <IconButton
                name="close"
                label="Close new collection"
                onPress={() => router.back()}
              />
            ),
          }}
        />
        <Stack.Screen
          name="Import"
          options={{
            title: "Add images",
            presentation: "modal",
            headerRight: () => (
              <IconButton
                name="close"
                label="Close import"
                onPress={() => router.back()}
              />
            ),
          }}
        />
        <Stack.Screen
          name="Editor"
          options={{ title: "Review masks", headerLeft: () => <BackButton /> }}
        />
        <Stack.Screen
          name="Settings"
          options={{
            title: "Settings",
            headerRight: () => (
              <IconButton
                name="close"
                label="Close settings"
                onPress={() =>
                  router.canGoBack() ? router.back() : router.replace("/(tabs)")
                }
              />
            ),
          }}
        />
        <Stack.Screen
          name="Privacy"
          options={{ title: "Privacy", headerLeft: () => <BackButton /> }}
        />
        <Stack.Screen
          name="Study"
          options={{
            headerShown: false,
            presentation: "fullScreenModal",
            gestureEnabled: false,
          }}
        />
        <Stack.Screen
          name="Complete"
          options={{
            headerShown: false,
            presentation: "fullScreenModal",
            gestureEnabled: false,
          }}
        />
      </Stack>
      <StatusBar style={dark ? "light" : "dark"} />
    </ThemeProvider>
  );
}
export default function RootLayout() {
  return (
    <PaywallProvider>
      <GestureHandlerRootView style={{ flex: 1 }}>
        <SafeAreaProvider>
          <Routes />
        </SafeAreaProvider>
      </GestureHandlerRootView>
    </PaywallProvider>
  );
}
