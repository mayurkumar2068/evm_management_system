import { Observable } from 'rxjs';

import { LocationOption } from './location.model';

/**
 * One step in a cascading-dropdown chain. The chain is fully data-driven: the
 * reusable `CascadeSelectComponent` renders and wires any list of these without
 * per-screen boilerplate.
 *
 * `load` receives a snapshot of every already-selected level (key → id) so a
 * loader can depend on more than just its immediate parent (e.g. an urban body
 * is filtered by BOTH district and body-type).
 */
export interface CascadeLevel {
  readonly key: string;
  readonly label: string;
  readonly load: (selected: Record<string, string>) => Observable<LocationOption[]>;
}

/** Live state emitted by `CascadeSelectComponent` on every change. */
export interface CascadeSelection {
  /** key → selected option id. */
  readonly values: Record<string, string>;
  /** key → selected option label. */
  readonly labels: Record<string, string>;
  /** True once every level has a selection. */
  readonly complete: boolean;
}
