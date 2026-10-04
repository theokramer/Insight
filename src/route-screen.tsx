import React from "react";
import { router, useLocalSearchParams, useNavigation } from "expo-router";
const paths: Record<string, string> = {
  Today: "/(tabs)",
  Home: "/(tabs)",
  Library: "/(tabs)/Library",
  Activity: "/(tabs)/Activity",
};
const destination = (
  name: string,
  params?: Record<string, string | number>,
) => ({ pathname: paths[name] || `/${name}`, params });
export function routeScreen(Screen: React.ComponentType<any>) {
  return function RouteScreen() {
    const params = useLocalSearchParams();
    const native = useNavigation();
    const navigation = {
      ...native,
      navigate: (name: string, args?: Record<string, string | number>) =>
        router.navigate(destination(name, args) as any),
      replace: (name: string, args?: Record<string, string | number>) =>
        router.replace(destination(name, args) as any),
      goBack: () =>
        router.canGoBack() ? router.back() : router.replace("/(tabs)"),
      popToTop: () => {
        router.dismissAll();
        router.replace("/(tabs)");
      },
    };
    return (
      <Screen
        key={`${params.diagramId || ""}:${params.deckId || ""}`}
        route={{ params }}
        navigation={navigation}
      />
    );
  };
}
