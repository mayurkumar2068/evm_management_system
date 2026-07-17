/** Urban (नगरीय) vs Rural (ग्रामीण) survey flow. */
export type AreaType = 'urban' | 'rural';

/**
 * A selectable option in any cascading dropdown
 * (district → body/block → body-name/panchayat → booth).
 */
export interface LocationOption {
  readonly id: string;
  readonly name: string;
}

/** Generic label/value pair used by the read-only location card. */
export interface LabelValue {
  readonly label: string;
  readonly value: string;
  /** Optional Material icon name shown before the label. */
  readonly icon?: string;
}

/** Device GPS reading. */
export interface Coordinates {
  latitude: number;
  longitude: number;
  accuracy?: number;
}

/**
 * Final, fully-resolved location chosen on screen 1 and carried to screen 2.
 * `values` (key → id) feeds the submit payload; `rows` (ordered label/value)
 * drives the display card — both work for urban and rural flows.
 */
export interface SelectedLocation {
  areaType: AreaType;
  values: Record<string, string>;
  rows: LabelValue[];
}
