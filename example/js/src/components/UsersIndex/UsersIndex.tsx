import _ from "lodash";
import { useRecoilValue } from "recoil";
import usersState from "../../state/usersState";
import UsersIndexItem from "./UsersIndexItem";

export default function UsersIndex() {
  const users = useRecoilValue(usersState);

  return <div>
    <h1>Users</h1>
    <ul>
      {
        _.map(
          users,
          ({ id }) => <li key={id}><UsersIndexItem id={id} /></li>
        )
      }
    </ul>
  </div>
}
