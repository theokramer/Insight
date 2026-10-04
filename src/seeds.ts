import { Deck, Diagram, makeMask } from "./model";
const wrap = (body: string) =>
  `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="700" viewBox="0 0 800 700"><rect width="800" height="700" rx="24" fill="#F5F6EE"/>${body}</svg>`;
const line = (d: string) =>
  `<path d="${d}" fill="none" stroke="#8A9E8F" stroke-width="2"/>`;
const label = (s: string, x: number, y: number) =>
  `<text x="${x}" y="${y}" font-family="Helvetica,Arial,sans-serif" font-size="25" font-weight="500" fill="#25463B">${s}</text>`;
export const neuronSVG = wrap(
  `<text x="42" y="55" font-family="Helvetica,Arial" font-size="15" letter-spacing="3" fill="#758A7D">NEURON · STRUCTURE &amp; FUNCTION</text><g stroke="#316D52" stroke-width="7" fill="none" stroke-linecap="round"><path d="M270 323 L201 244 L170 153 M201 244 L119 217 M230 276 L138 307 L81 289 M138 307 L92 354 M263 303 L287 219 L348 165 M287 219 L271 156 M258 357 L213 433 L136 466 M213 433 L238 479 M289 367 L321 435"/></g><path d="M223 315 Q238 263 279 275 Q318 268 333 314 Q354 343 320 375 Q282 405 244 372 Q210 357 223 315" fill="#C6D9AF" stroke="#316D52" stroke-width="5"/><circle cx="278" cy="335" r="23" fill="#7EAD76"/><path d="M330 341 C410 321 444 353 511 332 S593 345 669 320" stroke="#316D52" stroke-width="10" fill="none"/><g fill="#CBDCB9" stroke="#548064" stroke-width="3"><rect x="359" y="313" width="52" height="49" rx="21"/><rect x="427" y="315" width="52" height="49" rx="21"/><rect x="495" y="307" width="52" height="49" rx="21"/><rect x="565" y="302" width="52" height="49" rx="21"/></g><g fill="none" stroke="#316D52" stroke-width="5" stroke-linecap="round"><path d="M669 320 L709 272 L733 254 M669 320 L727 328 M669 320 L704 378 L735 391"/></g><g fill="#316D52"><circle cx="733" cy="254" r="8"/><circle cx="727" cy="328" r="8"/><circle cx="735" cy="391" r="8"/></g>${line("M125 182 L125 124 L45 124")}${label("Dendrites", 45, 113)}${line("M245 376 L245 526 L44 526")}${label("Cell body", 44, 515)}${line("M281 335 L281 576 L344 576")}${label("Nucleus", 344, 565)}${line("M453 313 L453 151 L407 151")}${label("Myelin sheath", 390, 140)}${line("M549 339 L549 482 L561 482")}${label("Axon", 561, 471)}${line("M733 391 L733 577 L554 577")}${label("Axon terminals", 554, 566)}<path d="M357 625 L636 625 M624 615 L636 625 L624 635" fill="none" stroke="#8A9E8F" stroke-width="2"/><text x="377" y="655" font-family="Helvetica,Arial" font-size="16" fill="#758A7D">Direction of nerve impulse</text>`,
);
const cellSVG = wrap(
  `<text x="42" y="55" font-family="Helvetica,Arial" font-size="15" letter-spacing="3" fill="#758A7D">PLANT CELL · A LOOK INSIDE</text><rect x="182" y="168" width="415" height="361" rx="93" fill="#D0DFBA" stroke="#356C4E" stroke-width="13"/><rect x="199" y="183" width="382" height="332" rx="80" fill="#E4EBCC" stroke="#80A477" stroke-width="4"/><path d="M299 230 Q440 196 506 291 Q564 423 455 471 Q326 504 282 389 Q253 295 299 230" fill="#C9DFD3" stroke="#8FB4A0" stroke-width="3"/><circle cx="251" cy="327" r="42" fill="#ABC199" stroke="#517D55" stroke-width="3"/><circle cx="251" cy="327" r="15" fill="#618459"/><g fill="#7EAF77" stroke="#436D49" stroke-width="3"><ellipse cx="273" cy="213" rx="34" ry="16" transform="rotate(-15 273 213)"/><ellipse cx="552" cy="401" rx="31" ry="15" transform="rotate(70 552 401)"/><ellipse cx="250" cy="460" rx="34" ry="16" transform="rotate(20 250 460)"/></g><g fill="#C8D29E" stroke="#8E9B67" stroke-width="2"><ellipse cx="535" cy="269" rx="25" ry="12" transform="rotate(35 535 269)"/><ellipse cx="336" cy="494" rx="25" ry="12"/></g>${line("M186 231 L137 130 L44 130")}${label("Cell wall", 44, 119)}${line("M251 327 L115 327 L45 352")}${label("Nucleus", 45, 390)}${line("M393 356 L393 586 L300 586")}${label("Central vacuole", 300, 619)}${line("M552 401 L666 440 L633 493")}${label("Chloroplast", 616, 528)}${line("M535 269 L654 199 L609 131")}${label("Mitochondrion", 566, 117)}`,
);
const circuitSVG = wrap(
  `<text x="42" y="55" font-family="Helvetica,Arial" font-size="15" letter-spacing="3" fill="#758A7D">SERIES CIRCUIT · THE ESSENTIALS</text><path d="M235 252 L235 180 L510 180 L510 251 M510 352 L510 470 L235 470 L235 349" fill="none" stroke="#46705A" stroke-width="6"/><path d="M195 280 L275 280 M210 308 L260 308 M195 331 L275 331" stroke="#46705A" stroke-width="6"/><path d="M510 251 L495 262 L525 277 L495 292 L525 307 L495 322 L525 337 L510 352" fill="none" stroke="#46705A" stroke-width="5"/><circle cx="362" cy="470" r="38" fill="#E6EACD" stroke="#46705A" stroke-width="5"/><path d="M338 446 L386 494 M386 446 L338 494" stroke="#46705A" stroke-width="4"/><path d="M344 180 L393 180 M381 169 L393 180 L381 191" stroke="#91AE72" stroke-width="5" fill="none"/>${line("M194 308 L75 308")}${label("Battery", 45, 354)}${line("M525 300 L638 300")}${label("Resistor", 601, 345)}${line("M362 508 L362 579")}${label("Lamp", 330, 616)}${line("M374 180 L374 120")}${label("Current", 335, 109)}`,
);
export const seedDecks: Deck[] = [
  {
    id: "neuro",
    title: "The nervous system",
    subtitle: "Biology · 1 diagram",
    symbol: "pulse-outline",
    created: 0,
  },
  {
    id: "plant",
    title: "Inside a plant cell",
    subtitle: "Biology · 1 diagram",
    symbol: "leaf-outline",
    created: 0,
  },
  {
    id: "circuits",
    title: "Circuits, made simple",
    subtitle: "Physics · 1 diagram",
    symbol: "flash-outline",
    created: 0,
  },
];
const m = (l: string, x: number, y: number, w: number, h: number, e: string) =>
  makeMask(l, x / 800, y / 700, w / 800, h / 700, e);
