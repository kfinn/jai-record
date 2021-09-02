import _ from "lodash";
import { useRecoilValue } from "recoil";
import userState from "../../state/userState";
import userTagsState from "../../state/userTagsState";
import UsersShowTag from "./UsersShowTag";

export default function UsersShow({ id }: { id: number }) {
  const user = useRecoilValue(userState(id));
  const tags = useRecoilValue(userTagsState(id));

  return <div>
    <h1>Users &gt; {user.email}</h1>
    <h2>Tags</h2>
    <ul>
      {
        _.map(tags, ({ id }) => <li key={id}><UsersShowTag id={id} /></li>)
      }
    </ul>
  </div>
}
