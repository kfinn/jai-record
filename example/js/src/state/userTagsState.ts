import { atomFamily } from "recoil";
import api from "../config/api";
import { Tag } from "./tagState";

const userTagsState = atomFamily<Tag[], number>({
  key: 'userTagsState',
  default: (id) => api.get<{ tags: Tag[] }>(`users/${id}/tags`).then(({ data }) => data.tags)
})
export default userTagsState