export const seedDiagrams: Diagram[] = [
  {
    id: "neuron",
    deckId: "neuro",
    title: "Anatomy of a neuron",
    svg: neuronSVG,
    width: 800,
    height: 700,
    status: "ready",
    masks: [
      m(
        "Dendrites",
        40,
        85,
        150,
        35,
        "Branched extensions that receive signals from other neurons.",
      ),
      m(
        "Cell body",
        40,
        487,
        145,
        36,
        "Contains the nucleus and supports the metabolic activity of the neuron.",
      ),
      m(
        "Nucleus",
        340,
        537,
        125,
        36,
        "Contains genetic material and helps regulate cell activity.",
      ),
      m(
        "Myelin sheath",
        385,
        112,
        185,
        37,
        "An insulating layer that helps electrical signals travel quickly along the axon.",
      ),
      m(
        "Axon",
        555,
        443,
        85,
        36,
        "Carries electrical impulses away from the cell body.",
      ),
      m(
        "Axon terminals",
        549,
        538,
        209,
        36,
        "Release neurotransmitters to communicate with another cell.",
      ),
    ],
  },
  {
    id: "cell",
    deckId: "plant",
    title: "Parts of a plant cell",
    svg: cellSVG,
    width: 800,
    height: 700,
    status: "ready",
    masks: [
      m(
        "Cell wall",
        40,
        91,
        130,
        36,
        "A rigid outer layer that supports and protects the cell.",
      ),
      m("Nucleus", 40, 362, 123, 36, "Houses the cell’s DNA."),
      m(
        "Central vacuole",
        295,
        591,
        213,
        36,
        "Stores water and solutes and helps maintain turgor pressure.",
      ),
      m(
        "Chloroplast",
        610,
        500,
        175,
        36,
        "The organelle where photosynthesis takes place.",
      ),
      m(
        "Mitochondrion",
        560,
        89,
        222,
        36,
        "Generates ATP through cellular respiration.",
      ),
    ],
  },
  {
    id: "circuit",
    deckId: "circuits",
    title: "A simple series circuit",
    svg: circuitSVG,
    width: 800,
    height: 700,
    status: "ready",
    masks: [
      m(
        "Battery",
        40,
        326,
        128,
        36,
        "Provides the potential difference that drives current.",
      ),
      m("Resistor", 595, 317, 139, 36, "Limits current in the circuit."),
      m(
        "Lamp",
        325,
        588,
        93,
        36,
        "Converts electrical energy into light and heat.",
      ),
      m(
        "Current",
        329,
        81,
        131,
        36,
        "The flow of electric charge. Conventional current flows from positive to negative outside the battery.",
      ),
    ],
  },
];
