import React from "react";
import {
  Text,
  Pressable,
  View,
  ActivityIndicator,
  StyleSheet,
  ViewStyle,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { useColors } from "../theme";
export function Txt({
  children,
  style,
  muted = false,
  ...props
}: React.ComponentProps<typeof Text> & { muted?: boolean }) {
  const c = useColors();
  const metrics = StyleSheet.flatten(style);
  const fontSize = metrics?.fontSize ?? 16;
  return (
    <Text
      {...props}
      style={[
        {
          color: muted ? c.muted : c.ink,
          fontSize,
          lineHeight: metrics?.lineHeight ?? Math.ceil(fontSize * 1.4),
        },
        style,
      ]}
    >
      {children}
    </Text>
  );
}
export function SafeScreen({
  children,
  bottom = false,
}: {
  children: React.ReactNode;
  bottom?: boolean;
}) {
  const c = useColors();
  return (
    <SafeAreaView
      edges={bottom ? ["top", "bottom"] : ["top"]}
      style={{ flex: 1, backgroundColor: c.bg }}
    >
      {children}
    </SafeAreaView>
  );
}
export function Icon({
  name,
  size = 23,
  color,
}: {
  name: React.ComponentProps<typeof Ionicons>["name"];
  size?: number;
  color?: string;
}) {
  const c = useColors();
  return (
    <Ionicons
      name={name}
      size={size}
      color={color || c.ink}
      allowFontScaling={false}
    />
  );
}
export function Button({
  title,
  onPress,
  icon,
  secondary = false,
  disabled = false,
  loading = false,
  style,
}: {
  title: string;
  onPress: () => void;
  icon?: React.ComponentProps<typeof Ionicons>["name"];
  secondary?: boolean;
  disabled?: boolean;
  loading?: boolean;
  style?: ViewStyle;
}) {
  const c = useColors();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={title}
      disabled={disabled || loading}
      onPress={() => {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
        onPress();
      }}
      style={({ pressed }) => [
        {
          minHeight: 56,
          borderRadius: 18,
          backgroundColor: secondary ? c.soft : c.accent,
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "center",
          gap: 10,
          paddingHorizontal: 22,
          paddingVertical: 14,
          borderCurve: "continuous",
          opacity: disabled ? 0.4 : pressed ? 0.8 : 1,
        },
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={secondary ? c.ink : c.bg} />
      ) : icon ? (
        <Icon name={icon} size={21} color={secondary ? c.ink : c.bg} />
      ) : null}
      <Txt
        style={{
          fontWeight: "600",
          color: secondary ? c.ink : c.bg,
          flexShrink: 1,
          textAlign: "center",
        }}
      >
        {title}
      </Txt>
    </Pressable>
  );
}
export function IconButton({
  name,
  onPress,
  label,
  color,
}: {
  name: React.ComponentProps<typeof Ionicons>["name"];
  onPress: () => void;
  label: string;
  color?: string;
}) {
  const c = useColors();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={({ pressed }) => ({
        width: 46,
        height: 46,
        alignItems: "center",
        justifyContent: "center",
        borderRadius: 23,
        backgroundColor: c.soft,
        opacity: pressed ? 0.6 : 1,
      })}
    >
      <Icon name={name} color={color} />
    </Pressable>
  );
}
export function Eyebrow({ children }: { children: React.ReactNode }) {
  return (
    <Txt
      muted
      style={{
        fontSize: 11,
        fontWeight: "700",
        letterSpacing: 1.8,
        lineHeight: 16,
      }}
    >
      {children}
    </Txt>
  );
}
export function Section({
  title,
  action,
  onPress,
}: {
  title: string;
  action?: string;
  onPress?: () => void;
}) {
  return (
    <View
      style={{
        flexDirection: "row",
        alignItems: "center",
        justifyContent: "space-between",
        gap: 12,
        flexWrap: "wrap",
        marginTop: 28,
        marginBottom: 14,
      }}
    >
      <Txt style={{ fontSize: 22, fontWeight: "600", letterSpacing: -0.7 }}>
        {title}
      </Txt>
      {action &&
        (onPress ? (
          <Pressable
            accessibilityRole="button"
            onPress={onPress}
            hitSlop={10}
            style={{ minHeight: 44, justifyContent: "center" }}
          >
            <Txt muted style={{ fontSize: 14 }}>
              {action}
            </Txt>
          </Pressable>
        ) : (
          <Txt muted style={{ fontSize: 14 }}>
            {action}
          </Txt>
        ))}
    </View>
  );
}
export function Empty({
  title,
  detail,
  children,
}: {
  title: string;
  detail: string;
  children?: React.ReactNode;
}) {
  const c = useColors();
  return (
    <View
      style={{
        padding: 28,
        borderWidth: 1,
        borderColor: c.line,
        borderRadius: 24,
        gap: 12,
        alignItems: "center",
      }}
    >
      <Icon name="images-outline" size={34} />
      <Txt style={{ fontSize: 21, fontWeight: "600", textAlign: "center" }}>
        {title}
      </Txt>
      <Txt muted style={{ textAlign: "center" }}>
        {detail}
      </Txt>
      {children}
    </View>
  );
}
export const common = StyleSheet.create({
  page: { paddingHorizontal: 24, paddingTop: 18, paddingBottom: 40 },
  title: {
    fontSize: 35,
    lineHeight: 41,
    fontWeight: "700",
    letterSpacing: -1.4,
  },
  row: { flexDirection: "row", alignItems: "center", gap: 12 },
  card: { borderRadius: 24, padding: 20 },
  input: {
    minHeight: 54,
    borderRadius: 14,
    borderWidth: 1,
    paddingHorizontal: 16,
    fontSize: 16,
  },
});
