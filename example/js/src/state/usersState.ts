import { atom } from "recoil";
import api from "../config/api";
import { User } from "./userState";

const usersState = atom<User[]>({
  key: 'usersState',
  default: api.get<{ users: User[] }>('users').then(({ data }) => data.users)
})
export default usersState
