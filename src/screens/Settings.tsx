import React, { useState, useEffect } from "react";
import {
  View,
  ScrollView,
  TextInput,
  Alert,
  Pressable,
  Linking,
  Platform,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useStore } from "../store";
import { useColors } from "../theme";
import { token, setToken, runQueue } from "../services";
import { Button, Txt, Icon, Eyebrow, Section, common } from "../components/UI";
import { useSubscription } from "../subscriptions";
import { useProAction } from "../paywall";
export function SettingsScreen({ navigation }: any) {
  const c = useColors();
  const backend = useStore((s) => s.backendUrl);
  const [url, setUrl] = useState(backend),
    [access, setAccess] = useState(""),
    [saved, setSaved] = useState(false);
  const proAction = useProAction();
  const pro = useSubscription((s) => s.active);
  useEffect(() => {
    if (__DEV__) token().then((v) => setAccess(v || ""));
  }, []);
  return (
    <ScrollView
      keyboardShouldPersistTaps="handled"
      contentInsetAdjustmentBehavior="automatic"
      style={{ backgroundColor: c.bg }}
      contentContainerStyle={[common.page, { gap: 18 }]}
    >
      <Eyebrow>YOUR LEARNING SPACE</Eyebrow>
      <Txt style={common.title}>Simple by design.</Txt>
      <View
        style={{
          padding: 22,
          backgroundColor: c.hero,
          borderRadius: 24,
          gap: 15,
        }}
      >
        <Icon name="scan-outline" color="#DBE8D4" size={30} />
        <Txt style={{ fontSize: 24, fontWeight: "600", color: "#FFF" }}>
          Insight {pro ? "Pro" : "for the curious"}
        </Txt>
        <Txt style={{ color: "#BCCFBD", fontSize: 14 }}>
          Use your own images. Let GPT handle the labels. Keep your focus on
          understanding.
        </Txt>
        <Button
          title={pro ? "Manage subscription" : "Explore Insight Pro"}
          secondary
          onPress={() =>
            pro
              ? Linking.openURL(
                  Platform.OS === "ios"
                    ? "https://apps.apple.com/account/subscriptions"
                    : "https://play.google.com/store/account/subscriptions",
                )
              : proAction("upgrade_tapped")
          }
        />
      </View>
      <Section title="Your library stays with you" />
      <Txt muted>
        Images, masks, and study progress are saved on this device. Studying and
        manual mask creation work offline. GPT creation requires an internet
        connection.
      </Txt>
      <Pressable
        accessibilityRole="button"
        onPress={() => navigation.navigate("Privacy")}
        style={{
          minHeight: 48,
          flexDirection: "row",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <Txt>Privacy & your data</Txt>
        <Icon name="chevron-forward" size={17} />
      </Pressable>
      {__DEV__ && (
        <>
          <Section title="Developer connection" />
          <Txt muted style={{ fontSize: 13 }}>
            Production GPT access is verified by your subscription. A private
            preview token is available only in development builds.
          </Txt>
          <TextInput
            accessibilityLabel="Backend URL"
            defaultValue={url}
            onChangeText={(v) => {
              setUrl(v);
              setSaved(false);
            }}
            autoCapitalize="none"
            autoCorrect={false}
            keyboardType="url"
            placeholder="https://your-insight-worker.workers.dev"
            placeholderTextColor={c.muted}
            style={[
              common.input,
              { color: c.ink, borderColor: c.line, backgroundColor: c.surface },
            ]}
          />
          <TextInput
            accessibilityLabel="Private preview token"
            value={access}
            onChangeText={(v) => {
              setAccess(v);
              setSaved(false);
            }}
            secureTextEntry
            autoCapitalize="none"
            autoCorrect={false}
            placeholder="Private preview token"
            placeholderTextColor={c.muted}
            style={[
              common.input,
              { color: c.ink, borderColor: c.line, backgroundColor: c.surface },
            ]}
          />
          <Button
            title={saved ? "Connection saved" : "Save connection"}
            onPress={async () => {
              try {
                const parsed = new URL(url.trim());
                if (!["http:", "https:"].includes(parsed.protocol))
                  throw new Error();
                await setToken(access);
                useStore.getState().setBackend(url.trim().replace(/\/$/, ""));
                setSaved(true);
              } catch {
                Alert.alert(
                  "Check the connection",
                  "Enter a valid backend address.",
                );
              }
            }}
          />
          <Button
            title="Retry failed images"
            secondary
            onPress={() =>
              proAction("generate_occlusions", () => {
                for (const d of useStore
                  .getState()
                  .diagrams.filter((d) => d.status === "failed"))
                  useStore.getState().updateDiagram(d.id, {
                    status: "queued",
                    error: undefined,
                  });
                void runQueue();
              })
            }
          />
        </>
      )}
      <Txt muted style={{ fontSize: 12, textAlign: "center", marginTop: 22 }}>
        Insight · A clearer picture, every day.
      </Txt>
    </ScrollView>
  );
}
export function PrivacyScreen() {
  const c = useColors();
  return (
    <ScrollView
      contentInsetAdjustmentBehavior="automatic"
      style={{ backgroundColor: c.bg }}
      contentContainerStyle={[common.page, { gap: 21 }]}
    >
      <Eyebrow>YOUR PICTURES. YOUR PROGRESS.</Eyebrow>
      <Txt style={common.title}>A private place to learn.</Txt>
      <Txt style={{ fontWeight: "600" }}>On your device</Txt>
      <Txt muted>
        Your library, images, masks, and review history are saved locally. There
        is no cloud library sync in this version. Uninstalling the app removes
        its local library.
      </Txt>
      <Txt style={{ fontWeight: "600" }}>When you use GPT</Txt>
      <Txt muted>
        The image you choose to analyze, plus detected text and its positions,
        goes to the Insight backend and OpenAI to propose labels and
        explanations. The backend requests that responses are not stored.
        OpenAI’s applicable API data retention policies still apply. Studying
        and editing do not send your images to the backend.
      </Txt>
      <Txt style={{ fontWeight: "600" }}>Subscriptions</Txt>
      <Txt muted>
        Superwall presents subscription plans. RevenueCat and your app store
        process purchases and restores. The backend checks your RevenueCat
        customer identifier and active entitlement before analyzing an image.
      </Txt>
      <Txt style={{ fontWeight: "600" }}>Removing an image</Txt>
      <Txt muted>
        Delete a diagram from its editor to remove the local image and its
        masks. Delete a collection to remove its images and library records.
      </Txt>
      {process.env.EXPO_PUBLIC_PRIVACY_URL && (
        <Button
          title="Read full privacy policy"
          secondary
          onPress={() => Linking.openURL(process.env.EXPO_PUBLIC_PRIVACY_URL!)}
        />
      )}
    </ScrollView>
  );
}
export function ActivityScreen() {
  const c = useColors(),
    insets = useSafeAreaInsets();
  const reviews = useStore((s) => s.reviews),
    diagrams = useStore((s) => s.diagrams);
  const days = Array.from({ length: 7 }, (_, i) => {
    const date = new Date();
    date.setDate(date.getDate() - (6 - i));
    const count = reviews.filter(
      (r) => new Date(r.at).toDateString() === date.toDateString(),
    ).length;
    return {
      label: date.toLocaleDateString("en", { weekday: "narrow" }),
      count,
    };
  });
  const max = Math.max(5, ...days.map((d) => d.count));
  const total = reviews.length;
  const recalled = reviews.filter((r) => r.rating !== "again").length;
  const mature = diagrams
    .flatMap((d) => d.masks)
    .filter((m) => m.interval >= 21).length;
  return (
    <ScrollView
      contentInsetAdjustmentBehavior="automatic"
      style={{ backgroundColor: c.bg }}
      contentContainerStyle={[
        common.page,
        { paddingTop: insets.top + 23, gap: 19 },
      ]}
    >
      <Eyebrow>SMALL MOMENTS ADD UP</Eyebrow>
      <Txt style={common.title}>Look how far{"\n"}you’ve come.</Txt>
      <Txt muted>Every return to a picture builds understanding.</Txt>
      <View
        style={{
          padding: 23,
          backgroundColor: c.surface,
          borderRadius: 26,
          borderWidth: 1,
          borderColor: c.line,
          gap: 18,
        }}
      >
        <Txt style={{ fontWeight: "600" }}>Your last seven days</Txt>
        <View
          accessibilityLabel={days
            .map((d) => `${d.label}: ${d.count} reviews`)
            .join(", ")}
          style={{
            height: 154,
            flexDirection: "row",
            gap: 15,
            alignItems: "flex-end",
          }}
        >
          {days.map((d, i) => (
            <View key={i} style={{ flex: 1, alignItems: "center", gap: 9 }}>
              <Txt muted style={{ fontSize: 10 }}>
                {d.count || ""}
              </Txt>
              <View
                style={{
                  width: "100%",
                  height: Math.max(4, (d.count / max) * 100),
                  backgroundColor: i === 6 ? c.accent : c.soft,
                  borderRadius: 8,
                }}
              />
              <Txt muted style={{ fontSize: 12 }}>
                {d.label}
              </Txt>
            </View>
          ))}
        </View>
      </View>
      <View style={{ flexDirection: "row", gap: 12 }}>
        <View
          style={{
            flex: 1,
            padding: 20,
            backgroundColor: c.soft,
            borderRadius: 22,
          }}
        >
          <Txt style={{ fontSize: 30, fontWeight: "600" }}>{total}</Txt>
          <Txt muted style={{ fontSize: 13 }}>
            total reviews
          </Txt>
        </View>
        <View
          style={{
            flex: 1,
            padding: 20,
            backgroundColor: c.soft,
            borderRadius: 22,
          }}
        >
          <Txt style={{ fontSize: 30, fontWeight: "600" }}>
            {total ? `${Math.round((recalled / total) * 100)}%` : "—"}
          </Txt>
          <Txt muted style={{ fontSize: 13 }}>
            recalled
          </Txt>
        </View>
      </View>
      <View
        style={{
          padding: 22,
          borderRadius: 22,
          borderWidth: 1,
          borderColor: c.line,
          gap: 10,
        }}
      >
        <Icon name="leaf-outline" size={30} color={c.accent} />
        <Txt style={{ fontWeight: "600" }}>
          {mature
            ? `${mature} labels are taking root.`
            : "Give it time to take root."}
        </Txt>
        <Txt muted style={{ fontSize: 14 }}>
          Labels with review intervals of three weeks or longer show here. Keep
          returning, a little at a time.
        </Txt>
      </View>
    </ScrollView>
  );
}
