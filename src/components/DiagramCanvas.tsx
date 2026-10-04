import React from "react";
import { View } from "react-native";
import { Image } from "expo-image";
import { SvgXml } from "react-native-svg";
import { Diagram, Mask } from "../model";
import { useColors } from "../theme";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from "react-native-reanimated";
import { Txt } from "./UI";
export function DiagramImage({ diagram }: { diagram: Diagram }) {
  return diagram.svg ? (
    <SvgXml xml={diagram.svg} width="100%" height="100%" />
  ) : (
    <Image
      source={{ uri: diagram.uri }}
      style={{ width: "100%", height: "100%" }}
      contentFit="fill"
      cachePolicy="disk"
      recyclingKey={diagram.id}
    />
  );
}
export function MaskedDiagram({
  diagram,
  activeMask,
  revealed = false,
  all = false,
}: {
  diagram: Diagram;
  activeMask?: Mask;
  revealed?: boolean;
  all?: boolean;
}) {
  const c = useColors();
  return (
    <View
      style={{
        width: "100%",
        aspectRatio: diagram.width / diagram.height,
        overflow: "hidden",
        borderRadius: 20,
        backgroundColor: "#F5F6EE",
      }}
    >
      <DiagramImage diagram={diagram} />
      {diagram.masks
        .filter((m) => all || (m.id === activeMask?.id && !revealed))
        .map((m, i) => (
          <View
            key={m.id}
            style={{
              position: "absolute",
              left: `${m.x * 100}%`,
              top: `${m.y * 100}%`,
              width: `${m.width * 100}%`,
              height: `${m.height * 100}%`,
              borderRadius: 5,
              backgroundColor: c.hero,
              borderWidth: 1.5,
              borderColor: "#83AB88",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Txt
              style={{
                color: "#FFF",
                fontSize: 12,
                lineHeight: 14,
                fontWeight: "600",
              }}
            >
              {all ? "" : "?"}
            </Txt>
          </View>
        ))}
    </View>
  );
}
export function ZoomCanvas({ children }: { children: React.ReactNode }) {
  const size = useSharedValue({ width: 0, height: 0 });
  const scale = useSharedValue(1),
    saved = useSharedValue(1),
    x = useSharedValue(0),
    y = useSharedValue(0),
    sx = useSharedValue(0),
    sy = useSharedValue(0);
  const pinch = Gesture.Pinch()
    .onUpdate((e) => {
      scale.value = Math.min(4, Math.max(1, saved.value * e.scale));
    })
    .onEnd(() => {
      saved.value = scale.value;
      if (scale.value <= 1) {
        x.value = withTiming(0);
        y.value = withTiming(0);
        sx.value = 0;
        sy.value = 0;
      }
    });
  const pan = Gesture.Pan()
    .minPointers(1)
    .onUpdate((e) => {
      if (scale.value > 1) {
        const maxX = (size.value.width * (scale.value - 1)) / 2;
        const maxY = (size.value.height * (scale.value - 1)) / 2;
        x.value = Math.max(-maxX, Math.min(maxX, sx.value + e.translationX));
        y.value = Math.max(-maxY, Math.min(maxY, sy.value + e.translationY));
      }
    })
    .onEnd(() => {
      sx.value = x.value;
      sy.value = y.value;
    });
  const double = Gesture.Tap()
    .numberOfTaps(2)
    .onEnd(() => {
      const target = scale.value > 1 ? 1 : 2;
      saved.value = target;
      scale.value = withTiming(target);
      x.value = withTiming(0);
      y.value = withTiming(0);
      sx.value = 0;
      sy.value = 0;
    });
  const style = useAnimatedStyle(() => ({
    transform: [
      { translateX: x.value },
      { translateY: y.value },
      { scale: scale.value },
    ],
  }));
  return (
    <View
      onLayout={(e) => {
        size.value = e.nativeEvent.layout;
      }}
      style={{ overflow: "hidden", borderRadius: 20 }}
    >
      <GestureDetector gesture={Gesture.Simultaneous(pinch, pan, double)}>
        <Animated.View style={style}>{children}</Animated.View>
      </GestureDetector>
    </View>
  );
}
