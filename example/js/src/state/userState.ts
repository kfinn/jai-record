import _ from "lodash";
import { selectorFamily } from "recoil";
import usersState from "./usersState";

export interface User {
  id: number;
  email: string;
}

const userState = selectorFamily({
  key: 'userState',
  get: (id) => ({ get }) => _.find(get(usersState), (user) => user.id === id)!
})
export default userState;
