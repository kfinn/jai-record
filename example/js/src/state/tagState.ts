import _ from "lodash";
import { selectorFamily } from "recoil";
import tagsState from "./tagsState";

export interface Tag {
  id: number;
  description: string;
}

const tagState = selectorFamily<Tag, number>({
  key: 'tagState',
  get: (id) => ({ get }) => _.find(get(tagsState), (tag) => tag.id === id)!
})
export default tagState
