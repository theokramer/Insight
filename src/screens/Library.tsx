import React, { useState } from "react";
import {
  View,
  ScrollView,
  Pressable,
  TextInput,
  Alert,
  FlatList,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useStore, dueMasks } from "../store";
import { useColors } from "../theme";
import {
  Button,
  Txt,
  Icon,
  IconButton,
  Eyebrow,
  Section,
  Empty,
  SafeScreen,
  common,
} from "../components/UI";
import { MaskedDiagram } from "../components/DiagramCanvas";
import { Deck, id } from "../model";
import { deleteCollection } from "../services";
export function DeckRow({ deck, navigation }: { deck: Deck; navigation: any }) {
  const c = useColors();
  const allDiagrams = useStore((s) => s.diagrams);
  const diagrams = allDiagrams.filter((d) => d.deckId === deck.id);
  const count = diagrams.reduce((n, d) => n + d.masks.length, 0);
  const due = dueMasks(diagrams).length;
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${deck.title}, ${count} labels, ${due} due`}
      onPress={() => navigation.navigate("Deck", { deckId: deck.id })}
      style={({ pressed }) => ({
        paddingVertical: 16,
        borderBottomWidth: 1,
        borderBottomColor: c.line,
        flexDirection: "row",
        alignItems: "center",
        gap: 14,
        opacity: pressed ? 0.6 : 1,
      })}
    >
      <View
        style={{
          width: 57,
          height: 63,
          borderRadius: 16,
          backgroundColor: c.soft,
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Icon name={deck.symbol} size={26} color={c.accent} />
      </View>
      <View style={{ flex: 1, gap: 3 }}>
        <Txt style={{ fontWeight: "600", fontSize: 17 }}>{deck.title}</Txt>
        <Txt muted style={{ fontSize: 13 }}>
          {diagrams.length} {diagrams.length === 1 ? "diagram" : "diagrams"} ·{" "}
          {count} labels
        </Txt>
      </View>
      {due > 0 ? (
        <View
          style={{
            paddingHorizontal: 10,
            paddingVertical: 5,
            borderRadius: 12,
            backgroundColor: c.soft,
          }}
        >
          <Txt style={{ fontSize: 12, color: c.accent, fontWeight: "700" }}>
            {due} due
          </Txt>
        </View>
      ) : (
        <Icon name="chevron-forward" size={17} color={c.muted} />
      )}
    </Pressable>
  );
}
export function TodayScreen({ navigation }: any) {
  const c = useColors();
  const diagrams = useStore((s) => s.diagrams),
    decks = useStore((s) => s.decks),
    reviews = useStore((s) => s.reviews);
  const due = dueMasks(diagrams);
  const sample = due[0]?.diagram || diagrams.find((d) => d.status === "ready");
  const today = reviews.filter(
    (r) => new Date(r.at).toDateString() === new Date().toDateString(),
  ).length;
  return (
    <SafeScreen>
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        style={{ backgroundColor: c.bg }}
        contentContainerStyle={[common.page, { paddingTop: 12 }]}
      >
        <View
          style={[
            common.row,
            { justifyContent: "space-between", marginBottom: 32 },
          ]}
        >
          <View style={common.row}>
            <View
              style={{
                width: 31,
                height: 31,
                backgroundColor: c.accent,
                borderRadius: 10,
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Icon name="scan-outline" color={c.bg} size={21} />
            </View>
            <Txt
              style={{ fontWeight: "700", fontSize: 22, letterSpacing: -0.8 }}
            >
              insight
            </Txt>
          </View>
          <IconButton
            name="options-outline"
            label="Settings"
            onPress={() => navigation.navigate("Settings")}
          />
        </View>
        <Eyebrow>YOUR DAILY MOMENT</Eyebrow>
        <Txt style={[common.title, { marginTop: 7 }]}>Make it stick.</Txt>
        <Txt muted style={{ marginTop: 8, marginBottom: 24 }}>
          A little focus. A clearer picture.
        </Txt>
        <View
          style={{
            backgroundColor: c.hero,
            borderRadius: 28,
            padding: 22,
            gap: 16,
          }}
        >
          <View style={[common.row, { justifyContent: "space-between" }]}>
            <View style={{ gap: 3, flex: 1 }}>
              <Txt
                style={{
                  color: "#BCCFBD",
                  fontSize: 11,
                  fontWeight: "700",
                  letterSpacing: 1.4,
                }}
              >
                READY WHEN YOU ARE
              </Txt>
              <Txt
                style={{
                  color: "#FFF",
                  fontSize: 27,
                  lineHeight: 32,
                  fontWeight: "600",
                  letterSpacing: -0.6,
                }}
              >
                {due.length
                  ? `${due.length} labels to remember.`
                  : "A moment well spent."}
              </Txt>
            </View>
            <Icon name="sunny-outline" color="#B8CDBB" size={26} />
          </View>
          {sample && (
            <View
              style={{
                backgroundColor: "#F5F6EE",
                borderRadius: 20,
                overflow: "hidden",
              }}
            >
              <View>
                <MaskedDiagram diagram={sample} all />
              </View>
              <View
                style={{
                  margin: 12,
                  backgroundColor: "#FFF",
                  paddingHorizontal: 10,
                  paddingVertical: 5,
                  borderRadius: 10,
                }}
              >
                <Txt
                  style={{ color: "#25463B", fontSize: 10, fontWeight: "600" }}
                >
                  A picture. A few hidden labels. You’ve got this.
                </Txt>
              </View>
            </View>
          )}
          <Pressable
            accessibilityRole="button"
            onPress={() =>
              due.length
                ? navigation.navigate("Study", {})
                : navigation.navigate("Import", {})
            }
            style={({ pressed }) => ({
              minHeight: 55,
              paddingVertical: 14,
              backgroundColor: "#F0F4E9",
              borderRadius: 17,
              flexDirection: "row",
              alignItems: "center",
              justifyContent: "space-between",
              paddingHorizontal: 18,
              opacity: pressed ? 0.8 : 1,
            })}
          >
            <Txt style={{ color: "#1C4F3D", fontWeight: "700", flex: 1 }}>
              {due.length ? "Start a quick session" : "Add something to learn"}
            </Txt>
            <Icon name="arrow-forward" color="#1C4F3D" size={21} />
          </Pressable>
          <Txt style={{ color: "#BCCFBD", fontSize: 12, textAlign: "center" }}>
            One hidden label at a time · At your pace
          </Txt>
        </View>
        <View style={{ flexDirection: "row", marginTop: 22, gap: 10 }}>
          <View
            style={{
              flex: 1,
              padding: 16,
              borderRadius: 20,
              backgroundColor: c.soft,
            }}
          >
            <Txt
              style={{
                fontSize: 23,
                fontWeight: "600",
                fontVariant: ["tabular-nums"],
              }}
            >
              {today}
            </Txt>
            <Txt muted style={{ fontSize: 12 }}>
              reviewed today
            </Txt>
          </View>
          <View
            style={{
              flex: 1,
              padding: 16,
              borderRadius: 20,
              backgroundColor: c.soft,
            }}
          >
            <Txt
              style={{
                fontSize: 23,
                fontWeight: "600",
                fontVariant: ["tabular-nums"],
              }}
            >
              {diagrams.filter((d) => d.status === "ready").length}
            </Txt>
            <Txt muted style={{ fontSize: 12 }}>
              pictures to explore
            </Txt>
          </View>
        </View>
        <Section
          title="Your collections"
          action="View all"
          onPress={() => navigation.navigate("Library")}
        />
        {decks.slice(0, 3).map((deck) => (
          <DeckRow key={deck.id} deck={deck} navigation={navigation} />
        ))}
        {!decks.length && (
          <Empty
            title="A blank canvas"
            detail="Bring a diagram you want to understand."
          >
            <Button
              title="Add images"
              onPress={() => navigation.navigate("Import", {})}
            />
          </Empty>
        )}
        <Pressable
          accessibilityRole="button"
          onPress={() => navigation.navigate("Import", {})}
          style={{
            marginTop: 26,
            padding: 20,
            borderRadius: 22,
            borderWidth: 1,
            borderStyle: "dashed",
            borderColor: c.line,
            flexDirection: "row",
            gap: 14,
            alignItems: "center",
          }}
        >
          <Icon name="add-circle-outline" size={27} color={c.accent} />
          <View style={{ flex: 1 }}>
            <Txt style={{ fontWeight: "600" }}>Turn pictures into practice</Txt>
            <Txt muted style={{ fontSize: 13 }}>
              Add a whole chapter in one go.
            </Txt>
          </View>
          <Icon name="arrow-forward" size={18} />
        </Pressable>
      </ScrollView>
    </SafeScreen>
  );
}
export function LibraryScreen({ navigation }: any) {
  const c = useColors(),
    insets = useSafeAreaInsets();
  const decks = useStore((s) => s.decks);
  const [query, setQuery] = useState("");
  const filtered = decks.filter((d) =>
    d.title.toLowerCase().includes(query.toLowerCase()),
  );
  return (
    <View
      style={{
        flex: 1,
        backgroundColor: c.bg,
        paddingTop: insets.top + 20,
        paddingHorizontal: 24,
      }}
    >
      <View
        style={[
          common.row,
          { justifyContent: "space-between", marginBottom: 20 },
        ]}
      >
        <Txt style={common.title}>Your library.</Txt>
        <IconButton
          name="add"
          label="Create collection"
          onPress={() => navigation.navigate("NewDeck")}
        />
      </View>
      <View
        style={[
          common.row,
          {
            backgroundColor: c.soft,
            borderRadius: 15,
            paddingHorizontal: 15,
            marginBottom: 20,
          },
        ]}
      >
        <Icon name="search-outline" size={20} color={c.muted} />
        <TextInput
          accessibilityLabel="Search collections"
          placeholder="Find a collection"
          placeholderTextColor={c.muted}
          value={query}
          onChangeText={setQuery}
          style={{ flex: 1, height: 54, fontSize: 16, color: c.ink }}
        />
      </View>
      <Eyebrow>{decks.length} COLLECTIONS · YOUR KNOWLEDGE, GROWING</Eyebrow>
      <FlatList
        data={filtered}
        keyExtractor={(d) => d.id}
        renderItem={({ item }) => (
          <DeckRow deck={item} navigation={navigation} />
        )}
        contentContainerStyle={{ paddingBottom: 30, paddingTop: 6 }}
        ListEmptyComponent={
          <View style={{ marginTop: 25 }}>
            <Empty
              title={query ? "No matches yet" : "Start your first collection"}
              detail={
                query
                  ? "Try a different name."
                  : "Group diagrams by subject or chapter."
              }
            >
              {!query && (
                <Button
                  title="New collection"
                  onPress={() => navigation.navigate("NewDeck")}
                />
              )}
            </Empty>
          </View>
        }
      />
    </View>
  );
}
export function DeckScreen({ route, navigation }: any) {
  const c = useColors();
  const deck = useStore((s) =>
    s.decks.find((d) => d.id === route.params.deckId),
  );
  const allDiagrams = useStore((s) => s.diagrams);
  const diagrams = allDiagrams.filter((d) => d.deckId === route.params.deckId);
  const due = dueMasks(diagrams);
  if (!deck)
    return (
      <View style={[common.page, { gap: 20 }]}>
        <Txt style={common.title}>This collection is unavailable.</Txt>
        <Button title="Back to library" onPress={() => navigation.popToTop()} />
      </View>
    );
  const labels = diagrams.reduce((n, d) => n + d.masks.length, 0);
  return (
    <FlatList
      style={{ backgroundColor: c.bg }}
      data={diagrams}
      numColumns={2}
      keyExtractor={(d) => d.id}
      contentContainerStyle={{ padding: 24, gap: 14, paddingBottom: 45 }}
      columnWrapperStyle={{ gap: 14 }}
      ListHeaderComponent={
        <View style={{ marginBottom: 22, gap: 16 }}>
          <Eyebrow>COLLECTION</Eyebrow>
          <Txt style={common.title}>{deck.title}</Txt>
          <Txt muted>
            {diagrams.length} {diagrams.length === 1 ? "diagram" : "diagrams"} ·{" "}
            {labels} {labels === 1 ? "label" : "labels"} · {due.length} ready to
            review
          </Txt>
          <Button
            title={
              due.length
                ? `Study ${due.length} ${due.length === 1 ? "label" : "labels"}`
                : "All caught up"
            }
            icon="play-outline"
            disabled={!due.length}
            onPress={() => navigation.navigate("Study", { deckId: deck.id })}
          />
          <View style={common.row}>
            <Button
              title="Add images"
              secondary
              icon="add-outline"
              onPress={() => navigation.navigate("Import", { deckId: deck.id })}
              style={{ flex: 1 }}
            />
            <IconButton
              name="ellipsis-horizontal"
              label="Collection options"
              onPress={() =>
                Alert.alert(deck.title, "Manage this collection", [
                  {
                    text: "Rename",
                    onPress: () =>
                      navigation.navigate("NewDeck", { deckId: deck.id }),
                  },
                  {
                    text: "Delete",
                    style: "destructive",
                    onPress: () =>
                      Alert.alert(
                        "Delete collection?",
                        "All diagrams and progress in this collection will be removed.",
                        [
                          { text: "Cancel", style: "cancel" },
                          {
                            text: "Delete",
                            style: "destructive",
                            onPress: async () => {
                              try {
                                await deleteCollection(deck.id);
                                navigation.goBack();
                              } catch {
                                Alert.alert(
                                  "Couldn’t remove every image",
                                  "Please try deleting the collection again.",
                                );
                              }
                            },
                          },
                        ],
                      ),
                  },
                  { text: "Cancel", style: "cancel" },
                ])
              }
            />
          </View>
          <Section title="The bigger picture" />
        </View>
      }
      renderItem={({ item }) => (
        <Pressable
          accessibilityRole="button"
          onPress={() => navigation.navigate("Editor", { diagramId: item.id })}
          style={({ pressed }) => ({
            flex: 1,
            maxWidth: "48%",
            borderRadius: 20,
            backgroundColor: c.surface,
            overflow: "hidden",
            borderWidth: 1,
            borderColor: c.line,
            opacity: pressed ? 0.7 : 1,
          })}
        >
          <View style={{ height: 135, overflow: "hidden" }}>
            <MaskedDiagram diagram={item} all />
          </View>
          <View style={{ padding: 13, gap: 4 }}>
            <Txt
              numberOfLines={2}
              style={{ fontSize: 14, lineHeight: 20, fontWeight: "600" }}
            >
              {item.title}
            </Txt>
            <Txt muted style={{ fontSize: 11 }}>
              {item.status === "ready"
                ? `${item.masks.length} labels`
                : item.status === "review"
                  ? "Review GPT masks"
                  : item.status === "failed"
                    ? "Needs attention"
                    : item.status === "processing"
                      ? "Finding labels…"
                      : "Waiting for GPT"}
            </Txt>
          </View>
        </Pressable>
      )}
      ListEmptyComponent={
        <Empty
          title="Bring this subject to life"
          detail="Import photos, screenshots, or a PDF. GPT will find labels for you."
        >
          <Button
            title="Add images"
            onPress={() => navigation.navigate("Import", { deckId: deck.id })}
          />
        </Empty>
      }
    />
  );
}
export function NewDeckScreen({ route, navigation }: any) {
  const c = useColors();
  const existing = useStore((s) =>
    s.decks.find((d) => d.id === route.params?.deckId),
  );
  const [name, setName] = useState(existing?.title || "");
  return (
    <ScrollView
      keyboardShouldPersistTaps="handled"
      automaticallyAdjustKeyboardInsets
      contentInsetAdjustmentBehavior="automatic"
      style={{ backgroundColor: c.bg }}
      contentContainerStyle={[common.page, { gap: 20 }]}
    >
      <Eyebrow>A PLACE FOR YOUR NEXT INSIGHT</Eyebrow>
      <Txt style={common.title}>
        {existing ? "Make it yours." : "Name your collection."}
      </Txt>
      <Txt muted>One subject, one chapter, or one big idea.</Txt>
      <TextInput
        autoFocus
        accessibilityLabel="Collection name"
        placeholder="e.g. Human anatomy"
        placeholderTextColor={c.muted}
        defaultValue={name}
        onChangeText={setName}
        maxLength={100}
        style={[
          common.input,
          { backgroundColor: c.surface, borderColor: c.line, color: c.ink },
        ]}
        returnKeyType="done"
      />
      <Button
        title={existing ? "Save name" : "Create collection"}
        disabled={!name.trim()}
        onPress={() => {
          if (existing) {
            useStore.getState().updateDeck(existing.id, name.trim());
            navigation.goBack();
          } else {
            const deck: Deck = {
              id: id(),
              title: name.trim(),
              subtitle: "",
              symbol: "layers-outline",
              created: Date.now(),
            };
            useStore.getState().addDeck(deck);
            navigation.replace("Deck", { deckId: deck.id });
          }
        }}
      />
    </ScrollView>
  );
}
