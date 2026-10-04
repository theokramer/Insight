import * as ImagePicker from "expo-image-picker";
import * as DocumentPicker from "expo-document-picker";
import * as FS from "expo-file-system/legacy";
import * as ImageManipulator from "expo-image-manipulator";
import * as SecureStore from "expo-secure-store";
import { requireOptionalNativeModule } from "expo-modules-core";
import { Diagram, id, makeMask, validBounds } from "./model";
import { useStore } from "./store";
import { subscriberId } from "./subscriptions";
import { prepareText, type RawText } from "./text-detection";
import { AnalysisError, requestAnalysis } from "./analysis-request";
import { currentImageUri } from "./image-location";
const native = requireOptionalNativeModule("InsightVision") as {
  renderPDF(
    uri: string,
  ): Promise<{ uri: string; width: number; height: number }[]>;
  recognize(uri: string): Promise<RawText[]>;
} | null;
const root = () => `${FS.documentDirectory}diagrams/`;
export async function keepImage(
  uri: string,
  width: number,
  height: number,
  deckId: string,
  title: string,
): Promise<Diagram> {
  const result = await ImageManipulator.manipulateAsync(
    uri,
    [
      {
        resize: {
          width: Math.max(
            1,
            Math.round(width * Math.min(1, 3200 / Math.max(width, height))),
          ),
        },
      },
    ],
    { compress: 0.94, format: ImageManipulator.SaveFormat.JPEG },
  );
  await FS.makeDirectoryAsync(root(), { intermediates: true });
  const imageId = id();
  const dest = `${root()}${imageId}.jpg`;
  try {
    await FS.copyAsync({ from: result.uri, to: dest });
  } finally {
    await FS.deleteAsync(result.uri, { idempotent: true }).catch(() => {});
  }
  return {
    id: imageId,
    deckId,
    title,
    uri: dest,
    width: result.width,
    height: result.height,
    status: "imported",
    masks: [],
  };
}
type ImportResult = { diagrams: Diagram[]; errors: string[] };
type ImportCallback = (diagram: Diagram) => void;
const imported = (
  result: ImportResult,
  diagram: Diagram,
  onImport?: ImportCallback,
) => {
  useStore.getState().addDiagrams([diagram]);
  result.diagrams.push(diagram);
  onImport?.(diagram);
};
export async function pickPhotos(
  deckId: string,
  camera = false,
  onImport?: ImportCallback,
): Promise<ImportResult> {
  if (camera) {
    const permission = await ImagePicker.requestCameraPermissionsAsync();
    if (!permission.granted)
      throw new Error(
        "Allow camera access in your phone settings to take a photo.",
      );
  }
  const selection = camera
    ? await ImagePicker.launchCameraAsync({
        mediaTypes: ["images"],
        quality: 1,
      })
    : await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ["images"],
        allowsMultipleSelection: true,
        selectionLimit: 50,
        quality: 1,
        orderedSelection: true,
      });
  const result: ImportResult = { diagrams: [], errors: [] };
  if (selection.canceled) return result;
  for (const asset of selection.assets.slice(0, 50)) {
    try {
      imported(
        result,
        await keepImage(
          asset.uri,
          asset.width,
          asset.height,
          deckId,
          asset.fileName?.replace(/\.[^.]+$/, "") || "Untitled diagram",
        ),
        onImport,
      );
    } catch {
      result.errors.push(asset.fileName || "Photo");
    }
  }
  return result;
}
export async function pickFiles(
  deckId: string,
  onImport?: ImportCallback,
): Promise<ImportResult> {
  const selection = await DocumentPicker.getDocumentAsync({
    type: ["image/*", "application/pdf"],
    multiple: true,
    copyToCacheDirectory: true,
  });
  const result: ImportResult = { diagrams: [], errors: [] };
  if (selection.canceled) return result;
  for (const asset of selection.assets) {
    if (result.diagrams.length >= 50) {
      result.errors.push("Import limit reached (50 images)");
      break;
    }
    let pages: { uri: string; width: number; height: number }[] = [];
    let converted: string | undefined;
    try {
      if (
        asset.mimeType === "application/pdf" ||
        asset.name.toLowerCase().endsWith(".pdf")
      ) {
        if (!native)
          throw new Error("PDF import needs the native Insight build.");
        pages = await native.renderPDF(asset.uri);
        for (let i = 0; i < pages.length; i++) {
          if (result.diagrams.length >= 50) {
            result.errors.push("Import limit reached (50 images)");
            break;
          }
          try {
            const page = pages[i];
            imported(
              result,
              await keepImage(
                page.uri,
                page.width,
                page.height,
                deckId,
                `${asset.name.replace(/\.pdf$/i, "")} · ${i + 1}`,
              ),
              onImport,
            );
          } catch {
            result.errors.push(`${asset.name} · ${i + 1}`);
          }
        }
      } else {
        const image = await ImageManipulator.manipulateAsync(asset.uri, [], {
          format: ImageManipulator.SaveFormat.JPEG,
        });
        converted = image.uri;
        imported(
          result,
          await keepImage(
            image.uri,
            image.width,
            image.height,
            deckId,
            asset.name,
          ),
          onImport,
        );
      }
    } catch (error) {
      result.errors.push(
        `${asset.name}: ${error instanceof Error ? error.message : "Could not read file"}`,
      );
    } finally {
      await Promise.all(
        [
          ...pages.map((p) => p.uri),
          ...(converted ? [converted] : []),
          asset.uri,
        ].map((uri) =>
          FS.deleteAsync(uri, { idempotent: true }).catch(() => {}),
        ),
      );
    }
  }
  return result;
}
export async function token() {
  return SecureStore.getItemAsync("insight-access-token");
}
export async function setToken(value: string) {
  if (value.trim())
    await SecureStore.setItemAsync("insight-access-token", value.trim());
  else await SecureStore.deleteItemAsync("insight-access-token");
}
export async function analyze(diagram: Diagram) {
  const uri = currentImageUri(diagram.uri, FS.documentDirectory);
  if (!uri) throw new Error("This example already has masks.");
  const url = useStore.getState().backendUrl.replace(/\/$/, "");
  if (
    !/^https:\/\//.test(url) &&
    !/^http:\/\/(localhost|127\.0\.0\.1|10\.0\.2\.2|192\.168\.|10\.|172\.(1[6-9]|2\d|3[01])\.)/.test(
      url,
    )
  )
    throw new Error(
      "Use an HTTPS backend address, or a local development address.",
    );
  const access = __DEV__ ? await token() : null;
  const userId = access ? null : await subscriberId();
  if (!native)
    throw new Error("Text detection needs the native Insight build.");
  let candidates;
  try {
    candidates = prepareText(
      await native.recognize(uri),
      diagram.width,
      diagram.height,
    );
  } catch {
    throw new Error(
      "Could not detect text in this image. Your image is saved; reimport it or retry.",
    );
  }
  // OCR retains the original pixels; GPT receives a bounded image with the same aspect ratio.
  const upload = await ImageManipulator.manipulateAsync(
    uri,
    [
      {
        resize: {
          width: Math.round(
            diagram.width *
              Math.min(1, 2000 / Math.max(diagram.width, diagram.height)),
          ),
        },
      },
    ],
    { compress: 0.9, format: ImageManipulator.SaveFormat.JPEG },
  );
  let base64: string;
  try {
    base64 = await FS.readAsStringAsync(upload.uri, {
      encoding: FS.EncodingType.Base64,
    });
  } finally {
    await FS.deleteAsync(upload.uri, { idempotent: true }).catch(() => {});
  }
  const data = await requestAnalysis(
    url,
    access
      ? { authorization: `Bearer ${access}` }
      : { "x-app-user-id": userId! },
    {
      image: `data:image/jpeg;base64,${base64}`,
      candidates,
    },
  );
  const masks = data.masks
    .filter(
      (m: any) =>
        m && typeof m.label === "string" && m.label.trim() && validBounds(m),
    )
    .map((m: any) =>
      makeMask(
        m.label,
        m.x,
        m.y,
        m.width,
        m.height,
        typeof m.explanation === "string" ? m.explanation : "",
      ),
    );
  return {
    title:
      typeof data.title === "string" && data.title.trim()
        ? data.title
        : diagram.title,
    masks,
    status: "review" as const,
    error: undefined,
  };
}
let running = false;
export async function runQueue() {
  if (running) return;
  running = true;
  try {
    while (true) {
      const next = useStore
        .getState()
        .diagrams.find((d) => d.status === "queued");
      if (!next) break;
      useStore
        .getState()
        .updateDiagram(next.id, { status: "processing", error: undefined });
      try {
        const result = await analyze(next);
        useStore.getState().updateDiagram(next.id, result);
      } catch (e) {
        if (e instanceof AnalysisError && e.status === 429) {
          useStore.getState().updateDiagram(next.id, {
            status: "queued",
            error: "Waiting a minute · resumes automatically",
          });
          setTimeout(() => {
            void runQueue();
          }, 61000);
          break;
        }
        useStore.getState().updateDiagram(next.id, {
          status: "failed",
          error:
            e instanceof Error ? e.message : "Analysis failed. Please retry.",
        });
      }
    }
  } finally {
    running = false;
  }
}
export async function deleteImage(diagram: Diagram) {
  const uri = currentImageUri(diagram.uri, FS.documentDirectory);
  if (uri) await FS.deleteAsync(uri, { idempotent: true });
  useStore.getState().removeDiagram(diagram.id);
}

export async function deleteCollection(deckId: string) {
  const diagrams = useStore
    .getState()
    .diagrams.filter((d) => d.deckId === deckId);
  for (const diagram of diagrams) await deleteImage(diagram);
  useStore.getState().deleteDeck(deckId);
}
