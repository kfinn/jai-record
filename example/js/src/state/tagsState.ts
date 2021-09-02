import _ from "lodash";
import { selector } from "recoil";
import { Tag } from "./tagState";
import usersState from "./usersState";
import userTagsState from "./userTagsState";

const tagsState = selector<Tag[]>({
  key: 'tagsState',
  get: ({ get }) => {
    const users = get(usersState);
    const userTagLists = _.map(users, ({ id }) => get(userTagsState(id)))
    return _.reduce(userTagLists, (lhs, rhs) => _.unionBy(lhs, rhs, 'id'), ([] as Tag[]))
  }
})
export default tagsState
