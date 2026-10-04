import { useColorScheme } from "react-native";
export const light = {
  bg: "#F7F8F3",
  surface: "#FFFFFF",
  ink: "#172E29",
  muted: "#74817B",
  line: "#E3E8DF",
  accent: "#17634D",
  soft: "#E6EFE6",
  hero: "#184B3B",
  white: "#FFFFFF",
  danger: "#AD413B",
  paper: "#F2F4EC",
};
export const dark = {
  bg: "#101C18",
  surface: "#1B2B24",
  ink: "#F0F4E9",
  muted: "#A2B0A4",
  line: "#30433A",
  accent: "#8BD3AC",
  soft: "#294638",
  hero: "#245541",
  white: "#FFFFFF",
  danger: "#F4A09A",
  paper: "#22372D",
};
export type Colors = typeof light;
export function useColors() {
  return useColorScheme() === "dark" ? dark : light;
}
