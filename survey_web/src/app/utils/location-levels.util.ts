import { CascadeLevel } from '../models/cascade.model';
import { I18nService } from '../i18n/i18n.service';
import { SurveyService } from '../services/survey.service';

/**
 * Declarative cascade definitions for each survey flow.
 *
 * The screen never wires individual dropdowns: it just hands one of these
 * arrays to `<app-cascade-select>`, which renders + chains them generically.
 * Adding/removing a level is a one-line change here. Level labels are
 * localized via {@link I18nService}.
 */

export function buildRuralLevels(svc: SurveyService, i18n: I18nService): CascadeLevel[] {
  return [
    { key: 'districtId', label: i18n.t('level.district'), load: () => svc.getDistricts() },
    {
      key: 'blockId',
      label: i18n.t('level.block'),
      load: (v) => svc.getBlocks(v['districtId']),
    },
    {
      key: 'boothId',
      label: i18n.t('level.booth'),
      load: (v) => svc.getRuralBooths(v['blockId']),
    },
  ];
}

export function buildUrbanLevels(svc: SurveyService, i18n: I18nService): CascadeLevel[] {
  return [
    { key: 'districtId', label: i18n.t('level.district'), load: () => svc.getDistricts() },
    {
      key: 'bodyId',
      label: i18n.t('level.body'),
      load: (v) => svc.getBodies(v['districtId']),
    },
    {
      key: 'boothId',
      label: i18n.t('level.booth'),
      load: (v) => svc.getUrbanBooths(v['bodyId']),
    },
  ];
}
