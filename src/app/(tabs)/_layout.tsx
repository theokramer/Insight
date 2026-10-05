import React from "react";
import { View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Tabs, router } from "expo-router";
import { useColors } from "../../theme";
import { Icon } from "../../components/UI";
export default function TabLayout() {
  const c = useColors();
  const insets = useSafeAreaInsets();
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: c.accent,
        tabBarInactiveTintColor: c.muted,
        tabBarStyle: {
          backgroundColor: c.bg,
          borderTopColor: c.line,
          paddingTop: 8,
          height: 64 + insets.bottom,
          paddingBottom: insets.bottom,
        },
        tabBarIconStyle: { width: 38, height: 36 },
        tabBarLabelStyle: {
          fontSize: 10,
          lineHeight: 14,
          fontWeight: "600",
          marginTop: 3,
        },
        tabBarHideOnKeyboard: true,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: "Today",
          tabBarIcon: ({ color }) => (
            <Icon name="sunny-outline" color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="Library"
        options={{
          tabBarIcon: ({ color }) => (
            <Icon name="albums-outline" color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="Create"
        options={{
          tabBarIcon: ({ color }) => (
            <View
              style={{
                width: 34,
                height: 34,
                borderRadius: 12,
                backgroundColor: c.accent,
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Icon name="add" color={c.bg} size={25} />
            </View>
          ),
        }}
        listeners={() => ({
          tabPress: (e) => {
            e.preventDefault();
            router.push("/Import");
          },
        })}
      />
      <Tabs.Screen
        name="Activity"
        options={{
          tabBarIcon: ({ color }) => (
            <Icon name="stats-chart-outline" color={color} />
          ),
        }}
      />
    </Tabs>
  );
}
